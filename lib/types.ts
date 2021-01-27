import { Range, Point, TextEditor, CompositeDisposable } from 'atom'

// https://github.com/steelbrain/linter-ui-default/blob/2f71befa78718018f444456706b1ea810531572d/lib/types.d.ts#L4-L57
export type MessageSolution =
  | {
      title?: string
      position: Range
      priority?: number
      currentText?: string
      replaceWith: string
    }
  | {
      title?: string
      priority?: number
      position: Range
      apply: () => any
    }

export type Message = {
  // Automatically added by linter
  key: string
  version: 2
  linterName: string

  // From providers
  location: {
    file: string
    position: Range
  }
  reference?: {
    file: string
    position?: Point
  }
  url?: string
  icon?: string
  excerpt: string
  severity: 'error' | 'warning' | 'info'
  solutions?: Array<MessageSolution>
  description?: string | (() => Promise<string> | string)
}

export type LinterResult = Array<Message> | null
export type Linter = {
  // Automatically added
  __$sb_linter_version: number
  __$sb_linter_activated: boolean
  __$sb_linter_request_latest: number
  __$sb_linter_request_last_received: number

  // From providers
  name: string
  scope: 'file' | 'project'
  lintOnFly?: boolean // <-- legacy
  lintsOnChange?: boolean
  grammarScopes: Array<string>
  lint(textEditor: TextEditor): LinterResult | Promise<LinterResult>
}

export type Indie = {
  name: string
}

export type MessagesPatch = {
  added: Array<Message>
  removed: Array<Message>
  messages: Array<Message>
}

export type UI = {
  name: string
  // panel?: Panel
  // signal: BusySignal
  // editors: Editors | null | undefined
  // treeview?: TreeView
  // commands: Commands
  // messages: Array<Message>
  // statusBar: StatusBar
  // intentions: Intentions
  subscriptions: CompositeDisposable
  idleCallbacks: Set<number>
  // constructor();
  didBeginLinting(linter: Linter, filePath: string | null | undefined): void
  didFinishLinting(linter: Linter, filePath: string | null | undefined): void
  render(patch: MessagesPatch): void
  dispose(): void
}

// Missing Atom API
declare module 'atom' {
  interface CompositeDisposable {
    disposed: boolean
  }
  interface Pane {
    getPendingItem(): TextEditor
  }
  interface Notification {
    getOptions(): { detail: string }
  }
}

// windows requestIdleCallback types
/* eslint-disable-next-line @typescript-eslint/no-explicit-any */
export type RequestIdleCallbackHandle = any
type RequestIdleCallbackOptions = {
  timeout: number
}
type RequestIdleCallbackDeadline = {
  readonly didTimeout: boolean
  timeRemaining: () => number
}

declare global {
  interface Window {
    requestIdleCallback: (
      callback: (deadline: RequestIdleCallbackDeadline) => void,
      opts?: RequestIdleCallbackOptions,
    ) => RequestIdleCallbackHandle
    cancelIdleCallback: (handle: RequestIdleCallbackHandle) => void
  }
}
