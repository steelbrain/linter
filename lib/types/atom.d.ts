import { TextEditor } from 'atom'

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
