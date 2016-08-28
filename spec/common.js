/* @flow */

import { normalizeMessagesLegacy } from '../lib/helpers'

export function getMessageLegacy(): Object {
  const message: Object = { type: 'Error', filePath: '/tmp/passwd', range: [[0, 1], [1, 0]], text: String(Math.random()), version: 1 }
  normalizeMessagesLegacy('Some Linter', [message])
  return message
}
