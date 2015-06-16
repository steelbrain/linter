"use strict"
// H = Helpers
let Helpers = {
  // Iterate over generator helper
  genValue: function(Gen, Callback) {
    for(var Value of Gen){
      Callback(Value[1] || Value) // 1 for Maps and whole for Sets
    }
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