/* @flow */

import Path from 'path'
import { normalizeMessages } from '../dist/helpers'

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
export function getMessage(filePathOrNormalized: ?(boolean | string) = undefined): Object {
  const message: Object = {
    severity: 'error',
    excerpt: String(Math.random()),
    location: { file: __filename, position: [[0, 0], [0, 0]] },
  }
  if ((typeof filePathOrNormalized === 'boolean' && filePathOrNormalized) || filePathOrNormalized === undefined) {
    normalizeMessages('Some Linter', [message])
  } else if (typeof filePathOrNormalized === 'string') {
    message.location.file = filePathOrNormalized
  }
  return message
}
export function getFixturesPath(path: string): string {
  return Path.join(__dirname, 'fixtures', path)
}
