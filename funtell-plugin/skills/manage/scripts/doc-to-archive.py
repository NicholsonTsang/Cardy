#!/usr/bin/env python3
"""
Doc-to-Archive: Extract text + images from a PDF or Word document (.docx)
and generate a FunTell project archive ZIP for import via the web portal.

Usage:
    python scripts/doc-to-archive.py input.pdf [options]
    python scripts/doc-to-archive.py input.docx [options]

Options:
    --output, -o    Output ZIP path (default: {input_name}_archive.zip)
    --name, -n      Project name (default: filename without extension)
    --language, -l  Original language code (default: en)
    --mode, -m      Content mode: single|list|grid|cards (default: list)
    --grouped, -g   Enable grouped categories (default: auto-detect)

Requirements:
    pip install -r scripts/requirements-doc.txt
"""

import argparse
import json
import os
import re
import sys
import zipfile
from collections import Counter
from datetime import datetime, timezone


# ── Helpers ──────────────────────────────────────────────────────────

def sanitize_filename(name: str) -> str:
    """Create a safe filename from a string."""
    clean = re.sub(r"[^a-z0-9_\-. ]", "", name, flags=re.IGNORECASE)
    clean = re.sub(r"\s+", "-", clean).strip("-")
    return clean[:80] or "untitled"


def ext_from_content_type(content_type: str) -> str:
    """Map MIME content type to file extension."""
    mapping = {
        "image/jpeg": "jpg", "image/png": "png",
        "image/webp": "webp", "image/gif": "gif",
        "image/tiff": "tiff", "image/bmp": "bmp",
        "image/x-emf": "emf", "image/x-wmf": "wmf",
    }
    return mapping.get(content_type, "png")


# ── PDF processing ───────────────────────────────────────────────────

def _check_pymupdf():
    try:
        import fitz
        return fitz
    except ImportError:
        print("Error: pymupdf is required for PDF files. Install with:")
        print("  pip install pymupdf")
        sys.exit(1)


def _detect_heading_threshold(blocks: list[dict]) -> float:
    """Determine font size threshold separating headings from body."""
    sizes = [b["size"] for b in blocks if b["type"] == "text" and b["text"].strip()]
    if not sizes:
        return 999
    body_size = Counter(round(s, 1) for s in sizes).most_common(1)[0][0]
    return body_size * 1.2


def _extract_pdf_text_blocks(page, fitz) -> list[dict]:
    """Extract text blocks with font size and position from a PDF page."""
    blocks = []
    text_dict = page.get_text("dict", flags=fitz.TEXT_PRESERVE_WHITESPACE)
    for block in text_dict.get("blocks", []):
        if block["type"] != 0:
            continue
        full_text = ""
        max_size = 0
        is_bold = False
        for line in block.get("lines", []):
            for span in line.get("spans", []):
                full_text += span["text"]
                if span["size"] > max_size:
                    max_size = span["size"]
                if "bold" in span.get("font", "").lower():
                    is_bold = True
            full_text += "\n"
        text = full_text.strip()
        if text:
            blocks.append({
                "type": "text", "text": text, "size": max_size,
                "bold": is_bold, "y": block["bbox"][1], "page": page.number,
            })
    return blocks


def _extract_pdf_images(page, doc) -> list[dict]:
    """Extract images from a PDF page with their position."""
    images = []
    seen_xrefs = set()
    for img_info in page.get_images(full=True):
        xref = img_info[0]
        if xref in seen_xrefs:
            continue
        seen_xrefs.add(xref)
        try:
            img_data = doc.extract_image(xref)
            if not img_data or not img_data.get("image"):
                continue
            if img_data.get("width", 0) < 50 or img_data.get("height", 0) < 50:
                continue
            img_rects = page.get_image_rects(xref)
            y_pos = img_rects[0].y0 if img_rects else 0
            images.append({
                "data": img_data["image"],
                "ext": img_data.get("ext", "jpg"),
                "y": y_pos, "page": page.number,
            })
        except Exception:
            continue
    return images


def process_pdf(file_path: str) -> tuple[list[dict], list[dict], list[dict]]:
    """
    Process a PDF file.
    Returns (text_blocks, images, []) where text_blocks have type/text/size/bold/y/page
    and images have data/ext/y/page.
    """
    fitz = _check_pymupdf()
    doc = fitz.open(file_path)
    all_blocks: list[dict] = []
    all_images: list[dict] = []
    for page in doc:
        all_blocks.extend(_extract_pdf_text_blocks(page, fitz))
        all_images.extend(_extract_pdf_images(page, doc))
    doc.close()
    return all_blocks, all_images, []


# ── DOCX processing ─────────────────────────────────────────────────

def _check_docx():
    try:
        import docx
        return docx
    except ImportError:
        print("Error: python-docx is required for Word files. Install with:")
        print("  pip install python-docx")
        sys.exit(1)


def process_docx(file_path: str) -> tuple[list[dict], list[dict], list[dict]]:
    """
    Process a Word .docx file.
    Returns (text_blocks, images, []) matching the same structure as process_pdf.
    """
    docx_mod = _check_docx()
    from docx.oxml.ns import qn

    doc = docx_mod.Document(file_path)

    # ── Extract images from the docx media ──
    # DOCX is a ZIP; images live in word/media/
    SKIP_FORMATS = {"emf", "wmf", "tiff", "bmp"}
    media_images: dict[str, dict] = {}  # rId -> {data, ext}
    for rel in doc.part.rels.values():
        if "image" in rel.reltype:
            blob = rel.target_part.blob
            ct = rel.target_part.content_type
            ext = ext_from_content_type(ct)
            if ext in SKIP_FORMATS:
                continue
            media_images[rel.rId] = {"data": blob, "ext": ext}

    # ── Walk paragraphs to extract text blocks + inline image positions ──
    text_blocks: list[dict] = []
    all_images: list[dict] = []
    block_idx = 0  # acts as a virtual "y" position since docx has no coordinates

    for para in doc.paragraphs:
        style_name = (para.style.name or "").lower()
        text = para.text.strip()

        # Detect heading level from style
        is_heading = False
        heading_level = 0
        if style_name.startswith("heading"):
            is_heading = True
            try:
                heading_level = int(style_name.replace("heading", "").strip())
            except ValueError:
                heading_level = 1

        # Detect bold (entire paragraph is bold)
        is_bold = False
        if para.runs:
            is_bold = all(run.bold for run in para.runs if run.text.strip())

        # Map heading level to a virtual font size for consistency with PDF logic
        if is_heading:
            size = max(24 - (heading_level - 1) * 4, 14)  # H1=24, H2=20, H3=16, H4=14
        else:
            size = 12  # body text

        if text:
            text_blocks.append({
                "type": "text", "text": text, "size": size,
                "bold": is_bold or is_heading, "y": block_idx, "page": 0,
            })

        # Check for inline images in this paragraph
        for run in para.runs:
            drawing_elements = run._element.findall(f".//{qn('wp:inline')}")
            drawing_elements += run._element.findall(f".//{qn('wp:anchor')}")
            for drawing in drawing_elements:
                blip = drawing.find(f".//{qn('a:blip')}")
                if blip is not None:
                    r_embed = blip.get(qn("r:embed"))
                    if r_embed and r_embed in media_images:
                        img = media_images[r_embed]
                        all_images.append({
                            "data": img["data"], "ext": img["ext"],
                            "y": block_idx, "page": 0,
                        })

        block_idx += 1

    return text_blocks, all_images, []


# ── Shared: build categories & items from text blocks ────────────────

def build_structure(
    all_blocks: list[dict],
    all_images: list[dict],
    args: argparse.Namespace,
    file_path: str,
) -> tuple[dict, dict[str, bytes]]:
    """
    Convert text blocks + images into a ProjectArchive dict and image file map.
    """
    if not all_blocks:
        print("Warning: No text content found in document.")

    # Determine heading threshold
    heading_threshold = _detect_heading_threshold(all_blocks)

    # Build categories and items
    categories: list[dict] = []
    current_category: dict | None = None
    current_item: dict | None = None

    for block in all_blocks:
        is_heading = block["size"] >= heading_threshold or (
            block["bold"] and len(block["text"]) < 100
        )

        if is_heading:
            text = block["text"].strip()
            if current_category is None or block["size"] >= heading_threshold:
                current_category = {
                    "name": text, "items": [],
                    "page": block["page"], "y": block["y"],
                }
                categories.append(current_category)
                current_item = None
            else:
                current_item = {
                    "name": text, "content": "",
                    "page": block["page"], "y": block["y"],
                }
                current_category["items"].append(current_item)
        else:
            if current_item:
                if current_item["content"]:
                    current_item["content"] += "\n\n"
                current_item["content"] += block["text"]
            elif current_category and not current_category["items"]:
                current_item = {
                    "name": current_category["name"],
                    "content": block["text"],
                    "page": block["page"], "y": block["y"],
                }
                current_category["items"].append(current_item)

    # Fallback: single default category
    if not categories:
        categories = [{
            "name": "default",
            "items": [{
                "name": args.name or "Content",
                "content": "\n\n".join(b["text"] for b in all_blocks),
                "page": 0, "y": 0,
            }],
            "page": 0, "y": 0,
        }]

    is_grouped = args.grouped if args.grouped is not None else len(categories) > 1

    # Associate images with nearest content item
    image_files: dict[str, bytes] = {}
    item_images: dict[int, str] = {}

    flat_items: list[dict] = []
    for cat in categories:
        for item in cat["items"]:
            flat_items.append(item)

    for img in all_images:
        best_idx = 0
        best_dist = float("inf")
        for i, item in enumerate(flat_items):
            if item["page"] == img["page"]:
                dist = abs(item["y"] - img["y"])
            else:
                dist = abs(item["page"] - img["page"]) * 10000 + abs(item["y"] - img["y"])
            if dist < best_dist:
                best_dist = dist
                best_idx = i

        if best_idx not in item_images:
            item_name = sanitize_filename(flat_items[best_idx]["name"])
            ext = img["ext"] if img["ext"] in ("jpg", "jpeg", "png", "webp", "gif") else "jpg"
            filename = f"{best_idx}-{item_name}.{ext}"
            zip_path = f"images/content/{filename}"
            image_files[zip_path] = img["data"]
            item_images[best_idx] = zip_path

    # Build project.json
    content_items = []
    item_idx = 0
    for cat in categories:
        content_items.append({
            "name": cat["name"], "content": "", "ai_knowledge_base": "",
            "sort_order": len(content_items), "parent_name": None,
            "image": None, "crop_parameters": None,
            "translations": None, "content_hash": None,
        })
        for item in cat["items"]:
            content_items.append({
                "name": item["name"], "content": item["content"],
                "ai_knowledge_base": "", "sort_order": len(content_items),
                "parent_name": cat["name"],
                "image": item_images.get(item_idx),
                "crop_parameters": None, "translations": None, "content_hash": None,
            })
            item_idx += 1

    project = {
        "version": 1,
        "exportedAt": datetime.now(timezone.utc).isoformat(),
        "card": {
            "name": args.name or os.path.splitext(os.path.basename(file_path))[0],
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


# ── ZIP creation ─────────────────────────────────────────────────────

def create_zip(project: dict, image_files: dict[str, bytes], output_path: str) -> None:
    """Package project.json and images into a ZIP archive."""
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("project.json", json.dumps(project, indent=2, ensure_ascii=False))
        for path, data in image_files.items():
            zf.writestr(path, data)


# ── CLI ──────────────────────────────────────────────────────────────

SUPPORTED_EXTENSIONS = {".pdf", ".docx"}


def main():
    parser = argparse.ArgumentParser(
        description="Extract text + images from a PDF or Word document and generate a FunTell project archive ZIP."
    )
    parser.add_argument("input", help="Path to the input file (.pdf or .docx)")
    parser.add_argument("-o", "--output", help="Output ZIP path (default: {input}_archive.zip)")
    parser.add_argument("-n", "--name", help="Project name (default: filename)")
    parser.add_argument("-l", "--language", default="en", help="Original language code (default: en)")
    parser.add_argument("-m", "--mode", default="list", choices=["single", "list", "grid", "cards"],
                        help="Content mode (default: list)")
    parser.add_argument("-g", "--grouped", default=None, action="store_true",
                        help="Enable grouped categories (default: auto-detect)")

    args = parser.parse_args()

    if not os.path.isfile(args.input):
        print(f"Error: File not found: {args.input}")
        sys.exit(1)

    ext = os.path.splitext(args.input)[1].lower()
    if ext not in SUPPORTED_EXTENSIONS:
        print(f"Error: Unsupported file type '{ext}'. Supported: {', '.join(SUPPORTED_EXTENSIONS)}")
        sys.exit(1)

    if not args.output:
        base = os.path.splitext(args.input)[0]
        args.output = f"{base}_archive.zip"

    print(f"Processing: {args.input} ({ext})")

    # Dispatch to format-specific processor
    if ext == ".pdf":
        all_blocks, all_images, _ = process_pdf(args.input)
    else:  # .docx
        all_blocks, all_images, _ = process_docx(args.input)

    # Build structure and create archive
    project, image_files = build_structure(all_blocks, all_images, args, args.input)
    create_zip(project, image_files, args.output)

    # Summary
    items = [ci for ci in project["contentItems"] if ci["parent_name"] is not None]
    cats = [ci for ci in project["contentItems"] if ci["parent_name"] is None]
    images_with = sum(1 for ci in items if ci.get("image"))

    print(f"\nArchive created: {args.output}")
    print(f"  Categories: {len(cats)}")
    print(f"  Content items: {len(items)}")
    print(f"  Images: {len(image_files)} extracted, {images_with} associated with items")
    print(f"  Content mode: {args.mode}, Grouped: {project['card']['is_grouped']}")
    print(f"\nImport this ZIP via the FunTell web portal: Dashboard > Import")


if __name__ == "__main__":
    main()
