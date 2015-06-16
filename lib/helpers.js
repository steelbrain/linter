"use strict"
// H = Helpers
let Helpers = {
  // Iterate over generator helper
  genValue: function(Gen, Callback) {
    Gen.forEach(Callback)
  },
  genValues: function(Gen) {
    let ToReturn = []
    Helpers.genValue(Gen, function(Value){
      ToReturn.push(Value) // Only value
    })
    return ToReturn
  }
}
module.exports = Helpers