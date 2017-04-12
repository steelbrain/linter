/* @flow */

if (atom.inDevMode()) {
  module.exports = require('./lib')
} else {
  module.exports = require('./lib.bundle.js')
}
