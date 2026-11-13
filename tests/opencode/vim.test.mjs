import assert from "node:assert/strict"
import { createHash } from "node:crypto"
import { readFileSync } from "node:fs"
import test from "node:test"
import {
  sessionState, statusLayout, tabIcon, tabSpinnerFrames, vimField, vimLabels, vimLabelWidth, vimPrefixWidth, visibleTabs,
} from "../../opencode/.config/opencode/plugins/personal-ui/state.mjs"

test("Vim labels are right aligned in seven cells with exactly one space before the separator", () => {
  assert.equal(vimLabelWidth, 7)
  assert.equal(vimPrefixWidth, 9)
  for (const mode of Object.keys(vimLabels)) {
    const field = vimField(mode)
    assert.equal(field.length, vimPrefixWidth)
    assert.equal(field.indexOf("│"), 8)
    assert.equal(field[7], " ")
    assert.notEqual(field[6], " ")
    assert.equal(field.slice(0, 7).trim(), vimLabels[mode])
  }
  assert.equal(vimField("insert"), " INSERT │")
  assert.equal(vimField("replace"), "REPLACE │")
  assert.equal(vimField("normal"), " NORMAL │")
})

test("character and line visual modes share VISUAL, not VISUAL LINE", () => {
  assert.equal(vimField("visual"), " VISUAL │")
  assert.equal(vimField("visual-line"), vimField("visual"))
})

test("disabled Vim keeps the same field width without retaining a stale mode label", () => {
  for (const mode of Object.keys(vimLabels)) assert.equal(vimField(mode, false), "    OFF │")
  assert.equal(vimField("unknown"), "      ? │")
})

test("Vim modes, all six Kei states, and spinner frames never move either separator or the tabs", () => {
  const states = [
    sessionState({}), sessionState({ running: true }), sessionState({ permissions: 1 }),
    sessionState({ forms: 1 }), sessionState({ outcome: "failed" }), sessionState({ outcome: "interrupted" }),
  ]
  for (const columns of [32, 40, 72, 160]) {
    const keiWidth = statusLayout(states[0], columns - vimPrefixWidth).width
    for (const mode of Object.keys(vimLabels)) {
      for (const state of states) {
        const layout = statusLayout(state, columns - vimPrefixWidth)
        assert.equal(layout.width, keiWidth)
        for (let frame = 0; frame < tabSpinnerFrames.length; frame++) {
          const kei = ` Kei: ${layout.text} ${tabIcon(state, frame)} │`
          const row = vimField(mode) + kei + " 0: session"
          assert.equal(kei.length, keiWidth)
          assert.equal(row.indexOf("│"), 8)
          assert.equal(row.indexOf("│", 9), vimPrefixWidth + keiWidth - 1)
          assert.equal(row.indexOf("0: "), vimPrefixWidth + keiWidth + 1)
        }
      }
    }
  }
})

test("vendored prompt and Vim engine is byte-for-byte the verified upstream beta", () => {
  const bytes = readFileSync(new URL("../../opencode/.config/opencode/plugins/personal-ui/vendor/vim.js", import.meta.url))
  const boundary = bytes.indexOf("// src/tui.tsx\nvar PLUGIN_ID")
  assert.equal(boundary, 148263)
  assert.equal(createHash("sha256").update(bytes.subarray(0, boundary)).digest("hex"),
    "baec1b3a2473eec8cd12c2fe3c358c630b4354b0156ff0651f13b3658e48b3a4")
  const setup = bytes.subarray(boundary).toString("utf8")
  assert.match(setup, /function setupVim\(context\)/)
  assert.doesNotMatch(setup, /append: "prompt\.footer\.status"/)
  assert.match(setup, /append: "app",\s+render: \(\) => _\$createComponent\(KeymapSetup/)
  assert.match(setup, /return \{ enabled, mode: prompt\.mode, dispose:/)
  assert.match(setup, /releaseStatusSlot\(\);\s+prompt\.dispose\(\)/)
  assert.doesNotMatch(setup, /Plugin\.define/)
})

test("a 32-column bar still budgets enough room for the active tab number and icon", () => {
  const columns = 32
  const kei = statusLayout(sessionState({}), columns - vimPrefixWidth)
  const budget = columns - vimPrefixWidth - kei.width
  const [tab] = visibleTabs([{ sessionID: "a", title: "A long session title" }], "a", budget)
  assert.ok(tab.label.startsWith("0: "))
  assert.ok(tab.label.length + 5 <= tab.width)
  assert.ok(vimPrefixWidth + kei.width + tab.width <= columns)
})
