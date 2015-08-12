describe 'BottomPanel', ->
  linter = null
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance

  getLinter = ->
    return {grammarScopes: ['*'], lintOnFly: false, modifiesBuffer: false, scope: 'project', lint: -> }
  getMessage = (type, filePath) ->
    return {type, text: "Some Message", filePath}

  it 'remains visible when theres no active pane', ->
    expect(linter.views.panel.getVisibility()).toBe(true)

  it 'hides on config change', ->
    expect(linter.views.panel.getVisibility()).toBe(true)
    atom.config.set('linter.showErrorPanel', false)
    expect(linter.views.panel.getVisibility()).toBe(false)
    atom.config.set('linter.showErrorPanel', true)
    expect(linter.views.panel.getVisibility()).toBe(true)
