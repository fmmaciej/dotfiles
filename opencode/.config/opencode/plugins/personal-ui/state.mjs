// Pure presentation/state helpers; no server calls or persistent side effects.
export function cleanTitle(value, fallback = "Session") {
  return String(value || fallback).replace(/[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]/gu, " ").trim() || fallback
}

export function openTab(tabs, sessionID) {
  return tabs.includes(sessionID) ? [...tabs] : [...tabs, sessionID]
}

export function closeTab(tabs, sessionID) {
  const index = tabs.indexOf(sessionID)
  const remaining = tabs.filter((id) => id !== sessionID)
  return { tabs: remaining, next: remaining[Math.min(Math.max(index, 0), remaining.length - 1)] }
}

export function cycleTab(tabs, active, direction) {
  if (!tabs.length) return undefined
  const index = tabs.indexOf(active)
  if (index === -1) return direction > 0 ? tabs[0] : tabs.at(-1)
  return tabs[(index + direction + tabs.length) % tabs.length]
}

export const tabBindings = Array.from({ length: 10 }, (_, index) => ({
  index, id: `kei.tabs.select.${index}`, title: `Kei: tab ${index}`, bind: `<leader>${index}`,
}))

export function tokenTotal(tokens) {
  if (!tokens) return undefined
  const values = [tokens.input, tokens.output, tokens.reasoning, tokens.cache?.read, tokens.cache?.write]
  if (!values.every((value) => Number.isFinite(value) && value >= 0)) return undefined
  return values.reduce((sum, value) => sum + value, 0)
}

// Same measurement boundary and token categories as OpenCode 2.2.7's contextUsage.
// A completed compaction invalidates the preceding context measurement.
export function contextUsage(messages, models = [], boundary) {
  const end = boundary ? messages.findIndex((message) => message.id === boundary) : messages.length
  if (end < 0) return undefined
  for (let index = end - 1; index >= 0; index--) {
    const message = messages[index]
    if (message.type === "compaction" && message.status === "completed") return undefined
    if (message.type !== "assistant" || !message.tokens) continue
    const used = tokenTotal(message.tokens)
    if (used === undefined || used <= 0) return undefined
    const model = models.find((item) => item.id === message.model?.id && item.providerID === message.model?.providerID)
    const limit = model?.limit?.context
    const maximum = Number.isFinite(limit) && limit > 0 ? limit : undefined
    return { used, limit: maximum, percent: maximum ? Math.round(100 * used / maximum) : undefined }
  }
  return undefined
}

export function contextBar(percent, width = 12) {
  if (!Number.isFinite(percent)) return undefined
  const filled = Math.round(Math.min(100, Math.max(0, percent)) * width / 100)
  return "█".repeat(filled) + "░".repeat(width - filled)
}

export function sessionState({ running, permissions = 0, forms = 0, outcome }) {
  if (permissions) return { kind: "attention", label: "approve", icon: "!" }
  if (forms) return { kind: "attention", label: "reply", icon: "?" }
  if (running) return { kind: "running", label: "working", icon: "" }
  if (outcome === "failed") return { kind: "error", label: "error", icon: "✗" }
  if (outcome === "interrupted") return { kind: "idle", label: "interrupted", icon: "–" }
  return { kind: "idle", label: "ready", icon: "✓" }
}

export const tabSpinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

export function tabIcon(state, frame = 0, animations = true) {
  if (state.kind !== "running") return state.icon
  return animations ? tabSpinnerFrames[frame % tabSpinnerFrames.length] : "⋯"
}

// " Kei: " + label + " " + icon + gap + "│"; work uses gap for a scanner, then " │".
// Labels and glyphs here occupy one cell each. The longest label needs a one-cell gap.
// Only terminal resizing may move the separator, never a status transition.
export function statusLayout(state, terminalWidth) {
  const width = Math.max(0, Math.min(21, Math.floor(terminalWidth) - 8))
  const available = Math.max(0, width - 9)
  const full = state.label
  const text = full.length <= available ? full
    : available ? full.slice(0, available - 1) + "…" : ""
  return { width, icon: state.icon, text, gap: Math.max(0, available - text.length) }
}

// A bidirectional scanner with a fading, directional tail and endpoint pauses,
// following OC's Knight Rider timing: 40 ms ticks, 30/9 endpoint hold frames.
// Levels 1–6 describe dot brightness; 0 is an empty cell (no visible track).
export function scannerFrame(width, frame) {
  width = Math.max(0, Math.floor(width))
  if (!width) return []
  const endHold = 9
  const backwardEnd = width + endHold + width - 1
  const cycle = backwardEnd + 30
  const phase = ((Math.floor(frame) % cycle) + cycle) % cycle
  let position, direction, fade = 0
  if (phase < width) {
    position = phase
    direction = 1
  } else if (phase < width + endHold) {
    position = width - 1
    direction = 1
    fade = phase - width + 1
  } else if (phase < backwardEnd) {
    position = width - 2 - (phase - width - endHold)
    direction = -1
  } else {
    position = 0
    direction = -1
    fade = phase - backwardEnd + 1
  }
  return Array.from({ length: width }, (_, index) => {
    const distance = direction === 1 ? position - index : index - position
    return distance < 0 ? 0 : Math.max(0, 6 - distance - fade)
  })
}

const titleSegmenter = new Intl.Segmenter("en", { granularity: "grapheme" })
const titleCharacters = (value) => Array.from(titleSegmenter.segment(value), (part) => part.segment)

// Ten visible characters, followed by three literal dots only when truncated.
// A smaller room is used only when even the active card cannot fit the terminal.
export function tabTitle(value, room = 13) {
  room = Math.max(0, Math.floor(room))
  const chars = titleCharacters(cleanTitle(value))
  if (chars.length <= Math.min(10, room)) return chars.join("")
  const suffix = "...".slice(0, Math.min(3, room))
  return chars.slice(0, Math.min(10, Math.max(0, room - suffix.length))).join("") + suffix
}

// Pack content-sized cards into a contiguous window containing the active tab.
export function visibleTabs(tabs, active, width) {
  if (!tabs.length) return []
  const budget = Math.max(1, Math.floor(width))
  const index = Math.max(0, tabs.findIndex((tab) => tab.sessionID === active))
  const items = tabs.map((tab, number) => {
    const title = tabTitle(tab.title)
    const prefix = `${number}: `
    // One leading space and the non-shrinking four-cell suffix " icon │".
    return { ...tab, number, width: prefix.length + titleCharacters(title).length + 5, label: `${prefix}${title}` }
  })
  if (items[index].width > budget) {
    const prefix = `${index}: `
    const cellWidth = Math.max(4, budget)
    return [{ ...items[index], width: cellWidth,
      label: prefix + tabTitle(tabs[index].title, cellWidth - prefix.length - 5) }]
  }
  let start = index, end = index + 1
  let remaining = budget - items[index].width
  while (start > 0 || end < items.length) {
    const leftFirst = index - start < end - index - 1
    const candidates = leftFirst ? [start - 1, end] : [end, start - 1]
    const next = candidates.find((candidate) => candidate >= 0 && candidate < items.length
      && items[candidate].width <= remaining)
    if (next === undefined) break
    remaining -= items[next].width
    if (next < start) start = next
    else end = next + 1
  }
  return items.slice(start, end)
}
