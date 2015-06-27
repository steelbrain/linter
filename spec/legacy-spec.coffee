
describe 'legacy.coffee', ->
  legacyAdapter = require('../lib/legacy.coffee')

  it 'Adapts plain string `syntax` property', ->
    classicLinter = {
      syntax: 'source.js'
    }

    adapted = legacyAdapter(classicLinter)

    expect(adapted.grammarScopes).toEqual(['source.js'])

  it 'Adapts array `syntax` property', ->
    classicLinter = {
      syntax: [ 'source.js' ]
    }

    adapted = legacyAdapter(classicLinter)

    expect(adapted.grammarScopes).toEqual(['source.js'])
