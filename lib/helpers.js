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
      ToReturn.push(Value[1]) // Only value
    })
    return ToReturn
  }
}
module.exports = Helpers