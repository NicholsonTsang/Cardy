/**
 * Project archive utilities for ZIP-based import/export.
 *
 * Archive format:
 *   project.json          — typed card + content metadata
 *   images/card.*         — card cover image (full quality)
 *   images/content/N-slug.* — content item images (full quality)
 */
import JSZip from 'jszip'
import type { CropParameters } from './imageCropUtils'

// ─── Archive schema (version 1) ────────────────────────────────

export const ARCHIVE_VERSION = 1

export type ContentMode = 'single' | 'list' | 'grid' | 'cards'
export type GroupDisplay = 'expanded' | 'collapsed'
export type BillingType = 'digital'
export type QrPosition = 'TL' | 'TR' | 'BL' | 'BR'

export interface ArchiveCard {
  name: string
  description: string
  original_language: string
  content_mode: ContentMode
  is_grouped: boolean
  group_display: GroupDisplay
  conversation_ai_enabled: boolean
  ai_instruction: string
  ai_knowledge_base: string
  ai_welcome_general: string
  ai_welcome_item: string
  qr_code_position: QrPosition
  image: string | null
  crop_parameters: CropParameters | null
  translations: Record<string, unknown> | null
  content_hash: string | null
  metadata?: Record<string, unknown> | null
}

export interface ArchiveContentItem {
  name: string
  content: string
  ai_knowledge_base: string
  sort_order: number
  parent_name: string | null // null = category (L1), string = child of named parent (L2)
  image: string | null
  crop_parameters: CropParameters | null
  translations: Record<string, unknown> | null
  content_hash: string | null
}

export interface ProjectArchive {
  version: number
  exportedAt: string
  card: ArchiveCard
  contentItems: ArchiveContentItem[]
}

// ─── Import result ──────────────────────────────────────────────

export interface ImportedCard {
  card: ArchiveCard
  contentItems: ArchiveContentItem[]
  /** path → File  (only for entries that reference an image) */
  images: Map<string, File>
}

export interface ImportResult {
  cards: ImportedCard[]
  errors: string[]
  warnings: string[]
  isValid: boolean
}

// ─── Utility exports ────────────────────────────────────────────

/**
 * Calculate content hash for verification (exported for use in other modules)
 */
export async function calculateHash(content: string): Promise<string> {
  return calculateContentHash(content)
}

/**
 * Estimate export size in bytes (exported for pre-export checks)
 */
export function estimateSize(
  card: Record<string, unknown>,
  contentItems: Record<string, unknown>[]
): number {
  return estimateExportSize(card, contentItems)
}

// ─── Helpers ────────────────────────────────────────────────────

function sanitizeFilename(name: string): string {
  return name
    .replace(/[^a-z0-9_\-. ]/gi, '')
    .replace(/\s+/g, '-')
    .substring(0, 80) || 'untitled'
}

function extensionFromUrl(url: string): string {
  try {
    const pathname = new URL(url).pathname
    const ext = pathname.split('.').pop()?.toLowerCase()
    if (ext && ['jpg', 'jpeg', 'png', 'webp', 'gif'].includes(ext)) return ext
  } catch { /* ignore */ }
  return 'jpg'
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

/**
 * Fetch image with retry logic and exponential backoff
 */
async function fetchImageAsFile(url: string, filename: string, maxRetries = 3): Promise<File | null> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const res = await fetch(url)
      if (!res.ok) {
        if (attempt === maxRetries - 1) return null
        await sleep(1000 * Math.pow(2, attempt)) // Exponential backoff: 1s, 2s, 4s
        continue
      }
      const blob = await res.blob()
      return new File([blob], filename, { type: blob.type || 'image/jpeg' })
    } catch (err) {
      if (attempt === maxRetries - 1) return null
      await sleep(1000 * Math.pow(2, attempt))
    }
  }
  return null
}

/**
 * Calculate content hash for integrity verification
 */
async function calculateContentHash(content: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(content)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

/**
 * Estimate export size in bytes
 */
function estimateExportSize(
  card: Record<string, unknown>,
  contentItems: Record<string, unknown>[]
): number {
  const jsonSize = JSON.stringify({ card, contentItems }).length
  const imageCount = (card.image_url ? 1 : 0) +
    contentItems.filter(item => item.image_url).length
  // Rough estimate: 500KB per image + JSON size
  return jsonSize + (imageCount * 500 * 1024)
}

// ─── Export ─────────────────────────────────────────────────────

/**
 * Export a project (card + content items) to a ZIP Blob.
 *
 * @param card       Card record from the database (as returned by get_card_by_id)
 * @param contentItems  Content items from get_card_content_items
 * @param options    Export options (timeout, compression)
 */
export async function exportProject(
  card: Record<string, unknown>,
  contentItems: Record<string, unknown>[],
  options?: { timeout?: number; compressionLevel?: number }
): Promise<{ blob: Blob; imageCount: number; estimatedSize: number }> {
  const timeout = options?.timeout || 5 * 60 * 1000 // 5 minutes default
  const compressionLevel = options?.compressionLevel || 6

  // Estimate size before starting
  const estimatedSize = estimateExportSize(card, contentItems)

  // Wrap export in timeout promise
  const exportPromise = async (): Promise<{ blob: Blob; imageCount: number; estimatedSize: number }> => {
  const zip = new JSZip()
  const imgFolder = zip.folder('images')!
  const contentImgFolder = imgFolder.folder('content')!
  let imageCount = 0

  // --- Card image ---
  let cardImagePath: string | null = null
  const originalImageUrl = (card.original_image_url || card.image_url) as string | null
  if (originalImageUrl) {
    const ext = extensionFromUrl(originalImageUrl)
    const fname = `card.${ext}`
    const file = await fetchImageAsFile(originalImageUrl, fname)
    if (file) {
      imgFolder.file(fname, file)
      cardImagePath = `images/${fname}`
      imageCount++
    }
  }

  // --- Content items ---
  // Build parent lookup: id → name (for L2 items to reference their parent)
  const parentNameById = new Map<string, string>()
  for (const item of contentItems) {
    if (item.parent_id === null || item.parent_id === undefined) {
      parentNameById.set(item.id as string, item.name as string)
    }
  }

  const archiveItems: ArchiveContentItem[] = []
  for (let i = 0; i < contentItems.length; i++) {
    const item = contentItems[i]

    // Image
    let itemImagePath: string | null = null
    const itemOrigImageUrl = (item.original_image_url || item.image_url) as string | null
    if (itemOrigImageUrl) {
      const ext = extensionFromUrl(itemOrigImageUrl)
      const fname = `${i}-${sanitizeFilename(item.name as string)}.${ext}`
      const file = await fetchImageAsFile(itemOrigImageUrl, fname)
      if (file) {
        contentImgFolder.file(fname, file)
        itemImagePath = `images/content/${fname}`
        imageCount++
      }
    }

    // Crop params
    let cropParams: CropParameters | null = null
    if (item.crop_parameters) {
      cropParams = typeof item.crop_parameters === 'string'
        ? JSON.parse(item.crop_parameters)
        : item.crop_parameters as CropParameters
    }

    // Translations
    let translations: Record<string, unknown> | null = null
    if (item.translations) {
      translations = typeof item.translations === 'string'
        ? JSON.parse(item.translations)
        : item.translations as Record<string, unknown>
    }

    const parentId = item.parent_id as string | null
    archiveItems.push({
      name: item.name as string,
      content: (item.content || '') as string,
      ai_knowledge_base: (item.ai_knowledge_base || '') as string,
      sort_order: (item.sort_order ?? i) as number,
      parent_name: parentId ? (parentNameById.get(parentId) ?? null) : null,
      image: itemImagePath,
      crop_parameters: cropParams,
      translations,
      content_hash: (item.content_hash as string) || null,
    })
  }

  // Card crop params
  let cardCropParams: CropParameters | null = null
  if (card.crop_parameters) {
    cardCropParams = typeof card.crop_parameters === 'string'
      ? JSON.parse(card.crop_parameters as string)
      : card.crop_parameters as CropParameters
  }

  // Card translations
  let cardTranslations: Record<string, unknown> | null = null
  if (card.translations) {
    cardTranslations = typeof card.translations === 'string'
      ? JSON.parse(card.translations as string)
      : card.translations as Record<string, unknown>
  }

  const archive: ProjectArchive = {
    version: ARCHIVE_VERSION,
    exportedAt: new Date().toISOString(),
    card: {
      name: card.name as string,
      description: (card.description || '') as string,
      original_language: (card.original_language || 'en') as string,
      content_mode: (card.content_mode || 'list') as ContentMode,
      is_grouped: !!card.is_grouped,
      group_display: (card.group_display || 'expanded') as GroupDisplay,
      conversation_ai_enabled: !!card.conversation_ai_enabled,
      ai_instruction: (card.ai_instruction || '') as string,
      ai_knowledge_base: (card.ai_knowledge_base || '') as string,
      ai_welcome_general: (card.ai_welcome_general || '') as string,
      ai_welcome_item: (card.ai_welcome_item || '') as string,
      qr_code_position: (card.qr_code_position || 'BR') as QrPosition,
      image: cardImagePath,
      crop_parameters: cardCropParams,
      translations: cardTranslations,
      content_hash: (card.content_hash as string) || null,
      metadata: (card.metadata as Record<string, unknown>) || null,
    },
    contentItems: archiveItems,
  }

    zip.file('project.json', JSON.stringify(archive, null, 2))

    const blob = await zip.generateAsync({
      type: 'blob',
      compression: 'DEFLATE',
      compressionOptions: { level: compressionLevel }
    })
    return { blob, imageCount, estimatedSize }
  }

  // Apply timeout
  const timeoutPromise = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error(`Export timeout after ${timeout}ms`)), timeout)
  )

  return Promise.race([exportPromise(), timeoutPromise])
}

/**
 * Export multiple projects into a single ZIP containing nested ZIPs.
 * Each project becomes its own ZIP file inside the outer archive.
 */
export async function exportMultipleProjects(
  projects: Array<{ card: Record<string, unknown>; contentItems: Record<string, unknown>[] }>
): Promise<Blob> {
  const outerZip = new JSZip()

  for (let i = 0; i < projects.length; i++) {
    const { card, contentItems } = projects[i]
    const { blob } = await exportProject(card, contentItems)
    const safeName = sanitizeFilename(card.name as string || `project-${i + 1}`)
    outerZip.file(`${safeName}.zip`, blob)
  }

  return outerZip.generateAsync({ type: 'blob', compression: 'DEFLATE', compressionOptions: { level: 6 } })
}

// ─── Import ─────────────────────────────────────────────────────

const VALID_CONTENT_MODES: ContentMode[] = ['single', 'list', 'grid', 'cards']
const VALID_GROUP_DISPLAYS: GroupDisplay[] = ['expanded', 'collapsed']
const VALID_QR_POSITIONS: QrPosition[] = ['TL', 'TR', 'BL', 'BR']

function validateCardData(raw: Record<string, unknown>, warnings: string[]): ArchiveCard {
  // Content mode — map legacy values
  let contentMode = (raw.content_mode || 'list') as string
  if (contentMode === 'inline') { contentMode = 'cards'; warnings.push('Mapped legacy content_mode "inline" to "cards"') }
  if (contentMode === 'grouped') { contentMode = 'list'; warnings.push('Mapped legacy content_mode "grouped" to "list"') }
  if (!VALID_CONTENT_MODES.includes(contentMode as ContentMode)) {
    warnings.push(`Invalid content_mode "${contentMode}", defaulting to "list"`)
    contentMode = 'list'
  }

  let groupDisplay = (raw.group_display || 'expanded') as string
  if (!VALID_GROUP_DISPLAYS.includes(groupDisplay as GroupDisplay)) {
    warnings.push(`Invalid group_display "${groupDisplay}", defaulting to "expanded"`)
    groupDisplay = 'expanded'
  }

  let qrPosition = (raw.qr_code_position || 'BR') as string
  if (!VALID_QR_POSITIONS.includes(qrPosition as QrPosition)) {
    warnings.push(`Invalid qr_code_position "${qrPosition}", defaulting to "BR"`)
    qrPosition = 'BR'
  }

  return {
    name: (raw.name || 'Untitled') as string,
    description: (raw.description || '') as string,
    original_language: (raw.original_language || 'en') as string,
    content_mode: contentMode as ContentMode,
    is_grouped: !!raw.is_grouped,
    group_display: groupDisplay as GroupDisplay,
    conversation_ai_enabled: !!raw.conversation_ai_enabled,
    ai_instruction: (raw.ai_instruction || '') as string,
    ai_knowledge_base: (raw.ai_knowledge_base || '') as string,
    ai_welcome_general: (raw.ai_welcome_general || '') as string,
    ai_welcome_item: (raw.ai_welcome_item || '') as string,
    qr_code_position: qrPosition as QrPosition,
    image: (raw.image as string) || null,
    crop_parameters: (raw.crop_parameters as CropParameters) || null,
    translations: (raw.translations as Record<string, unknown>) || null,
    content_hash: (raw.content_hash as string) || null,
    metadata: (raw.metadata as Record<string, unknown>) || null,
  }
}

/**
 * Import one or more ZIP files into ImportResult.
 *
 * Supports both single File and File[] for multi-file import.
 */
export async function importProject(files: File | File[]): Promise<ImportResult> {
  const fileArray = Array.isArray(files) ? files : [files]
  const result: ImportResult = { cards: [], errors: [], warnings: [], isValid: true }

  for (const file of fileArray) {
    try {
      const zip = await JSZip.loadAsync(file)

      const projectJsonFile = zip.file('project.json')
      if (!projectJsonFile) {
        // Check for nested ZIPs (multi-project export from exportMultipleProjects)
        const nestedZipFiles = zip.file(/\.zip$/)
        if (nestedZipFiles.length > 0) {
          for (const nestedZipEntry of nestedZipFiles) {
            try {
              const nestedBlob = await nestedZipEntry.async('blob')
              const nestedFile = new File([nestedBlob], nestedZipEntry.name, { type: 'application/zip' })
              const nestedResult = await importProject(nestedFile)
              result.cards.push(...nestedResult.cards)
              result.errors.push(...nestedResult.errors)
              result.warnings.push(...nestedResult.warnings)
            } catch (nestedErr) {
              const msg = nestedErr instanceof Error ? nestedErr.message : String(nestedErr)
              result.errors.push(`${file.name}/${nestedZipEntry.name}: ${msg}`)
            }
          }
          continue
        }
        result.errors.push(`${file.name}: Missing project.json`)
        continue
      }

      const jsonText = await projectJsonFile.async('string')
      let archive: ProjectArchive
      try {
        archive = JSON.parse(jsonText)
      } catch {
        result.errors.push(`${file.name}: Invalid JSON in project.json`)
        continue
      }

      if (!archive.card || !archive.card.name) {
        result.errors.push(`${file.name}: Missing card data in project.json`)
        continue
      }

      // Validate card data
      const card = validateCardData(archive.card as unknown as Record<string, unknown>, result.warnings)
      const contentItems = (archive.contentItems || []) as ArchiveContentItem[]

      // Extract images referenced by the archive
      const images = new Map<string, File>()

      // Card image
      if (card.image) {
        const imgFile = zip.file(card.image)
        if (imgFile) {
          const blob = await imgFile.async('blob')
          const name = card.image.split('/').pop() || 'card.jpg'
          images.set(card.image, new File([blob], name, { type: blobTypeFromName(name) }))
        } else {
          result.warnings.push(`${file.name}: Card image "${card.image}" referenced but not found in archive`)
        }
      }

      // Content item images
      for (const item of contentItems) {
        if (item.image) {
          const imgFile = zip.file(item.image)
          if (imgFile) {
            const blob = await imgFile.async('blob')
            const name = item.image.split('/').pop() || 'image.jpg'
            images.set(item.image, new File([blob], name, { type: blobTypeFromName(name) }))
          } else {
            result.warnings.push(`${file.name}: Image "${item.image}" for item "${item.name}" not found in archive`)
          }
        }

        // Validate content hash if present
        if (item.content_hash && item.content) {
          try {
            const calculatedHash = await calculateContentHash(item.content)
            if (calculatedHash !== item.content_hash) {
              result.warnings.push(`${file.name}: Content hash mismatch for "${item.name}" - data may have been modified`)
            }
          } catch (err) {
            result.warnings.push(`${file.name}: Failed to validate content hash for "${item.name}"`)
          }
        }
      }

      // Validate card description hash if present
      if (card.content_hash && card.description) {
        try {
          const calculatedHash = await calculateContentHash(card.description)
          if (calculatedHash !== card.content_hash) {
            result.warnings.push(`${file.name}: Card description hash mismatch - data may have been modified`)
          }
        } catch (err) {
          result.warnings.push(`${file.name}: Failed to validate card description hash`)
        }
      }

      result.cards.push({ card, contentItems, images })
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e)
      result.errors.push(`${file.name}: ${msg}`)
    }
  }

  if (result.cards.length === 0 && result.errors.length > 0) {
    result.isValid = false
  }

  return result
}

function blobTypeFromName(name: string): string {
  const ext = name.split('.').pop()?.toLowerCase()
  const types: Record<string, string> = {
    jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png',
    webp: 'image/webp', gif: 'image/gif',
  }
  return types[ext || ''] || 'image/jpeg'
}
