"use strict"
// H = Helpers
let Helpers = {
  // Iterate over generator helper
  genValue: function(Gen, Callback) {
    for(var Value of Gen){
      Callback(Value)
    }
  },
  genValues: function(Gen) {
    let ToReturn = []
    Helpers.genValue(Gen, function(Value){
      ToReturn.push(Value) // Both the key and value
    })
    return ToReturn
  }
}
module.exports = Helpers