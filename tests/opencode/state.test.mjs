import assert from "node:assert/strict"
import test from "node:test"
import {
  cleanTitle, closeTab, contextBar, contextUsage, cycleTab,
  openTab, scannerFrame, sessionState, statusLayout, tabBindings, tabIcon, tabSpinnerFrames, tabTitle, tokenTotal, visibleTabs,
} from "../../opencode/.config/opencode/plugins/personal-ui/state.mjs"

const tokens = { input: 100, output: 20, reasoning: 10, cache: { read: 60, write: 10 } }
const assistant = (id = "a", extra = {}) => ({ id, type: "assistant", tokens, model: { id: "m", providerID: "p" }, ...extra })
const models = [{ id: "m", providerID: "p", limit: { context: 1000 } }]

test("opening tabs is ordered, idempotent and non-mutating", () => {
  const tabs = ["a", "b"]
  assert.deepEqual(openTab(tabs, "c"), ["a", "b", "c"])
  assert.deepEqual(openTab(tabs, "a"), tabs)
  assert.deepEqual(tabs, ["a", "b"])
})

test("closing only changes local tabs and selects a neighbour", () => {
  assert.deepEqual(closeTab(["a", "b", "c"], "b"), { tabs: ["a", "c"], next: "c" })
  assert.deepEqual(closeTab(["a", "b"], "b"), { tabs: ["a"], next: "a" })
  assert.deepEqual(closeTab(["a"], "a"), { tabs: [], next: undefined })
})

test("cycling wraps and handles the unsaved home screen", () => {
  assert.equal(cycleTab(["a", "b"], "b", 1), "a")
  assert.equal(cycleTab(["a", "b"], "a", -1), "b")
  assert.equal(cycleTab(["a", "b"], undefined, -1), "b")
  assert.equal(cycleTab([], undefined, 1), undefined)
})

test("titles cannot inject control sequences or newlines", () => {
  assert.equal(cleanTitle("Audyt\n\u001b[31m\u202e"), "Audyt  [31m")
  assert.equal(cleanTitle(""), "Session")
  assert.equal(cleanTitle("Zażółć gęślą jaźń"), "Zażółć gęślą jaźń")
})

test("context uses the last measured response, not accumulated usage", () => {
  assert.deepEqual(contextUsage([assistant("a"), assistant("b")], models), { used: 200, limit: 1000, percent: 20 })
  assert.equal(tokenTotal(tokens), 200)
  assert.equal(tokenTotal({ input: NaN }), undefined)
})

test("context follows revert boundaries, including unknown boundaries", () => {
  assert.equal(contextUsage([assistant()], models, "missing"), undefined)
  assert.equal(contextUsage([assistant()], models, "a"), undefined)
  assert.equal(contextUsage([assistant(), assistant("b")], models, "b").used, 200)
})

test("completed compaction clears stale context; failed compaction does not", () => {
  const completed = { id: "c", type: "compaction", status: "completed" }
  assert.equal(contextUsage([assistant(), completed], models), undefined)
  assert.equal(contextUsage([assistant(), completed, assistant("b")], models).used, 200)
  assert.equal(contextUsage([assistant(), { ...completed, status: "failed" }], models).used, 200)
})

test("missing or mismatched limits never produce a made-up percentage", () => {
  const value = contextUsage([assistant()], [])
  assert.equal(value.limit, undefined)
  assert.equal(value.percent, undefined)
  assert.equal(contextUsage([assistant()], [{ ...models[0], providerID: "other" }]).limit, undefined)
  assert.equal(contextUsage([assistant("a", { tokens: undefined })], models), undefined)
})

test("bar clamps its drawing but the actual percent is not capped", () => {
  assert.equal(contextBar(150), "█".repeat(12))
  assert.equal(contextBar(-10), "░".repeat(12))
  assert.equal(contextBar(undefined), undefined)
  assert.equal(contextUsage([assistant()], [{ ...models[0], limit: { context: 100 } }]).percent, 200)
})

test("permission and question waiting take precedence over running and past errors", () => {
  assert.equal(sessionState({ running: true, permissions: 1 }).kind, "attention")
  assert.equal(sessionState({ running: true, forms: 1 }).kind, "attention")
  assert.equal(sessionState({ running: true, outcome: "failed" }).kind, "running")
  assert.equal(sessionState({ running: false, outcome: "failed" }).kind, "error")
  assert.equal(sessionState({ running: false, outcome: "interrupted" }).label, "interrupted")
})

test("all six lowercase statuses precede their icon and keep the same separator", () => {
  const states = [
    sessionState({}), sessionState({ running: true }), sessionState({ permissions: 1 }),
    sessionState({ forms: 1 }), sessionState({ outcome: "failed" }), sessionState({ outcome: "interrupted" }),
  ]
  assert.deepEqual(states.map((state) => state.label), ["ready", "working", "approve", "reply", "error", "interrupted"])
  for (const state of states) {
    const layout = statusLayout(state, 120)
    const segment = ` Kei: ${layout.text} ${layout.icon}${" ".repeat(layout.gap)}${layout.icon ? "│" : " │"}`
    assert.equal(layout.width, 21)
    assert.equal(segment.length, 21)
    assert.equal(segment.indexOf("│"), 20)
    assert.equal(segment.indexOf(layout.text), 6)
    if (layout.icon) assert.equal(segment[7 + layout.text.length], layout.icon)
  }
  assert.equal(statusLayout(states[1], 120).gap, 5)
  assert.equal(statusLayout(states[2], 120).gap, 5)
  assert.equal(statusLayout(states[3], 120).gap, 7)
  assert.equal(statusLayout(states[5], 120).gap, 1)
  assert.equal(statusLayout(states[2], 120).text, "approve")
  assert.equal(statusLayout(states[3], 120).text, "reply")
  assert.equal(statusLayout(states[5], 120).text, "interrupted")
})

test("narrow status layouts stay bounded and keep space for a tab", () => {
  for (const width of [0, 5, 8, 16, 30, 48, 72, 120]) {
    const idle = statusLayout(sessionState({}), width)
    const running = statusLayout(sessionState({ running: true }), width)
    const waiting = statusLayout(sessionState({ forms: 1 }), width)
    assert.equal(idle.width, running.width)
    assert.equal(idle.width, waiting.width)
    assert.ok(waiting.width <= Math.max(0, width - 8))
    assert.ok(waiting.gap >= 0)
    assert.ok(waiting.text.length <= Math.max(0, waiting.width - 9))
  }
  assert.ok(statusLayout(sessionState({ outcome: "interrupted" }), 24).text.endsWith("…"))
})

test("scanner crosses all fifteen cells and returns with a fading directional tail", () => {
  assert.deepEqual(scannerFrame(15, 0), [6, ...Array(14).fill(0)])
  assert.deepEqual(scannerFrame(15, 3).slice(0, 6), [3, 4, 5, 6, 0, 0])
  assert.equal(scannerFrame(15, 14)[14], 6)
  assert.equal(scannerFrame(15, 15)[14], 5)
  assert.deepEqual(scannerFrame(15, 24).slice(11), [0, 0, 6, 5])
  assert.equal(scannerFrame(15, 37)[0], 6)
  assert.equal(scannerFrame(15, 38)[0], 5)
  assert.deepEqual(scannerFrame(15, 68), scannerFrame(15, 0))
  for (let frame = 0; frame < 68; frame++) {
    const levels = scannerFrame(15, frame)
    assert.equal(levels.length, 15)
    assert.ok(levels.every((level) => Number.isInteger(level) && level >= 0 && level <= 6))
  }
})

test("scanner handles empty and one-cell gaps", () => {
  assert.deepEqual(scannerFrame(0, 10), [])
  assert.deepEqual(scannerFrame(-1, 0), [])
  assert.deepEqual(scannerFrame(1, 0), [6])
  assert.deepEqual(scannerFrame(1, 1), [5])
  assert.deepEqual(scannerFrame(1, 40), [6])
})

test("English status scanner uses exactly five cells and completes a bidirectional cycle", () => {
  const width = statusLayout(sessionState({ running: true }), 120).gap
  assert.equal(width, 5)
  assert.deepEqual(scannerFrame(width, 0), [6, 0, 0, 0, 0])
  assert.deepEqual(scannerFrame(width, 1), [5, 6, 0, 0, 0])
  assert.deepEqual(scannerFrame(width, 4), [2, 3, 4, 5, 6])
  assert.deepEqual(scannerFrame(width, 14), [0, 0, 0, 6, 5])
  assert.deepEqual(scannerFrame(width, 17), [6, 5, 4, 3, 2])
  assert.deepEqual(scannerFrame(width, 48), scannerFrame(width, 0))
})

test("every animation frame follows working and leaves the separator fixed", () => {
  const layout = statusLayout(sessionState({ running: true }), 120)
  for (let frame = 0; frame < 48; frame++) {
    const dots = scannerFrame(layout.gap, frame).map((level) => level ? "·" : " ").join("")
    const segment = ` Kei: ${layout.text} ${dots} │`
    assert.ok(segment.startsWith(" Kei: working "))
    assert.equal(segment.length, 21)
    assert.equal(segment.indexOf("│"), 20)
    assert.equal(segment[19], " ")
  }
})

test("displayed tab numbers and keyboard shortcuts both start at zero", () => {
  const tabs = Array.from({ length: 10 }, (_, index) => ({ sessionID: `${index}`, title: `Sesja ${index}` }))
  const items = visibleTabs(tabs, "0", 200)
  assert.equal(items[0].label, "0: Sesja 0")
  assert.equal(items[9].label, "9: Sesja 9")
  assert.equal(tabBindings.length, 10)
  for (const binding of tabBindings) {
    assert.equal(binding.bind, `<leader>${binding.index}`)
    assert.equal(binding.id, `kei.tabs.select.${binding.index}`)
    assert.equal(binding.title, `Kei: tab ${binding.index}`)
    assert.equal(items[binding.index].number, binding.index)
  }
})

test("untitled tabs use an English fallback without translating existing titles", () => {
  const tabs = [{ sessionID: "a" }, { sessionID: "b", title: "Moja rozmowa" }]
  const items = visibleTabs(tabs, "a", 100)
  assert.equal(items[0].label, "0: Session")
  assert.equal(items[1].label, "1: Moja rozmo...")
  assert.equal(tabs[1].title, "Moja rozmowa")
})

test("narrow bars keep the active tab and its actual number visible", () => {
  const tabs = Array.from({ length: 20 }, (_, i) => ({ sessionID: `${i}`, title: "Długi tytuł sesji" }))
  const items = visibleTabs(tabs, "18", 30)
  assert.equal(items.length, 1)
  assert.equal(items[0].number, 18)
  assert.equal(items[0].sessionID, "18")
  assert.ok(!items[0].label.includes("\n"))
  assert.deepEqual(visibleTabs([], undefined, 0), [])
})

test("tab icons cover all states with exactly one character", () => {
  const cases = [
    [{}, "✓"], [{ running: true }, "⠋"], [{ permissions: 1 }, "!"],
    [{ forms: 1 }, "?"], [{ outcome: "failed" }, "✗"], [{ outcome: "interrupted" }, "–"],
  ]
  for (const [input, icon] of cases) {
    assert.equal(tabIcon(sessionState(input)), icon)
    assert.equal(Array.from(icon).length, 1)
  }
  const running = sessionState({ running: true })
  assert.deepEqual(tabSpinnerFrames.map((_, frame) => tabIcon(running, frame)), tabSpinnerFrames)
  assert.equal(tabIcon(running, tabSpinnerFrames.length), tabSpinnerFrames[0])
  assert.equal(tabIcon(running, 4, false), "⋯")
  assert.equal(tabIcon(sessionState({ permissions: 1 }), 4, false), "!")
})

test("inactive tabs retain their own activity and are not assigned the active status", () => {
  const tabs = [
    { sessionID: "idle", title: "Plan", activity: sessionState({}) },
    { sessionID: "busy", title: "Code", activity: sessionState({ running: true }) },
    { sessionID: "approval", title: "Review", activity: sessionState({ permissions: 1, running: true }) },
  ]
  const items = visibleTabs(tabs, "idle", 90)
  assert.deepEqual(items.map((tab) => tabIcon(tab.activity, 2)), ["✓", "⠹", "!"])
  assert.deepEqual(items.map((tab) => tab.width), [12, 12, 14])
})

test("truncated tab titles reserve space for an icon and a stationary separator", () => {
  const [tab] = visibleTabs([{ sessionID: "a", title: "A very long session title that must be truncated" }], "a", 17)
  assert.ok(tab.label.endsWith("..."))
  assert.equal(tab.width, 17)
  const states = [
    sessionState({}), sessionState({ running: true }), sessionState({ permissions: 1 }),
    sessionState({ forms: 1 }), sessionState({ outcome: "failed" }), sessionState({ outcome: "interrupted" }),
  ]
  for (const state of states) {
    for (let frame = 0; frame < tabSpinnerFrames.length; frame++) {
      const row = ` ${tab.label} ${tabIcon(state, frame)} │`
      assert.equal(row.length, tab.width)
      assert.equal(row.indexOf("│"), 16)
      assert.equal(Array.from(tabIcon(state, frame)).length, 1)
    }
  }
  assert.equal(visibleTabs([{ sessionID: "a", title: "Title" }], "a", 1)[0].width, 4)
})

test("tab titles keep ten characters before literal dots and preserve shorter names", () => {
  assert.equal(tabTitle("1234567890"), "1234567890")
  assert.equal(tabTitle("1234567890extra"), "1234567890...")
  assert.equal(tabTitle("Plan"), "Plan")
  assert.equal(tabTitle(""), "Session")
  assert.equal(tabTitle("😀".repeat(11)), "😀".repeat(10) + "...")
  assert.equal(tabTitle("e\u0301".repeat(11)), "e\u0301".repeat(10) + "...")
})

test("compact cards leave exactly one space between the displayed name and its icon", () => {
  const items = visibleTabs([
    { sessionID: "a", title: "Plan" }, { sessionID: "b", title: "1234567890extra" },
  ], "a", 136)
  assert.deepEqual(items.map((tab) => tab.width), [12, 21])
  assert.equal(items[1].label, "1: 1234567890...")
  for (const tab of items) {
    const row = ` ${tab.label} ✓ │`
    assert.equal(row.length, tab.width)
    assert.equal(row.indexOf("✓") - row.indexOf(tab.label) - tab.label.length, 1)
  }
})

test("content-sized windows stay within budget, preserve order and include the active card", () => {
  const tabs = Array.from({ length: 20 }, (_, index) => ({
    sessionID: `${index}`, title: index % 2 ? "A very long session title" : "Plan",
  }))
  for (const width of [22, 35, 48, 80, 136]) {
    for (let active = 0; active < tabs.length; active++) {
      const items = visibleTabs(tabs, `${active}`, width)
      assert.ok(items.some((tab) => tab.sessionID === `${active}`))
      assert.ok(items.reduce((sum, tab) => sum + tab.width, 0) <= width)
      assert.ok(items.every((tab, offset) => !offset || tab.number === items[offset - 1].number + 1))
    }
  }
  assert.deepEqual(visibleTabs(tabs.slice(0, 2), undefined, 40).map((tab) => tab.number), [0, 1])
})
