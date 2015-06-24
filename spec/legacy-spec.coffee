
describe 'legacy.coffee', ->
  legacyAdapter = require('../lib/legacy.coffee')

  it 'Adapts plain string `syntax` property', ->
    clasicLinter = {
      syntax: 'source.js'
    }

    adapted = legacyAdapter(clasicLinter)

    expect(adapted.grammarScopes).toEqual(['source.js'])

  it 'Adapts array `syntax` property', ->
    clasicLinter = {
      syntax: [ 'source.js' ]
    }

    adapted = legacyAdapter(clasicLinter)

    expect(adapted.grammarScopes).toEqual(['source.js'])
