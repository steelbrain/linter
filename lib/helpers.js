"use strict"
// H = Helpers
let Helpers = {
  genValues: function(Gen) {
    let ToReturn = []
    Gen.forEach(function(Value){
      ToReturn.push(Value) // Only value
    })
    return ToReturn
  }
}
module.exports = Helpers