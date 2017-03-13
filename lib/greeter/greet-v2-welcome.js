/* @flow */

import coolTrim from 'cool-trim'

export default function greet() {
  return atom.notifications.addInfo('Welcome to Linter v2', {
    dismissable: true,
    description: coolTrim`
      Hi Linter user! 👋

      Linter has been upgraded to v2.

      Packages compatible with v1 will keep working on v2 for a long time.
      If you are a package author, I encourage you to upgrade your package to the Linter v2 API.

      You can read [the announcement post on my blog](http://steelbrain.me/2017/03/13/linter-v2-released.html).
    `,
  })
}
