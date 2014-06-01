StatusBarView = require '../lib/statusbar-view.coffee'
sinon = require 'sinon'
chai = require 'chai'

chai.should()

{Range, Point} = require 'atom'

describe 'StatusBarView', ->
  [statusBarView] = []

  beforeEach ->
    statusBarView = new StatusBarView()

  afterEach ->
    statusBarView.remove()
    statusBarView = null

  it "should not be visible", ->
    statusBarView.is(':visible').should.be.false

  it "should append violation into status bar", ->
    spy = sinon.spy(statusBarView, 'show')

    messages = [{
      linter: 'foo'
      message: 'bar'
      line: 0
      col: 1
      range: new Range([0, 1], [0, 3])
    }]

    position =
      row: 0
      column: 1

    # Faking we are on an error line
    statusBarView.computeMessages messages, position, 1, false

    # `@show` should have been called, so the view is visible
    spy.should.have.been.calledOnce

    # html should have correctly added into the status bar
    statusBarView.find('.error-message').text().should.be.eql(messages[0].message)
    statusBarView.find('dt > span').text().should.be.eql(messages[0].linter)
