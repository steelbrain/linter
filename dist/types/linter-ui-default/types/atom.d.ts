import { TextEditor, Package } from 'atom'

// TODO: uses internal API
export type TextEditorExtra = TextEditor & {
  getURI?: () => string
  isAlive?: () => boolean
}

// TODO: uses internal API
interface PackageDepsList {
  [key: string]: string[]
}

export type PackageExtra = Package & {
  metadata: PackageDepsList
}
