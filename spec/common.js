/* @flow */

import Path from 'path'
import { normalizeMessages, normalizeMessagesLegacy } from '../lib/helpers'

export function getLinter(): Object {
  return {
    name: 'Some Linter',
    scope: 'project',
    lintsOnChange: false,
    grammarScopes: ['source.js'],
    lint() {
      return new Promise(function(resolve) {
        setTimeout(function() {
          resolve([])
        }, 50)
      })
    },
  }
}
export function getMessage(param: ?(boolean | string)): Object {
  const message: Object = { severity: 'error', excerpt: String(Math.random()), location: { file: __filename, position: [[0, 0], [0, 0]] } }
  if (typeof param === 'boolean' && param) {
    normalizeMessages('Some Linter', [message])
  } else if (typeof param === 'string') {
    message.location.file = param
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
