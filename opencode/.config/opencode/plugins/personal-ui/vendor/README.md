# Vim integration

`vim.js` is the published `dist/tui.js` from
`@leohenon/opencode-vim-plugin@0.2.0-beta.3`, with a small local integration
change. Copyright and MIT permission notice are preserved in `LICENSE`.

- Upstream: https://github.com/leohenon/opencode-vim-plugin
- Tarball: https://registry.npmjs.org/@leohenon/opencode-vim-plugin/-/opencode-vim-plugin-0.2.0-beta.3.tgz
- Tarball SHA-512 (base64): `wfNJHLmNh8D7sO6Jw8e2j0VYwH6k1DA6VNJLPEa/vj859Loy35ITltzZGdRhQU3fsaVnioPHFPAbt9/Iu2gdwg==`
- Original `dist/tui.js` SHA-256: `7d54a14b9481442f5d5e9cf303529619ba19a5dba0e66df04f0c67cf23aa1fd6`

## Local delta

Only the final setup/export section is adapted:

1. Export `setupVim(context)` instead of an independently discovered plugin.
2. Mount the existing null-rendering `KeymapSetup` in `app`, not in
   `prompt.footer.status`. Keep the upstream global commands, priorities,
   toggle, prompt engine, cursor handling, and teardown.
3. Remove the native status text synchronization. Return the actual reactive
   `enabled` and `prompt.mode` accessors plus `dispose` to the personal UI.

The first 148263 bytes, including the complete prompt/Vim engine, are unchanged.
Their SHA-256 is `baec1b3a2473eec8cd12c2fe3c358c630b4354b0156ff0651f13b3658e48b3a4`;
a regression test guards that boundary. `vim.d.ts` describes the local API.
Unused upstream display helpers remain intact to keep the delta reviewable.

The personal UI owns initialization and cleanup. Vim options live in its
`options.vim`; the toggle now persists in the personal UI storage namespace.
The old standalone plugin's state is not deleted or migrated. On first use of
this integration, the configured `enabled` value supplies the initial state.
Do not enable the npm plugin alongside this integration: that would install
two copies of the keyboard/prompt hooks.

## Updating

Do not edit OpenCode's package cache or run a formatter over this vendored file.
For an upgrade, verify the published package, review the upstream changes,
reapply only the setup/export delta, and update provenance and the engine hash.
Run config/state tests, the strict UI typecheck, and isolated real-TUI checks
for editing, toggles, reload/cleanup, and fixed bar geometry before activation.
