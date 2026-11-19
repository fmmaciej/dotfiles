import assert from "node:assert/strict"
import test from "node:test"
import {
  cleanTitle, closeTab, contextBar, contextUsage, cycleTab,
  openTab, sessionState, statusLabelWidth, statusLayout, statusSegmentWidth, tabBindings, tabIcon, tabSpinnerFrames, tabTitle, tokenTotal, visibleTabs,
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
  assert.equal(sessionState({ running: false, outcome: "interrupted" }).label, "STOPPED")
  assert.equal(sessionState({ outcome: "interrupted" }).label.length, sessionState({ running: true }).label.length)
  assert.equal(sessionState({ outcome: "interrupted" }).label.length, sessionState({ permissions: 1 }).label.length)
})

test("all six uppercase statuses omit Kei and keep the same icon and separator columns", () => {
  const states = [
    sessionState({}), sessionState({ running: true }), sessionState({ permissions: 1 }),
    sessionState({ forms: 1 }), sessionState({ outcome: "failed" }), sessionState({ outcome: "interrupted" }),
  ]
  assert.deepEqual(states.map((state) => state.label), ["READY", "WORKING", "APPROVE", "REPLY", "ERROR", "STOPPED"])
  for (const state of states) {
    const layout = statusLayout(state, 120)
    const segment = ` ${layout.text} ${tabIcon(state)} │`
    assert.equal(layout.width, 12)
    assert.equal(segment.length, 12)
    assert.equal(segment.indexOf("│"), 11)
    assert.equal(segment.indexOf(state.label), 1)
    assert.equal(segment[9], tabIcon(state))
    assert.ok(!segment.includes("Kei"))
    assert.equal(layout.labelWidth, 7)
    assert.equal(layout.text.trim(), state.label)
  }
  assert.equal(statusLabelWidth, 7)
  assert.equal(statusSegmentWidth, 12)
  assert.equal(statusLayout(states[2], 120).text, "APPROVE")
  assert.equal(statusLayout(states[3], 120).text, "REPLY  ")
  assert.equal(statusLayout(states[5], 120).text, "STOPPED")
})

test("narrow status layouts stay bounded and keep space for a tab", () => {
  for (const width of [0, 5, 8, 16, 30, 48, 72, 120]) {
    const idle = statusLayout(sessionState({}), width)
    const running = statusLayout(sessionState({ running: true }), width)
    const waiting = statusLayout(sessionState({ forms: 1 }), width)
    assert.equal(idle.width, running.width)
    assert.equal(idle.width, waiting.width)
    assert.ok(waiting.width <= Math.max(0, width - 8))
    assert.ok(waiting.labelWidth >= 0)
    assert.equal(waiting.text.length, Math.max(0, waiting.width - 5))
  }
  assert.ok(statusLayout(sessionState({ outcome: "interrupted" }), 18).text.endsWith("…"))
})

test("working uses a one-cell spinner in the same icon column for every frame", () => {
  const state = sessionState({ running: true })
  const layout = statusLayout(state, 120)
  assert.equal(new Set(tabSpinnerFrames).size, 10)
  for (let frame = 0; frame < tabSpinnerFrames.length; frame++) {
    const icon = tabIcon(state, frame)
    const segment = ` ${layout.text} ${icon} │`
    assert.ok(segment.startsWith(" WORKING "))
    assert.equal(icon.length, 1)
    assert.equal(segment[9], icon)
    assert.equal(segment.length, 12)
    assert.equal(segment.indexOf("│"), 11)
    assert.equal(segment[10], " ")
  }
  assert.equal(tabIcon(state, 0, false), "⋯")
})

test("displayed tab numbers and keyboard shortcuts both start at zero", () => {
  const tabs = Array.from({ length: 10 }, (_, index) => ({ sessionID: `${index}`, title: `Sesja ${index}` }))
  const items = visibleTabs(tabs, "0", 200)
  assert.equal(items[0].label, "0 Sesja")
  assert.equal(items[9].label, "9 Sesja")
  assert.equal(tabBindings.length, 10)
  for (const binding of tabBindings) {
    assert.equal(binding.bind, `<leader>${binding.index}`)
    assert.equal(binding.id, `kei.tabs.select.${binding.index}`)
    assert.equal(binding.title, `Kei: tab ${binding.index}`)
    assert.equal(items[binding.index].number, binding.index)
  }
})

test("missing titles use oc and all current session titles use their first word", () => {
  const tabs = [{ sessionID: "a" }, { sessionID: "b", title: "Moja rozmowa" }]
  const items = visibleTabs(tabs, "a", 100)
  assert.equal(items[0].label, "0 oc")
  assert.equal(items[1].label, "1 Moja")
  assert.equal(tabs[1].title, "Moja rozmowa")
})

test("automatic and manual title updates both replace the displayed first word", () => {
  const tab = { sessionID: "a" }
  assert.equal(visibleTabs([tab], "a", 100)[0].label, "0 oc")
  tab.title = "Generated automatic description"
  assert.equal(visibleTabs([tab], "a", 100)[0].label, "0 Generated")
  tab.title = "audyt konfiguracji OpenCode"
  assert.equal(visibleTabs([tab], "a", 100)[0].label, "0 audyt")
  tab.title = "Another generated description"
  assert.equal(visibleTabs([tab], "a", 100)[0].label, "0 Another")
  tab.title = " \t "
  assert.equal(visibleTabs([tab], "a", 100)[0].label, "0 oc")
})

test("narrow bars keep the active tab and its actual number visible", () => {
  const tabs = Array.from({ length: 20 }, (_, i) => ({ sessionID: `${i}`, title: "Długi tytuł sesji" }))
  const items = visibleTabs(tabs, "18", 30)
  assert.ok(items.length >= 1)
  const active = items.find((tab) => tab.sessionID === "18")
  assert.equal(active.number, 18)
  assert.equal(active.sessionID, "18")
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
  assert.deepEqual(items.map((tab) => tab.width), [11, 11, 13])
})

test("truncated tab titles reserve space for an icon and a stationary separator", () => {
  const [tab] = visibleTabs([{ sessionID: "a", title: "averylongsessiontitle description" }], "a", 17)
  assert.equal(tab.label, "0 averylongs")
  assert.ok(!tab.label.includes("..."))
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

test("tab titles keep the first word without a ten-character cap or added dots", () => {
  assert.equal(tabTitle("1234567890"), "1234567890")
  assert.equal(tabTitle("1234567890extra description"), "1234567890extra")
  assert.equal(tabTitle("Plan"), "Plan")
  assert.equal(tabTitle(""), "oc")
  assert.equal(tabTitle(undefined), "oc")
  assert.equal(tabTitle("  audyt\t konfiguracji\nOC  "), "audyt")
  assert.equal(tabTitle("audyt\u00a0konfiguracji"), "audyt")
  assert.equal(tabTitle("audyt konfiguracji", 3), "aud")
  assert.equal(tabTitle("audyt", 0), "")
  assert.equal(tabTitle("😀".repeat(11)), "😀".repeat(11))
  assert.equal(tabTitle("e\u0301".repeat(11), 2), "e\u0301".repeat(2))
})

test("compact cards leave exactly one space between the displayed name and its icon", () => {
  const items = visibleTabs([
    { sessionID: "a", title: "Plan" }, { sessionID: "b", title: "1234567890extra" },
  ], "a", 136)
  assert.deepEqual(items.map((tab) => tab.width), [11, 22])
  assert.equal(items[1].label, "1 1234567890extra")
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
