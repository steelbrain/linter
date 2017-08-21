/* @flow */

export function lazyRequire(filePath: string, propName: string) {
  let TargetModule = null
  return function(target: Object, name: string, descriptor: Object) {
    const callback = descriptor.value
    descriptor.value = function() {
      if (this[propName]) return
      if (TargetModule === null) {
        // $FlowIgnore: Have to pass a string instead of literal
        TargetModule = require(filePath) // eslint-disable-line import/no-dynamic-require
      }
      this[propName] = new TargetModule(this.state)
      this.subscriptions.add(this[propName])
      callback.call(this)
    }
  }
}
