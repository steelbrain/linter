/* @flow */

import Path from 'path'
import { normalizeMessages, normalizeMessagesLegacy } from '../lib/helpers'

export function getLinter(): Object {
  return {
    name: 'Some Linter',
    scope: 'project',
    grammarScopes: ['source.js'],
    lint() {
      return []
    },
  }
}
export function getMessage(normalized: boolean = true): Object {
  const message: Object = { severity: 'error', excerpt: String(Math.random()), location: { file: __filename, position: [[0, 0], [0, 0]] } }
  if (normalized) {
    normalizeMessages('Some Linter', [message])
  }
  return message
}
export function getMessageLegacy(normalized: boolean = true): Object {
  const message: Object = { type: 'Error', filePath: '/tmp/passwd', range: [[0, 1], [1, 0]], text: String(Math.random()) }
  if (normalized) {
    normalizeMessagesLegacy('Some Linter', [message])
  }
  return message
}
export function getFixturesPath(path: string): string {
  return Path.join(__dirname, 'fixtures', path)
}
