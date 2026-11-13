# OpenCode terminal UI and Kei entry point

The `opencode` Stow package provides a global TUI-only plugin for OpenCode
**2.2.7**. It is independent of Kei: running `opencode` in any project uses the
same interface. It does not load Kei instructions or change server permissions,
providers, models, accounts, or authentication.

## Configuration

`opencode/.config/opencode/cli.json` preserves the existing theme, diff,
notification, and session preferences and enables `./plugins/personal-ui`.
It also defines the keybinds and disables the native tab strip replaced by
the plugin. Unrelated plugins should remain in the list when editing it.

The plugin keeps its historical package name `kei-terminal-ui`, TUI ID
`kei.terminal-ui`, and per-directory `tabs-<hash>` storage keys. This avoids an
unnecessary identity change. Session data and saved tab state stay in OpenCode's
runtime storage, never in this repository. The visible `Kei:` label and existing
layout are retained; this migration is not a UI redesign.

The plugin's `options.animations` controls its status and tab spinners. Set it
to `false` for static activity indicators. Native UI motion is separately
controlled by the top-level `animations` setting: OpenCode 2.2.7's public plugin
context does not expose that setting, so no private API or launcher is used.
Both are initially enabled, matching the previous configuration.

### Vim editing

The personal UI integrates a local adaptation of
`@leohenon/opencode-vim-plugin@0.2.0-beta.3`, pinned to the tested OpenCode V2
beta (the npm `latest` tag targets V1). Provenance, license, the small setup-only
delta, and upgrade instructions are in `plugins/personal-ui/vendor/README.md`.
It starts in insert mode; `/vim` toggles Vim editing. Escape enters normal
mode, `i` returns to insert, and `v` / `V` starts character/line selection.
Enter adds a newline in insert mode and submits the prompt in normal mode.
The automatic system clipboard register is disabled.

Options live under `personal-ui`'s `options.vim`. The personal keymap uses
priority 200, above Vim's 100, preserving the Ctrl+B leader. Keyboard resources
mount independently of the native footer, which is hidden again. There is no
separate npm Vim entry and no `preservePromptFooter` workaround.

The Vim toggle persists in the personal UI's storage namespace, including
across UI reloads. The old standalone plugin's saved flag is left untouched;
on first use here, `options.vim.enabled` supplies the initial value. Use `/vim`
to switch editing off or on; `OFF` keeps the same field width.

Do not add the standalone npm plugin alongside this integration. To roll back
to that version, restore the previous `cli.json`, `tui.tsx`, and `state.mjs`
together from the pre-integration backup, including its footer compatibility
option. The unused vendor files can remain inert. No Stow is needed for
existing linked files; use `/reload` if automatic reload does not apply.

There are no activation environment variables or project-local discovery
adapters. Global `opencode.jsonc`, service configuration, credentials,
dependencies, databases, and logs are not managed by this package.

## Interface

The bottom bar contains a Vim field, the six activity states, and compact
numbered tabs:

```text
 INSERT │ Kei: ready   ✓ │ 0: …
 NORMAL │ Kei: working ⠋ │ 0: …
 VISUAL │ Kei: stopped – │ 0: …
REPLACE │ Kei: approve ! │ 0: …
```

The Vim label occupies seven cells, right-aligned, followed by exactly one
space and the separator. Character/line selections both display `VISUAL`;
`COPY` and `OFF` also fit without resizing. Pending commands/search text never
expand this mode field. The Kei segment uses a 17-cell budget including its
right separator (18 cells counting both separators). Status labels are padded
to seven cells before a one-cell icon, so every icon occupies the same column
as `approve !` and `stopped –`. `working` cycles through the same ten Braille
spinner frames as running tabs, using one 100 ms timer; disabling animations
shows a static `⋯`. The multi-cell scanner is removed. Neither mode/state transitions nor animation
frames move the separators or the start of the tabs. Resizing can reduce the
Kei budget and truncate tab titles; the nine-cell Vim prefix stays fixed.

Closing a tab does not delete its session. Restored tabs synchronize metadata
and pending questions/permissions, including child sessions, without calling
a model. Tabs are stored separately for each launch directory.

The sidebar shows the selected model and variant, the agent recorded in the
session, the last reported context sample, total usage, and OC-reported cost.
The context sample is not a live estimate. A zero reported cost does not prove
that usage was free. Native prompt model/agent information remains visible
because OC 2.2.7 does not provide a public removal slot.

Leader is **Ctrl+B**, leaving Ctrl+A for tmux:

| Key after leader | Action |
| --- | --- |
| `c` | New session |
| `,` | Rename active session |
| `x` | Close tab without deleting its session |
| `0`–`9` | Select numbered tab |
| `l` | Session list |
| `e` | External prompt editor |
| `b` | Toggle sidebar |

Alt+Up/Down changes tabs, Ctrl+P opens the command palette, and Ctrl+R renames
the session. The comma binding uses the existing public key event workaround
for OC 2.2.7. All owned listeners, timers, and slots are cleaned up on reload.

## Kei entry point

`zsh/.config/zsh/80-kei.zsh` defines one shell function with one instance path:

```text
kei / kei help  show help
kei open        change the current shell directory to the instance
kei run [args]  run OpenCode there; preserve the caller's directory afterward
kei edit        open the instance in VS Code
```

It uses simple Bash-compatible syntax but is loaded by Zsh. A standalone
executable cannot implement `kei open` for the calling terminal. After installing
or changing the function, open a fresh shell or run `exec zsh -l`.

This function is unrelated to the instance's `./00-system/bin/kei`, which still
provides `doctor`, `validate`, and other system operations.

## Checks

From the repository root:

```sh
node --test tests/opencode/*.test.mjs
python3 -B -m unittest discover -s tests/opencode -p 'test_*.py' -v
bash -n zsh/.config/zsh/80-kei.zsh
zsh -f -n zsh/.config/zsh/80-kei.zsh
```

Wrapper tests use synthetic paths and mock executables; they do not start an
editor or model. Typecheck and real TUI smoke tests use isolated runtime copies,
XDG directories, and synthetic sessions. Do not install test dependencies or
write test state inside the Stow packages.

### Verified on 2026-11-12

On OpenCode 2.2.7: 28 JS tests, 7 wrapper tests (each using Bash and Zsh), and
the strict plugin typecheck passed. Isolated real-TUI checks passed with
animations on at 160×42, off at 72×18, and after restoring saved synthetic tabs.
The deployed plugin also loaded normally in the actual Kei directory and an
unrelated directory, without activation flags, inline CLI config, duplicate UI,
or model requests. Real private sessions and saved tabs were not inspected.

The existing global theme, notifications, diff preferences, and session settings
were preserved. An initial Stow attempt refused a CLI file recreated while its
path was temporarily absent; the successful retry replaced the CLI path
atomically. Backups and detailed technical results are retained privately in
the migration runtime, not committed with the configuration.

Vim compatibility was checked in an isolated real PTY with 24 passing checks:
insert/newline, normal/visual motions, Escape, delete/undo, normal Enter,
Ctrl+B session/tab commands in both modes, and command-palette passthrough.
Submission used a safe stub, not a model; interruption of an active model was
not tested. The Vim indicator and existing bottom bar rendered together.

### Vim bar verified on 2026-11-13

On OpenCode 2.2.7, isolated real-PTY checks passed with the native footer hidden:
45 interaction checks per run, including character/line visual, replace/undo,
Vim off/native editing/on, all six synthetic Kei states, and two actual UI
reinitializations. The toggle survived reload, the editing layer remained
single, and the keyboard listener count returned to its original value.
Geometry checks passed across rendered frames at 160×42 with animation,
72×18, and 32×18. At 32 columns the active tab number and icon still fit.
The strict UI typecheck, 35 JS tests, and 7 wrapper tests passed. A separate
39-check PTY run loaded the deployed managed source directly, without the
synthetic status wrapper, and passed editing, toggle, reload, and geometry
checks. Submission remained stubbed; no real model interruption or private
session was tested.

### Aligned status icons verified on 2026-11-13

The compact status segment passed 32 JS regression tests and the strict UI
typecheck. Isolated PTY runs at 160×42 (animated) and 72×18 (static) each passed
45 interaction checks, including all six synthetic statuses, reload/cleanup,
fixed icon/separator/tab columns, and unchanged Vim behavior. The animated run
observed all ten spinner glyphs in one cell; the static run observed only `⋯`.
No model requests or real private sessions were used.
