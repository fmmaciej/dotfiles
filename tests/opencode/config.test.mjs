import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import test from "node:test"

const root = new URL("../../", import.meta.url)
const config = JSON.parse(readFileSync(new URL("opencode/.config/opencode/cli.json", root), "utf8"))
const plugin = new URL("opencode/.config/opencode/plugins/personal-ui/", root)

test("global CLI configuration enables the local TUI-only package", () => {
  assert.equal(config.$schema, "https://opencode.ai/v2/cli.json")
  const entry = config.plugins.find((item) => item.package === "./plugins/personal-ui")
  assert.ok(entry)
  assert.equal(typeof entry.options.animations, "boolean")
  assert.equal(config.tabs.mode, "off")
  assert.equal(config.session.sidebar, "auto")
  assert.equal(config.instructions, undefined)
  assert.equal(config.permissions, undefined)
})

test("keybinds retain the existing leader and resolve native tab conflicts", () => {
  assert.equal(config.keybinds.leader, "ctrl+b")
  assert.equal(config.keybinds["input.line.home"], "home")
  assert.equal(config.keybinds["input.move.left"], "left")
  assert.equal(config.keybinds["session.new"], "<leader>c")
  for (const key of ["session.background", "session.compact", "session.export", "session.tab.next", "session.tab.previous", "session.tab.close"]) {
    assert.equal(config.keybinds[key], "none")
  }
  for (let index = 1; index <= 10; index++) {
    assert.equal(config.keybinds[`session.tab.select.${index}`], "none")
  }
})

test("plugin keeps its identity and storage keys without depending on Kei", () => {
  const source = readFileSync(new URL("tui.tsx", plugin), "utf8")
  const manifest = JSON.parse(readFileSync(new URL("package.json", plugin), "utf8"))
  assert.equal(manifest.name, "kei-terminal-ui")
  assert.equal(manifest.exports["./tui"], "./tui.tsx")
  assert.match(source, /id: "kei\.terminal-ui"/)
  assert.ok(source.includes("`tabs-${scope}`"))
  assert.ok(source.includes("context.options.animations"))
  assert.doesNotMatch(source, /KEI_TUI_ENABLED|KEI_UI_ANIMATIONS|00-system\//)
})
