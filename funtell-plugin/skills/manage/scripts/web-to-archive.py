#!/usr/bin/env python3
"""
Web-to-Archive: Scrape a website and generate a FunTell project archive ZIP.

Usage:
    python scripts/web-to-archive.py <url> [options]

Options:
    --output, -o         Output ZIP path (default: {sanitized_domain}_archive.zip)
    --name, -n           Project name (default: page title or domain)
    --language, -l       Original language code (default: en)
    --mode, -m           Content mode: single|list|grid|cards (default: list)
    --grouped, -g        Enable grouped categories (default: auto-detect)
    --max-depth          Maximum link depth to follow (default: 1, max: 3)
    --max-pages          Maximum pages to scrape (default: 20, max: 100)
    --same-domain-only   Only follow links on the same domain (default: true)
    --delay              Delay between requests in seconds (default: 1.0)

Requirements:
    pip install -r scripts/requirements-web.txt
"""

import argparse
import hashlib
import json
import os
import re
import sys
import time
import zipfile
from collections import Counter, defaultdict
from datetime import datetime, timezone
from io import BytesIO
from typing import Any
from urllib.parse import urljoin, urlparse
from urllib.robotparser import RobotFileParser

try:
    import requests
    from bs4 import BeautifulSoup, NavigableString
    from PIL import Image
    import html2text
    import chardet
except ImportError as e:
    print(f"Error: Missing required dependency: {e.name}")
    print("Install with: pip install -r scripts/requirements-web.txt")
    sys.exit(1)


# ── Constants ──────────────────────────────────────────────────────────

USER_AGENT = "FunTell-Bot/1.0 (+https://funtell.app)"
REQUEST_TIMEOUT = 30
MIN_IMAGE_SIZE = 50
MAX_IMAGE_SIZE_MB = 10
SKIP_IMAGE_FORMATS = {"emf", "wmf", "tiff", "bmp", "ico", "svg"}


# ── Helpers ──────────────────────────────────────────────────────────────

def sanitize_filename(name: str) -> str:
    """Create a safe filename from a string."""
    clean = re.sub(r"[^a-z0-9_\-. ]", "", name, flags=re.IGNORECASE)
    clean = re.sub(r"\s+", "-", clean).strip("-")
    return clean[:80] or "untitled"


def url_to_domain(url: str) -> str:
    """Extract domain from URL."""
    parsed = urlparse(url)
    return parsed.netloc


def normalize_url(url: str) -> str:
    """Normalize URL by removing fragments and trailing slashes."""
    parsed = urlparse(url)
    return f"{parsed.scheme}://{parsed.netloc}{parsed.path.rstrip('/')}"


def is_same_domain(url1: str, url2: str) -> bool:
    """Check if two URLs belong to the same domain."""
    return urlparse(url1).netloc == urlparse(url2).netloc


def is_blocked_domain(url: str) -> bool:
    """Check if URL is from a blocked domain (social media, etc.)."""
    blocked_patterns = [
        "facebook.com", "twitter.com", "x.com", "instagram.com",
        "linkedin.com", "reddit.com", "tiktok.com", "youtube.com",
        "pinterest.com", "tumblr.com", "snapchat.com",
    ]
    domain = urlparse(url).netloc.lower()
    return any(pattern in domain for pattern in blocked_patterns)


# ── Robots.txt checking ──────────────────────────────────────────────────

class RobotsChecker:
    """Check robots.txt compliance."""

    def __init__(self, user_agent: str):
        self.user_agent = user_agent
        self.parsers: dict[str, RobotFileParser] = {}

    def can_fetch(self, url: str) -> bool:
        """Check if URL can be fetched according to robots.txt."""
        parsed = urlparse(url)
        base_url = f"{parsed.scheme}://{parsed.netloc}"

        if base_url not in self.parsers:
            parser = RobotFileParser()
            parser.set_url(f"{base_url}/robots.txt")
            try:
                parser.read()
                self.parsers[base_url] = parser
            except Exception:
                # If robots.txt can't be fetched, allow by default
                return True

        return self.parsers[base_url].can_fetch(self.user_agent, url)


# ── HTML content extraction ──────────────────────────────────────────────

def extract_main_content(soup: BeautifulSoup) -> BeautifulSoup:
    """Extract main content area, removing navigation, headers, footers."""
    # Remove unwanted elements
    for tag in soup.find_all(["script", "style", "nav", "header", "footer", "aside"]):
        tag.decompose()

    # Try to find main content area
    main_candidates = [
        soup.find("main"),
        soup.find("article"),
        soup.find(role="main"),
        soup.find("div", class_=re.compile(r"(content|main|article|post)", re.I)),
        soup.find("div", id=re.compile(r"(content|main|article|post)", re.I)),
    ]

    for candidate in main_candidates:
        if candidate:
            return candidate

    # Fallback: use body
    return soup.find("body") or soup


def extract_text_blocks(soup: BeautifulSoup) -> list[dict]:
    """Extract structured text blocks with headings and content."""
    blocks = []
    position = 0

    main_content = extract_main_content(soup)

    for element in main_content.find_all(["h1", "h2", "h3", "h4", "h5", "h6", "p", "ul", "ol", "blockquote"]):
        text = element.get_text(separator=" ", strip=True)
        if not text or len(text) < 3:
            continue

        # Determine element type and size
        tag_name = element.name
        if tag_name.startswith("h"):
            level = int(tag_name[1])
            size = 24 - (level - 1) * 3  # H1=24, H2=21, H3=18, etc.
            is_heading = True
        else:
            size = 12
            is_heading = False

        # Convert lists to markdown
        if tag_name in ("ul", "ol"):
            items = element.find_all("li", recursive=False)
            if tag_name == "ul":
                text = "\n".join(f"- {li.get_text(strip=True)}" for li in items)
            else:
                text = "\n".join(f"{i+1}. {li.get_text(strip=True)}" for i, li in enumerate(items))

        # Convert blockquotes
        if tag_name == "blockquote":
            text = f"> {text}"

        blocks.append({
            "type": "text",
            "text": text,
            "size": size,
            "bold": is_heading,
            "is_heading": is_heading,
            "y": position,
            "page": 0,
        })

        position += 1

    return blocks


def extract_images(soup: BeautifulSoup, base_url: str) -> list[dict]:
    """Extract image URLs from page."""
    images = []
    position = 0
    seen_urls = set()

    main_content = extract_main_content(soup)

    for img in main_content.find_all("img"):
        src = img.get("src") or img.get("data-src")
        if not src:
            continue

        # Convert relative URLs to absolute
        full_url = urljoin(base_url, src)

        # Skip if already seen
        if full_url in seen_urls:
            continue
        seen_urls.add(full_url)

        # Skip data URLs and SVGs
        if full_url.startswith("data:") or full_url.endswith(".svg"):
            continue

        images.append({
            "url": full_url,
            "y": position,
            "page": 0,
        })

        position += 1

    return images


def extract_links(soup: BeautifulSoup, base_url: str, same_domain_only: bool) -> list[str]:
    """Extract internal links from page."""
    links = set()

    main_content = extract_main_content(soup)

    for a in main_content.find_all("a", href=True):
        href = a["href"]

        # Skip anchors, mailto, tel, etc.
        if href.startswith(("#", "mailto:", "tel:", "javascript:")):
            continue

        # Convert to absolute URL
        full_url = urljoin(base_url, href)

        # Check domain restriction
        if same_domain_only and not is_same_domain(base_url, full_url):
            continue

        # Normalize and add
        normalized = normalize_url(full_url)
        if normalized:
            links.add(normalized)

    return list(links)


# ── Image downloading ──────────────────────────────────────────────────

def download_image(url: str, session: requests.Session) -> tuple[bytes | None, str]:
    """
    Download image and return (data, extension).
    Returns (None, "") if download fails or image is invalid.
    """
    try:
        response = session.get(url, timeout=REQUEST_TIMEOUT, stream=True)
        response.raise_for_status()

        # Check size
        content_length = response.headers.get("content-length")
        if content_length and int(content_length) > MAX_IMAGE_SIZE_MB * 1024 * 1024:
            return None, ""

        # Download content
        data = BytesIO(response.content)

        # Validate with PIL
        img = Image.open(data)

        # Check dimensions
        if img.width < MIN_IMAGE_SIZE or img.height < MIN_IMAGE_SIZE:
            return None, ""

        # Check format
        fmt = img.format.lower() if img.format else "jpeg"
        if fmt in SKIP_IMAGE_FORMATS:
            return None, ""

        # Convert unsupported formats to JPEG
        if fmt not in ("jpeg", "jpg", "png", "webp", "gif"):
            output = BytesIO()
            rgb_img = img.convert("RGB")
            rgb_img.save(output, format="JPEG", quality=85)
            return output.getvalue(), "jpg"

        # Return original data
        ext = "jpg" if fmt == "jpeg" else fmt
        return response.content, ext

    except Exception as e:
        return None, ""


# ── Web scraping ──────────────────────────────────────────────────────

class WebScraper:
    """Scrape website content."""

    def __init__(
        self,
        start_url: str,
        max_depth: int,
        max_pages: int,
        same_domain_only: bool,
        delay: float,
    ):
        self.start_url = normalize_url(start_url)
        self.max_depth = max_depth
        self.max_pages = max_pages
        self.same_domain_only = same_domain_only
        self.delay = delay

        self.session = requests.Session()
        self.session.headers.update({"User-Agent": USER_AGENT})

        self.robots_checker = RobotsChecker(USER_AGENT)

        self.visited_urls: set[str] = set()
        self.pages: list[dict] = []
        self.stats = {
            "pages_scraped": 0,
            "pages_skipped": 0,
            "images_found": 0,
            "images_downloaded": 0,
            "images_failed": 0,
            "errors": [],
        }

    def scrape(self) -> tuple[list[dict], dict]:
        """Main scraping method. Returns (pages, stats)."""
        # Check if starting URL is blocked
        if is_blocked_domain(self.start_url):
            print(f"Error: Cannot scrape blocked domain: {url_to_domain(self.start_url)}")
            sys.exit(1)

        # Check robots.txt for starting URL
        if not self.robots_checker.can_fetch(self.start_url):
            print(f"Error: robots.txt disallows scraping: {self.start_url}")
            sys.exit(1)

        print(f"Starting scrape: {self.start_url}")
        print(f"  Max depth: {self.max_depth}, Max pages: {self.max_pages}")
        print(f"  Same domain only: {self.same_domain_only}")
        print()

        # BFS traversal
        queue = [(self.start_url, 0)]  # (url, depth)

        while queue and len(self.pages) < self.max_pages:
            url, depth = queue.pop(0)

            # Skip if already visited
            if url in self.visited_urls:
                continue

            # Skip if max depth exceeded
            if depth > self.max_depth:
                continue

            # Skip if robots.txt disallows
            if not self.robots_checker.can_fetch(url):
                self.stats["pages_skipped"] += 1
                self.stats["errors"].append(f"Robots.txt blocked: {url}")
                continue

            # Fetch page
            page_data = self._fetch_page(url, depth)

            if page_data:
                self.pages.append(page_data)
                self.stats["pages_scraped"] += 1
                print(f"[{len(self.pages)}/{self.max_pages}] Scraped: {url}")

                # Add links to queue if not at max depth
                if depth < self.max_depth:
                    for link in page_data.get("links", []):
                        if link not in self.visited_urls:
                            queue.append((link, depth + 1))

            self.visited_urls.add(url)

            # Rate limiting
            if self.delay > 0:
                time.sleep(self.delay)

        print()
        print(f"Scraping complete: {len(self.pages)} pages scraped")

        return self.pages, self.stats

    def _fetch_page(self, url: str, depth: int) -> dict | None:
        """Fetch and parse a single page."""
        try:
            response = self.session.get(url, timeout=REQUEST_TIMEOUT)
            response.raise_for_status()

            # Detect encoding
            if response.encoding == "ISO-8859-1":
                detected = chardet.detect(response.content)
                if detected["encoding"]:
                    response.encoding = detected["encoding"]

            html = response.text
            soup = BeautifulSoup(html, "lxml")

            # Extract title
            title_tag = soup.find("title")
            title = title_tag.get_text(strip=True) if title_tag else urlparse(url).path

            # Extract content
            text_blocks = extract_text_blocks(soup)
            image_urls = extract_images(soup, url)
            links = extract_links(soup, url, self.same_domain_only) if depth < self.max_depth else []

            self.stats["images_found"] += len(image_urls)

            return {
                "url": url,
                "title": title,
                "depth": depth,
                "blocks": text_blocks,
                "image_urls": image_urls,
                "links": links,
            }

        except requests.RequestException as e:
            self.stats["pages_skipped"] += 1
            self.stats["errors"].append(f"Failed to fetch {url}: {str(e)}")
            return None
        except Exception as e:
            self.stats["pages_skipped"] += 1
            self.stats["errors"].append(f"Error parsing {url}: {str(e)}")
            return None

    def download_images(self, pages: list[dict]) -> dict[str, tuple[bytes, str]]:
        """Download all images from scraped pages. Returns {hash: (data, ext)}."""
        image_map = {}
        seen_hashes = set()

        print("Downloading images...")

        for page in pages:
            for img_info in page.get("image_urls", []):
                url = img_info["url"]

                # Download
                data, ext = download_image(url, self.session)

                if not data:
                    self.stats["images_failed"] += 1
                    continue

                # Hash for deduplication
                img_hash = hashlib.md5(data).hexdigest()

                if img_hash not in seen_hashes:
                    image_map[img_hash] = (data, ext)
                    seen_hashes.add(img_hash)
                    self.stats["images_downloaded"] += 1

                # Store hash in img_info for later association
                img_info["hash"] = img_hash

                # Rate limiting
                if self.delay > 0:
                    time.sleep(self.delay)

        print(f"Downloaded {self.stats['images_downloaded']} unique images")
        print()

        return image_map


# ── Structure detection ──────────────────────────────────────────────────

def detect_structure(pages: list[dict]) -> list[dict]:
    """
    Detect hierarchical structure from pages.
    Returns list of categories with items.
    """
    categories = []

    # Strategy 1: URL path-based categorization
    if len(pages) > 1:
        path_groups = defaultdict(list)

        for page in pages:
            parsed = urlparse(page["url"])
            path_parts = [p for p in parsed.path.split("/") if p]

            # Use first path segment as category, or "default"
            category_name = path_parts[0] if path_parts else "default"
            category_name = category_name.replace("-", " ").replace("_", " ").title()

            path_groups[category_name].append(page)

        # Convert to category structure
        for cat_name, cat_pages in path_groups.items():
            items = []
            for page in cat_pages:
                # Combine all blocks into content
                content = "\n\n".join(b["text"] for b in page["blocks"] if not b["is_heading"])

                items.append({
                    "name": page["title"],
                    "content": content,
                    "page": 0,
                    "y": 0,
                    "blocks": page["blocks"],
                    "image_urls": page.get("image_urls", []),
                })

            categories.append({
                "name": cat_name,
                "items": items,
                "page": 0,
                "y": 0,
            })

    # Fallback: single category with all pages
    if not categories or len(categories) == 1:
        items = []
        for page in pages:
            content = "\n\n".join(b["text"] for b in page["blocks"] if not b["is_heading"])

            items.append({
                "name": page["title"],
                "content": content,
                "page": 0,
                "y": 0,
                "blocks": page["blocks"],
                "image_urls": page.get("image_urls", []),
            })

        categories = [{
            "name": "default",
            "items": items,
            "page": 0,
            "y": 0,
        }]

    return categories


# ── Archive building ──────────────────────────────────────────────────────

def build_archive(
    pages: list[dict],
    image_map: dict[str, tuple[bytes, str]],
    args: argparse.Namespace,
) -> tuple[dict, dict[str, bytes]]:
    """Build ProjectArchive structure from scraped pages."""

    # Detect structure
    categories = detect_structure(pages)

    is_grouped = args.grouped if args.grouped is not None else len(categories) > 1

    # Associate images with items
    image_files: dict[str, bytes] = {}
    item_images: dict[int, str] = {}

    item_idx = 0
    for cat in categories:
        for item in cat["items"]:
            # Find first image in this item
            for img_info in item.get("image_urls", []):
                img_hash = img_info.get("hash")
                if img_hash and img_hash in image_map:
                    data, ext = image_map[img_hash]
                    item_name = sanitize_filename(item["name"])
                    filename = f"{item_idx}-{item_name}.{ext}"
                    zip_path = f"images/content/{filename}"
                    image_files[zip_path] = data
                    item_images[item_idx] = zip_path
                    break  # Only use first image per item
            item_idx += 1

    # Build project.json
    content_items = []
    item_idx = 0
    for cat in categories:
        content_items.append({
            "name": cat["name"],
            "content": "",
            "ai_knowledge_base": "",
            "sort_order": len(content_items),
            "parent_name": None,
            "image": None,
            "crop_parameters": None,
            "translations": None,
            "content_hash": None,
        })
        for item in cat["items"]:
            content_items.append({
                "name": item["name"],
                "content": item["content"],
                "ai_knowledge_base": "",
                "sort_order": len(content_items),
                "parent_name": cat["name"],
                "image": item_images.get(item_idx),
                "crop_parameters": None,
                "translations": None,
                "content_hash": None,
            })
            item_idx += 1

    # Determine project name
    project_name = args.name
    if not project_name and pages:
        project_name = pages[0]["title"]
    if not project_name:
        project_name = sanitize_filename(url_to_domain(args.input))

    project = {
        "version": 1,
        "exportedAt": datetime.now(timezone.utc).isoformat(),
        "card": {
            "name": project_name,
            "description": "",
            "original_language": args.language,
            "content_mode": args.mode,
            "is_grouped": is_grouped,
            "group_display": "expanded",
            "billing_type": "digital",
            "default_daily_session_limit": None,
            "conversation_ai_enabled": False,
            "ai_instruction": "",
            "ai_knowledge_base": "",
            "ai_welcome_general": "",
            "ai_welcome_item": "",
            "qr_code_position": "BR",
            "image": None,
            "crop_parameters": None,
            "translations": None,
            "content_hash": None,
        },
        "contentItems": content_items,
    }

    return project, image_files


def create_zip(project: dict, image_files: dict[str, bytes], output_path: str) -> None:
    """Package project.json and images into a ZIP archive."""
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("project.json", json.dumps(project, indent=2, ensure_ascii=False))
        for path, data in image_files.items():
            zf.writestr(path, data)


# ── CLI ──────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Scrape a website and generate a FunTell project archive ZIP."
    )
    parser.add_argument("input", help="Starting URL to scrape")
    parser.add_argument("-o", "--output", help="Output ZIP path")
    parser.add_argument("-n", "--name", help="Project name")
    parser.add_argument("-l", "--language", default="en", help="Original language code (default: en)")
    parser.add_argument("-m", "--mode", default="list", choices=["single", "list", "grid", "cards"],
                        help="Content mode (default: list)")
    parser.add_argument("-g", "--grouped", default=None, action="store_true",
                        help="Enable grouped categories (default: auto-detect)")
    parser.add_argument("--max-depth", type=int, default=1, help="Maximum link depth (default: 1, max: 3)")
    parser.add_argument("--max-pages", type=int, default=20, help="Maximum pages to scrape (default: 20, max: 100)")
    parser.add_argument("--same-domain-only", default=True, action="store_true",
                        help="Only follow links on the same domain (default: true)")
    parser.add_argument("--delay", type=float, default=1.0, help="Delay between requests in seconds (default: 1.0)")

    args = parser.parse_args()

    # Validate constraints
    if args.max_depth < 1 or args.max_depth > 3:
        print("Error: --max-depth must be between 1 and 3")
        sys.exit(1)

    if args.max_pages < 1 or args.max_pages > 100:
        print("Error: --max-pages must be between 1 and 100")
        sys.exit(1)

    if args.delay < 0:
        print("Error: --delay must be non-negative")
        sys.exit(1)

    # Normalize URL
    if not args.input.startswith(("http://", "https://")):
        args.input = f"https://{args.input}"

    # Set default output path
    if not args.output:
        domain = sanitize_filename(url_to_domain(args.input))
        args.output = f"{domain}_archive.zip"

    # Scrape
    scraper = WebScraper(
        start_url=args.input,
        max_depth=args.max_depth,
        max_pages=args.max_pages,
        same_domain_only=args.same_domain_only,
        delay=args.delay,
    )

    pages, stats = scraper.scrape()

    if not pages:
        print("Error: No pages scraped. Check errors above.")
        sys.exit(1)

    # Download images
    image_map = scraper.download_images(pages)

    # Build archive
    project, image_files = build_archive(pages, image_map, args)
    create_zip(project, image_files, args.output)

    # Summary
    items = [ci for ci in project["contentItems"] if ci["parent_name"] is not None]
    cats = [ci for ci in project["contentItems"] if ci["parent_name"] is None]
    images_with = sum(1 for ci in items if ci.get("image"))

    print("─" * 60)
    print(f"Archive created: {args.output}")
    print(f"  Categories: {len(cats)}")
    print(f"  Content items: {len(items)}")
    print(f"  Images: {len(image_files)} included, {images_with} associated with items")
    print(f"  Content mode: {args.mode}, Grouped: {project['card']['is_grouped']}")
    print()
    print(f"Stats:")
    print(f"  Pages scraped: {stats['pages_scraped']}")
    print(f"  Pages skipped: {stats['pages_skipped']}")
    print(f"  Images found: {stats['images_found']}")
    print(f"  Images downloaded: {stats['images_downloaded']}")
    print(f"  Images failed: {stats['images_failed']}")

    if stats["errors"]:
        print()
        print(f"Warnings ({len(stats['errors'])}):")
        for error in stats["errors"][:5]:  # Show first 5
            print(f"  - {error}")
        if len(stats["errors"]) > 5:
            print(f"  ... and {len(stats['errors']) - 5} more")

    print()
    print("Import this ZIP via the FunTell web portal: Dashboard > Import")


if __name__ == "__main__":
    main()
