# H = Helpers
Helpers = {
  # Iterate over generator helper
  genValue: (Gen, Callback)->
    value = Gen.next()
    while not value.done
      Callback(value.value)
      value = Gen.next()
  genValues: (Gen)->
    ToReturn = []
    Helpers.genValue(Gen, (Value)->
      ToReturn.push Value
    )
    ToReturn
}
module.exports = Helpers