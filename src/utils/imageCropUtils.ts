/**
 * Utility functions for applying crop parameters to images.
 * Used during project import to regenerate cropped images from original images + crop parameters.
 */

export interface CropParameters {
  x?: number
  y?: number
  zoom?: number
  width?: number
  height?: number
  [key: string]: unknown
}

/**
 * Apply crop parameters to an image file and generate a cropped image.
 */
export async function applyCropParametersToImage(
  imageFile: File,
  cropParams: CropParameters,
  aspectRatio: number = 2 / 3
): Promise<File> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    const reader = new FileReader()

    reader.onload = (e) => {
      img.onload = () => {
        try {
          const canvas = document.createElement('canvas')
          const ctx = canvas.getContext('2d')!

          const naturalWidth = img.naturalWidth
          const naturalHeight = img.naturalHeight

          const zoom = cropParams.zoom || 1
          const x = cropParams.x || 0
          const y = cropParams.y || 0
          const cropWidth = cropParams.width || naturalWidth
          const cropHeight = cropParams.height || naturalHeight

          const sourceX = x
          const sourceY = y
          const sourceWidth = cropWidth
          const sourceHeight = cropHeight

          const actualSourceX = Math.max(0, sourceX)
          const actualSourceY = Math.max(0, sourceY)
          const actualSourceRight = Math.min(sourceX + sourceWidth, naturalWidth)
          const actualSourceBottom = Math.min(sourceY + sourceHeight, naturalHeight)
          const actualSourceWidth = Math.max(0, actualSourceRight - actualSourceX)
          const actualSourceHeight = Math.max(0, actualSourceBottom - actualSourceY)

          const outputSize = 800
          let canvasWidth: number
          let canvasHeight: number
          if (aspectRatio >= 1) {
            canvasWidth = outputSize
            canvasHeight = outputSize / aspectRatio
          } else {
            canvasHeight = outputSize
            canvasWidth = outputSize * aspectRatio
          }

          canvas.width = canvasWidth
          canvas.height = canvasHeight

          const destOffsetX = Math.max(0, -sourceX) / sourceWidth
          const destOffsetY = Math.max(0, -sourceY) / sourceHeight
          const destScaleX = actualSourceWidth / sourceWidth
          const destScaleY = actualSourceHeight / sourceHeight

          const destX = destOffsetX * canvasWidth
          const destY = destOffsetY * canvasHeight
          const destWidth = destScaleX * canvasWidth
          const destHeight = destScaleY * canvasHeight

          ctx.fillStyle = '#ffffff'
          ctx.fillRect(0, 0, canvasWidth, canvasHeight)

          if (actualSourceWidth > 0 && actualSourceHeight > 0) {
            ctx.drawImage(
              img,
              actualSourceX, actualSourceY, actualSourceWidth, actualSourceHeight,
              destX, destY, destWidth, destHeight
            )
          }

          canvas.toBlob(
            (blob) => {
              if (!blob) {
                reject(new Error('Failed to create cropped image blob'))
                return
              }
              const croppedFile = new File(
                [blob],
                imageFile.name.replace(/\.(jpg|jpeg|png|webp)$/i, '-cropped.jpg'),
                { type: 'image/jpeg' }
              )
              resolve(croppedFile)
            },
            'image/jpeg',
            0.9
          )
        } catch (error) {
          reject(error)
        }
      }

      img.onerror = () => reject(new Error('Failed to load image'))
      img.src = (e.target as FileReader).result as string
    }

    reader.onerror = () => reject(new Error('Failed to read image file'))
    reader.readAsDataURL(imageFile)
  })
}

/**
 * Check if crop parameters are valid and non-empty.
 */
export function isValidCropParameters(cropParams: unknown): cropParams is CropParameters {
  if (!cropParams || typeof cropParams !== 'object') return false

  const p = cropParams as Record<string, unknown>
  return p.width !== undefined || p.height !== undefined ||
         p.x !== undefined || p.y !== undefined
}

/**
 * Parse crop parameters from a JSON string.
 */
export function parseCropParameters(cropParamsString: unknown): CropParameters | null {
  if (!cropParamsString || typeof cropParamsString !== 'string') return null

  try {
    const params = JSON.parse(cropParamsString)
    return isValidCropParameters(params) ? params : null
  } catch {
    return null
  }
}
