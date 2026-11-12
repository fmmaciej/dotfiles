import { Plugin } from "@opencode/plugin/tui"
import { createHash } from "node:crypto"
import { useTerminalDimensions } from "@opentui/solid"
import { RGBA, type KeyEvent } from "@opentui/core"
import { createEffect, createMemo, createSignal, For, on, onCleanup, Show } from "solid-js"
import {
  cleanTitle, closeTab, contextBar, contextUsage, cycleTab,
  openTab, scannerFrame, sessionState, statusLayout, tabBindings, tabIcon, tabSpinnerFrames, tokenTotal, visibleTabs,
} from "./state.mjs"

type Context = Plugin.Context
const number = new Intl.NumberFormat("en-US")
const money = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 4 })

function activeSession(context: Context) {
  const route = context.ui.router.current()
  return route.type === "session" ? context.data.session.root(route.sessionID) : undefined
}

function activity(context: Context, sessionID?: string) {
  const ids = sessionID ? Array.from(new Set([sessionID, ...context.data.session.family(sessionID)])) : []
  return sessionState({
    running: ids.some((id) => context.data.session.status(id) === "running"),
    permissions: ids.reduce((sum, id) => sum + (context.data.session.permission.list(id)?.length ?? 0), 0),
    forms: ids.reduce((sum, id) => sum + (context.data.session.form.list(id)?.length ?? 0), 0),
    outcome: sessionID ? context.data.session.get(sessionID)?.outcome : undefined,
  })
}

function Shortcuts(props: { context: Context }) {
  const dimensions = useTerminalDimensions()
  const full = () => dimensions().height >= 26
  return (
    <box gap={0}>
      <text fg={props.context.theme.text.base}><b>Ctrl+B, then</b></text>
      <text fg={props.context.theme.text.muted}>c       New session</text>
      <text fg={props.context.theme.text.muted}>,       Rename session</text>
      <text fg={props.context.theme.text.muted}>x       Close tab</text>
      <text fg={props.context.theme.text.muted}>0–9     Select tab</text>
      <Show when={full()}>
        <text fg={props.context.theme.text.muted}>l       Session list</text>
        <text fg={props.context.theme.text.muted}>e       Edit prompt</text>
        <text fg={props.context.theme.text.muted}>b       Toggle sidebar</text>
      </Show>
      <text fg={props.context.theme.text.muted}>Ctrl+P  Commands</text>
    </box>
  )
}

function Sidebar(props: { context: Context; sessionID: string }) {
  const context = props.context
  const session = createMemo(() => context.data.session.get(props.sessionID))
  const location = () => session()?.location ?? context.location
  const models = () => context.data.location.model.list(location()) ?? []
  const selected = createMemo(() => context.ui.model.current())
  const model = createMemo(() => {
    const ref = selected()
    return models().find((item) => item.id === (ref?.modelID ?? session()?.model?.id)
      && item.providerID === (ref?.providerID ?? session()?.model?.providerID))
  })
  const usage = createMemo(() => contextUsage(
    context.data.session.message.list(props.sessionID), models(), session()?.revert?.messageID,
  ))
  const agent = createMemo(() => {
    const id = session()?.agent
    return context.data.location.agent.list(location())?.find((item) => item.id === id)?.name ?? id ?? "—"
  })
  const tokens = createMemo(() => tokenTotal(session()?.tokens))

  return (
    <box gap={1}>
      <box>
        <text fg={context.theme.text.muted}>Model</text>
        <text fg={context.theme.text.base} wrapMode="word">{cleanTitle(model()?.name ?? selected()?.modelID ?? session()?.model?.id, "—")}</text>
        <text fg={context.theme.text.muted}>Reasoning / variant</text>
        <text fg={context.theme.text.base}>{cleanTitle(selected()?.variant, "Default")}</text>
        <text fg={context.theme.text.muted}>Session agent</text>
        <text fg={context.theme.text.base}>{cleanTitle(agent(), "—")}</text>
      </box>
      <box>
        <text fg={context.theme.text.base}><b>Context · last sample</b></text>
        <Show when={usage()} fallback={<text fg={context.theme.text.muted}>No measurement yet</text>}>
          {(value) => (
            <>
              <text fg={context.theme.text.base}>
                {number.format(value().used)} / {value().limit ? number.format(value().limit) : "?"} tokens
              </text>
              <Show when={value().percent !== undefined}>
                <text fg={context.theme.text.muted}>{contextBar(value().percent)} ~{value().percent}%</text>
              </Show>
            </>
          )}
        </Show>
      </box>
      <box>
        <text fg={context.theme.text.muted}>Total usage</text>
        <text fg={context.theme.text.base}>{tokens() === undefined ? "—" : `${number.format(tokens()!)} tokens`}</text>
        <text fg={context.theme.text.muted}>OC-reported cost</text>
        <text fg={context.theme.text.base}>{money.format(context.data.session.cost(props.sessionID))}</text>
      </box>
    </box>
  )
}

export default Plugin.define({
  id: "kei.terminal-ui",
  setup(context) {
    const animations = context.options.animations !== false
    const directory = context.location?.directory ?? context.data.location.default().directory
    const scope = createHash("sha256").update(directory).digest("hex")
    const [state, updateState] = context.storage.store(`tabs-${scope}`, { initial: { tabs: [] as string[] } })
    const active = () => activeSession(context)
    const reportError = (error: unknown) => context.ui.toast.show({
      title: "Kei UI", message: error instanceof Error ? error.message : String(error), variant: "error",
    })
    const navigate = (sessionID?: string) => context.ui.router.navigate(
      sessionID ? { type: "session", sessionID } : { type: "home" },
    )
    const close = async () => {
      const id = active()
      if (!id) return navigate(state.tabs.at(-1))
      const result = closeTab(state.tabs, id)
      await updateState((draft) => { draft.tabs = result.tabs })
      navigate(result.next)
    }

    // Base mode only: these shortcuts must not steal input from dialogs or panels.
    context.keymap.layer(() => ({
      priority: 10,
      commands: [
        { id: "kei.tabs.close", title: "Kei: close tab", bind: "<leader>x", palette: true,
          run: () => close().catch(reportError) },
        { id: "kei.tabs.next", title: "Kei: next tab", bind: "alt+down",
          run: () => { const id = cycleTab(state.tabs, active(), 1); if (id) navigate(id) } },
        { id: "kei.tabs.previous", title: "Kei: previous tab", bind: "alt+up",
          run: () => { const id = cycleTab(state.tabs, active(), -1); if (id) navigate(id) } },
        ...tabBindings.map(({ index, ...command }) => ({
          ...command,
          run: () => { const id = state.tabs[index]; if (id) navigate(id) },
        })),
      ],
    }))

    // OC 2.2.7 splits every comma in string bindings, and the name "comma"
    // does not match a physical comma. Use the public renderer event API only
    // for this key, gated by OC's real pending leader and base input mode.
    const renameOnComma = (event: KeyEvent) => {
      if (event.name !== "," || event.ctrl || event.meta || event.shift || event.super || event.hyper) return
      if (context.keymap.mode.current() !== "base" || !active()) return
      if (!context.keymap.pending().some((key) => key.token === "leader")) return
      if (!context.keymap.commands().some((command) => command.id === "session.rename")) return
      event.preventDefault()
      event.stopPropagation()
      context.keymap.dispatch("session.rename")
    }
    context.renderer.keyInput.prependListener("keypress", renameOnComma)

    function BottomBar() {
      const dimensions = useTerminalDimensions()
      const [frame, setFrame] = createSignal(0)
      const [tabFrame, setTabFrame] = createSignal(0)
      const status = createMemo(() => activity(context, active()))
      const tabItems = createMemo(() => state.tabs.map((sessionID) => ({
        sessionID, title: context.data.session.get(sessionID)?.title, activity: activity(context, sessionID),
      })))
      const layout = createMemo(() => statusLayout(status(), dimensions().width))
      const tabs = createMemo(() => visibleTabs(tabItems(), active(), dimensions().width - layout().width - 3))
      const gap = createMemo(() => layout().gap)
      const animated = createMemo(() => status().kind === "running" && animations)
      const animateTabs = createMemo(() => animations
        && tabItems().some((tab) => tab.activity.kind === "running"))
      const dots = createMemo(() => scannerFrame(gap(), frame()))
      const colors = createMemo(() => {
        const color = context.theme.text.base
        return [0, 0.11, 0.17, 0.27, 0.42, 0.65, 0.85].map((alpha) =>
          RGBA.fromValues(color.r, color.g, color.b, color.a * alpha))
      })

      createEffect(on(active, (id) => {
        if (!id) return
        if (!state.tabs.includes(id)) void updateState((draft) => { draft.tabs = openTab(draft.tabs, id) }).catch(reportError)
        void Promise.allSettled([
          context.data.session.sync(id), context.data.session.message.sync(id),
          context.data.session.permission.sync(id), context.data.session.form.sync(id),
          context.data.location.model.sync(), context.data.location.agent.sync(),
        ])
      }))
      // Warm every saved/open tab, not just the active one. No messages or model calls are needed.
      createEffect(on(() => [...state.tabs], (ids) => {
        void Promise.allSettled(ids.map(async (id) => {
          await context.data.session.sync(id)
          const family = new Set([id, ...context.data.session.family(id)])
          await Promise.allSettled([...family].flatMap((sessionID) => [
            context.data.session.permission.sync(sessionID), context.data.session.form.sync(sessionID),
          ]))
        }))
      }))
      createEffect(() => {
        const width = gap()
        setFrame(0)
        if (!animated() || !width) return
        const cycle = width * 2 - 1 + 9 + 30
        const timer = setInterval(() => setFrame((value) => (value + 1) % cycle), 40)
        onCleanup(() => clearInterval(timer))
      })
      createEffect(() => {
        setTabFrame(0)
        if (!animateTabs()) return
        const timer = setInterval(() => setTabFrame((value) => (value + 1) % tabSpinnerFrames.length), 100)
        onCleanup(() => clearInterval(timer))
      })

      // Reuse OC's blank session bottom padding, preserving the prompt's bottom edge.
      return (
        <box
          height={1} flexShrink={0} flexDirection="row" width="100%"
          marginTop={context.ui.router.current().type === "session" ? -1 : 0}
          backgroundColor={context.theme.background.raised.base}
        >
          <box width={layout().width} flexShrink={0} flexDirection="row" overflow="hidden">
            <text fg={context.theme.text.base} wrapMode="none" flexShrink={0}> Kei: </text>
            <text fg={context.theme.text.base} wrapMode="none" flexShrink={0}>{`${layout().text} `}</text>
            <Show when={layout().icon}>
              <text fg={context.theme.text.base} wrapMode="none" flexShrink={0}>{layout().icon}</text>
            </Show>
            <box width={layout().gap} flexShrink={0} flexDirection="row">
              <Show when={animated()} fallback={<text>{" ".repeat(layout().gap)}</text>}>
                <For each={dots()}>{(level) => (
                  <text fg={colors()[level]} wrapMode="none" flexShrink={0}>{level ? "·" : " "}</text>
                )}</For>
              </Show>
            </box>
            <text fg={context.theme.text.base} wrapMode="none" flexShrink={0}>{layout().icon ? "│" : " │"}</text>
          </box>
          <box flexDirection="row" flexGrow={1} minWidth={0} overflow="hidden">
            <For each={tabs()}>{(tab) => (
              <box
                width={tab.width} minWidth={4} flexShrink={1} flexDirection="row"
                backgroundColor={tab.sessionID === active() ? context.theme.background.raised.high : undefined}
                onMouseUp={() => navigate(tab.sessionID)}
              >
                <text fg={tab.sessionID === active() ? context.theme.text.base : context.theme.text.muted}
                  wrapMode="none" truncate flexGrow={1} flexShrink={1} minWidth={0}> {tab.label}</text>
                <text fg={tab.sessionID === active() ? context.theme.text.base : context.theme.text.muted}
                  wrapMode="none" flexShrink={0}>
                  {` ${tabIcon(tab.activity, tabFrame(), animations)} │`}
                </text>
              </box>
            )}</For>
            <Show when={!active()}><text fg={context.theme.text.muted} wrapMode="none" truncate> New session</text></Show>
          </box>
        </box>
      )
    }

    const stopDeleted = context.data.on("session.deleted", (event) => {
      void updateState((draft) => { draft.tabs = draft.tabs.filter((id) => id !== event.data.sessionID) }).catch(reportError)
    })
    const claims = [
      context.ui.slot({ append: "app", render: () => <BottomBar /> }),
      context.ui.slot({ replace: "prompt.footer", render: () => null }),
      context.ui.slot({ replace: "home.footer", render: () => null }),
      context.ui.slot({ replace: "sidebar.content", render: (props) => <Sidebar context={context} sessionID={props.sessionID} /> }),
      context.ui.slot({ replace: "sidebar.footer", render: () => <Shortcuts context={context} /> }),
    ]
    return () => {
      context.renderer.keyInput.removeListener("keypress", renameOnComma)
      stopDeleted()
      claims.forEach((remove) => remove())
    }
  },
})
