/* @flow */

const profileAtomLinter = false

if (atom.inDevMode()) {
  module.exports = require('./lib')
} else if (profileAtomLinter) {
  console.profile('linter load')
  const mainModule = require('./lib.bundle.js')
  console.profileEnd('linter load')
  module.exports = Object.assign({}, mainModule, {
    activate() {
      console.profile('linter activate')
      mainModule.activate.call(this)
      console.profileEnd('linter activate')
    },
  })
} else {
  module.exports = require('./lib.bundle.js')
}
