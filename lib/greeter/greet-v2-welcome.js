/* @flow */

import coolTrim from 'cool-trim'

export default function greet() {
  return atom.notifications.addInfo('Welcome to Linter v2', {
    dismissable: true,
    description: coolTrim`
      Hi Linter user! 👋

      Linter has been upgraded to v2.
      TL;DR is that UI has been split into a separate package and the base package has been rewritten to maximize stability.

      You can read [the announcement on my blog]().
    `,
  })
}
