import type { Plugin } from "@opencode/plugin/tui"

export function setupVim(context: Plugin.Context): {
  enabled: () => boolean
  mode: () => "insert" | "normal" | "visual" | "visual-line" | "replace" | "copy"
  dispose: () => void
}
