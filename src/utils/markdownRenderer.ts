import { marked } from 'marked'

/**
 * Configure marked to open all links in new tabs using hooks
 */
marked.use({
  hooks: {
    postprocess(html) {
      // Add target="_blank" and rel="noopener noreferrer" to all links for security
      return html.replace(/<a href=/g, '<a target="_blank" rel="noopener noreferrer" href=')
    }
  }
})

/**
 * Render markdown text to HTML with links opening in new tabs
 * @param text Markdown text to render
 * @returns Rendered HTML string
 */
export function renderMarkdown(text: string): string {
  if (!text) return ''
  return marked.parse(text) as string
}

