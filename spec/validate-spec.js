/* @flow */

import * as Validate from '../lib/validate'

describe('Validate', function() {
  function expectNotification(message: string) {
    const notifications = atom.notifications.getNotifications()
    expect(notifications.length).toBe(1)
    const issues = notifications[0].options.detail.split('\n')
    issues.shift()
    expect(issues[0]).toBe(`  • ${message}`)
    atom.notifications.clear()
  }

  describe('::ui', function() {
    function validateUI(ui: any, expectedValue: boolean, message: string = '') {
      expect(Validate.ui(ui)).toBe(expectedValue)
      if (!expectedValue) {
        expectNotification(message)
      }
    }

    it('cries if param is not an object', function() {
      validateUI(undefined, false, 'UI must be an object')
      validateUI(null, false, 'UI must be an object')
      validateUI(2, false, 'UI must be an object')
      validateUI(NaN, false, 'UI must be an object')
    })
    it('cries if ui.name is not a string', function() {
      validateUI({
        name: NaN,
      }, false, 'UI.name must be a string')
      validateUI({
        name: null,
      }, false, 'UI.name must be a string')
      validateUI({
        name: 2,
      }, false, 'UI.name must be a string')
    })
    it('cries if ui.didBeginLinting is not a function', function() {
      validateUI({
        name: 'Some',
        didBeginLinting: null,
      }, false, 'UI.didBeginLinting must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting: {},
      }, false, 'UI.didBeginLinting must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting: NaN,
      }, false, 'UI.didBeginLinting must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting: 5,
      }, false, 'UI.didBeginLinting must be a function')
    })
    it('cries if ui.didFinishLinting is not a function', function() {
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting: null,
      }, false, 'UI.didFinishLinting must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting: {},
      }, false, 'UI.didFinishLinting must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting: NaN,
      }, false, 'UI.didFinishLinting must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting: 5,
      }, false, 'UI.didFinishLinting must be a function')
    })
    it('cries if ui.render is not a function', function() {
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting() { },
        render: null,
      }, false, 'UI.render must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting() { },
        render: {},
      }, false, 'UI.render must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting() { },
        render: NaN,
      }, false, 'UI.render must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting() { },
        render: 5,
      }, false, 'UI.render must be a function')
    })
    it('cries if ui.dispose is not a function', function() {
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting() { },
        render() {},
        dispose: null,
      }, false, 'UI.dispose must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting() { },
        render() {},
        dispose: {},
      }, false, 'UI.dispose must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting() { },
        render() {},
        dispose: NaN,
      }, false, 'UI.dispose must be a function')
      validateUI({
        name: 'Some',
        didBeginLinting() { },
        didFinishLinting() { },
        render() {},
        dispose: 5,
      }, false, 'UI.dispose must be a function')
    })
    it('does not cry if everything is good', function() {
      validateUI({
        name: 'Some',
        didBeginLinting() {},
        didFinishLinting() {},
        render() {},
        dispose() {},
      }, true)
    })
  })
  describe('::linter', function() {
    function validateLinter(linter: any, expectedValue: boolean, message: string = '', version: 1 | 2) {
      expect(Validate.linter(linter, version)).toBe(expectedValue)
      if (!expectedValue) {
        expectNotification(message)
      }
    }

    it('cries if params is not an object', function() {
      validateLinter(null, false, 'Linter must be an object', 1)
      validateLinter(5, false, 'Linter must be an object', 1)
      validateLinter(NaN, false, 'Linter must be an object', 1)
      validateLinter(undefined, false, 'Linter must be an object', 1)
    })
    it('does not cry if linter.name is not a string on v1', function() {
      validateLinter({
        lint() {},
        scope: 'file',
        lintOnFly: true,
        grammarScopes: [],
      }, true, '', 1)
    })
    it('cries if linter.name is not a string', function() {
      validateLinter({
        name: undefined,
      }, false, 'Linter.name must be a string', 2)
      validateLinter({
        name: NaN,
      }, false, 'Linter.name must be a string', 2)
      validateLinter({
        name: null,
      }, false, 'Linter.name must be a string', 2)
      validateLinter({
        name: 5,
      }, false, 'Linter.name must be a string', 2)
    })
    it('cries if linter.scope is not valid', function() {
      validateLinter({
        name: 'Linter',
        scope: 5,
      }, false, "Linter.scope must be either 'file' or 'project'", 1)
      validateLinter({
        name: 'Linter',
        scope: NaN,
      }, false, "Linter.scope must be either 'file' or 'project'", 1)
      validateLinter({
        name: 'Linter',
        scope: null,
      }, false, "Linter.scope must be either 'file' or 'project'", 1)
      validateLinter({
        name: 'Linter',
        scope: undefined,
      }, false, "Linter.scope must be either 'file' or 'project'", 1)
      validateLinter({
        name: 'Linter',
        scope: 'something',
      }, false, "Linter.scope must be either 'file' or 'project'", 1)
      validateLinter({
        name: 'Linter',
        scope: 'fileistic',
      }, false, "Linter.scope must be either 'file' or 'project'", 1)
    })
    it('cries if v is 1 and linter.lintOnFly is not boolean', function() {
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: {},
      }, false, 'Linter.lintOnFly must be a boolean', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: [],
      }, false, 'Linter.lintOnFly must be a boolean', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: '',
      }, false, 'Linter.lintOnFly must be a boolean', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly() {},
      }, false, 'Linter.lintOnFly must be a boolean', 1)
    })
    it('cries if v is 2 and linter.lintsOnChange is not boolean', function() {
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintsOnChange: {},
      }, false, 'Linter.lintsOnChange must be a boolean', 2)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintsOnChange: [],
      }, false, 'Linter.lintsOnChange must be a boolean', 2)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintsOnChange: '',
      }, false, 'Linter.lintsOnChange must be a boolean', 2)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintsOnChange() {},
      }, false, 'Linter.lintsOnChange must be a boolean', 2)
    })
    it('cries if linter.grammarScopes is not an array', function() {
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: undefined,
      }, false, 'Linter.grammarScopes must be an Array', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: null,
      }, false, 'Linter.grammarScopes must be an Array', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: 5,
      }, false, 'Linter.grammarScopes must be an Array', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: NaN,
      }, false, 'Linter.grammarScopes must be an Array', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: {},
      }, false, 'Linter.grammarScopes must be an Array', 1)
    })
    it('cries if linter.lint is not a function', function() {
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: ['source.js'],
        lint: undefined,
      }, false, 'Linter.lint must be a function', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: ['source.js'],
        lint: 5,
      }, false, 'Linter.lint must be a function', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: ['source.js'],
        lint: NaN,
      }, false, 'Linter.lint must be a function', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: ['source.js'],
        lint: {},
      }, false, 'Linter.lint must be a function', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: ['source.js'],
        lint: 'something',
      }, false, 'Linter.lint must be a function', 1)
    })
    it('does not cry if everything is valid', function() {
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintOnFly: false,
        grammarScopes: ['source.js'],
        lint() { },
      }, true, '', 1)
      validateLinter({
        name: 'Linter',
        scope: 'file',
        lintsOnChange: false,
        grammarScopes: ['source.js'],
        lint() { },
      }, true, '', 2)
    })
  })
  describe('::indie', function() {
    function validateIndie(linter: any, expectedValue: boolean, message: string = '') {
      expect(Validate.indie(linter)).toBe(expectedValue)
      if (!expectedValue) {
        expectNotification(message)
      }
    }

    it('cries if params is not an object', function() {
      validateIndie(null, false, 'Indie must be an object')
      validateIndie(5, false, 'Indie must be an object')
      validateIndie(NaN, false, 'Indie must be an object')
      validateIndie(undefined, false, 'Indie must be an object')
    })
    it('cries if indie.name is not a string', function() {
      validateIndie({
        name: undefined,
      }, false, 'Indie.name must be a string')
      validateIndie({
        name: 5,
      }, false, 'Indie.name must be a string')
      validateIndie({
        name: {},
      }, false, 'Indie.name must be a string')
      validateIndie({
        name: NaN,
      }, false, 'Indie.name must be a string')
    })
    it('does not cry if everything is valid', function() {
      validateIndie({
        name: 'Indie',
      }, true)
    })
  })
  describe('::messages', function() {
    function validateMessages(linter: any, expectedValue: boolean, message: string = '') {
      expect(Validate.messages('Some Linter', linter)).toBe(expectedValue)
      if (!expectedValue) {
        expectNotification(message)
      }
    }

    it('cries if results are not array', function() {
      validateMessages(undefined, false, 'Linter Result must be an Array')
      validateMessages({}, false, 'Linter Result must be an Array')
      validateMessages(5, false, 'Linter Result must be an Array')
      validateMessages(NaN, false, 'Linter Result must be an Array')
    })
    it('cries if message.icon is present and invalid', function() {
      validateMessages([{
        icon: 5,
      }], false, 'Message.icon must be a string')
      validateMessages([{
        icon: {},
      }], false, 'Message.icon must be a string')
      validateMessages([{
        icon() {},
      }], false, 'Message.icon must be a string')
    })
    it('cries if message.location is invalid', function() {
      validateMessages([{
        location: 5,
      }], false, 'Message.location must be valid')
      validateMessages([{
        location: NaN,
      }], false, 'Message.location must be valid')
      validateMessages([{
        location: {},
      }], false, 'Message.location must be valid')
      validateMessages([{
        location: { file: __filename },
      }], false, 'Message.location must be valid')
      validateMessages([{
        location: { file: __filename, position: 5 },
      }], false, 'Message.location must be valid')
      validateMessages([{
        location: { file: __filename, position: null },
      }], false, 'Message.location must be valid')
      validateMessages([{
        location: { file: __filename, position: '' },
      }], false, 'Message.location must be valid')
      validateMessages([{
        location: { file: __filename, position: NaN },
      }], false, 'Message.location must be valid')
    })
    it('cries if message.location contains NaN', function() {
      validateMessages([{
        location: { file: __filename, position: [[NaN, NaN], [NaN, NaN]] },
      }], false, 'Message.location.position should not contain NaN coordinates')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, NaN]] },
      }], false, 'Message.location.position should not contain NaN coordinates')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [NaN, 0]] },
      }], false, 'Message.location.position should not contain NaN coordinates')
      validateMessages([{
        location: { file: __filename, position: [[0, NaN], [0, 0]] },
      }], false, 'Message.location.position should not contain NaN coordinates')
      validateMessages([{
        location: { file: __filename, position: [[NaN, 0], [0, 0]] },
      }], false, 'Message.location.position should not contain NaN coordinates')
    })
    it('cries if message.solutions is present and is not array', function() {
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        solutions: {},
      }], false, 'Message.solutions must be valid')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        solutions: 'asdsad',
      }], false, 'Message.solutions must be valid')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        solutions: 5,
      }], false, 'Message.solutions must be valid')
    })
    it('cries if message.reference is present and invalid', function() {
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: 5,
      }], false, 'Message.reference must be valid')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: {},
      }], false, 'Message.reference must be valid')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: 'asdasd',
      }], false, 'Message.reference must be valid')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: { file: __filename },
      }], false, 'Message.reference must be valid')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: { file: __filename, position: 5 },
      }], false, 'Message.reference must be valid')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: { file: __filename, position: NaN },
      }], false, 'Message.reference must be valid')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: { file: __filename, position: null },
      }], false, 'Message.reference must be valid')
    })
    it('cries if message.reference contains NaN', function() {
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: { file: __filename, position: [NaN, 5] },
      }], false, 'Message.reference.position should not contain NaN coordinates')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: { file: __filename, position: [5, NaN] },
      }], false, 'Message.reference.position should not contain NaN coordinates')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: { file: __filename, position: [NaN, NaN] },
      }], false, 'Message.reference.position should not contain NaN coordinates')
    })
    it('cries if message.excerpt is not string', function() {
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: undefined,
      }], false, 'Message.excerpt must be a string')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: {},
      }], false, 'Message.excerpt must be a string')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: null,
      }], false, 'Message.excerpt must be a string')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: NaN,
      }], false, 'Message.excerpt must be a string')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: 5,
      }], false, 'Message.excerpt must be a string')
    })
    it('cries if message.severity is invalid', function() {
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: '',
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: NaN,
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 5,
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: {},
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 'errorish',
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 'warningish',
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
    })
    it('cries if message.url is present and is not string', function() {
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 'error',
        url: 5,
      }], false, 'Message.url must be a string')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 'error',
        url: {},
      }], false, 'Message.url must be a string')
    })
    it('cries if message.description is present and is invalid', function() {
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 'error',
        description: 5,
      }], false, 'Message.description must be a function or string')
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 'error',
        description: {},
      }], false, 'Message.description must be a function or string')
    })
    it('does not cry if provided with valid values', function() {
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 'error',
      }], true)
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 'error',
        solutions: [],
      }], true)
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        reference: { file: __filename, position: [0, 0] },
        excerpt: '',
        severity: 'warning',
      }], true)
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        url: 'something',
        severity: 'info',
      }], true)
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        description: 'something',
        severity: 'warning',
      }], true)
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        description() { },
        severity: 'warning',
      }], true)
    })
    it('cries if message.linterName is present and is invalid', function() {
      validateMessages([{
        location: { file: __filename, position: [[0, 0], [0, 0]] },
        excerpt: '',
        severity: 'error',
        description: '',
        linterName: 1,
      }], false, 'Message.linterName must be a string')
    })
  })
  describe('::messagesLegacy', function() {
    function validateMessagesLegacy(linter: any, expectedValue: boolean, message: string = '') {
      expect(Validate.messagesLegacy('Some Linter', linter)).toBe(expectedValue)
      if (!expectedValue) {
        expectNotification(message)
      }
    }

    it('cries if results are not array', function() {
      validateMessagesLegacy(undefined, false, 'Linter Result must be an Array')
      validateMessagesLegacy({}, false, 'Linter Result must be an Array')
      validateMessagesLegacy(5, false, 'Linter Result must be an Array')
      validateMessagesLegacy(NaN, false, 'Linter Result must be an Array')
    })
    it('cries if message.type is invalid', function() {
      validateMessagesLegacy([{
        type: undefined,
      }], false, 'Message.type must be a string')
      validateMessagesLegacy([{
        type: NaN,
      }], false, 'Message.type must be a string')
      validateMessagesLegacy([{
        type: 5,
      }], false, 'Message.type must be a string')
      validateMessagesLegacy([{
        type: null,
      }], false, 'Message.type must be a string')
    })
    it('cries if message.text and message.html are invalid', function() {
      validateMessagesLegacy([{
        type: 'Error',
      }], false, 'Message.text or Message.html must have a valid value')
      validateMessagesLegacy([{
        type: 'Error',
        html: {},
      }], false, 'Message.text or Message.html must have a valid value')
      validateMessagesLegacy([{
        type: 'Error',
        html: 5,
      }], false, 'Message.text or Message.html must have a valid value')
      validateMessagesLegacy([{
        type: 'Error',
        html: NaN,
      }], false, 'Message.text or Message.html must have a valid value')
      validateMessagesLegacy([{
        type: 'Error',
        text: 5,
      }], false, 'Message.text or Message.html must have a valid value')
      validateMessagesLegacy([{
        type: 'Error',
        text: {},
      }], false, 'Message.text or Message.html must have a valid value')
      validateMessagesLegacy([{
        type: 'Error',
        text: NaN,
      }], false, 'Message.text or Message.html must have a valid value')
    })
    it('cries if message.filePath is present and invalid', function() {
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        filePath: 5,
      }], false, 'Message.filePath must be a string')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        filePath: {},
      }], false, 'Message.filePath must be a string')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        filePath() { },
      }], false, 'Message.filePath must be a string')
    })
    it('cries if message.range is present and invalid', function() {
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        range: 'some',
      }], false, 'Message.range must be an object')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        range: 5,
      }], false, 'Message.range must be an object')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        range() {},
      }], false, 'Message.range must be an object')
    })
    it('cries if message.range has NaN values', function() {
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        range: [[NaN, NaN], [NaN, NaN]],
      }], false, 'Message.range should not contain NaN coordinates')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        range: [[NaN, 0], [0, 0]],
      }], false, 'Message.range should not contain NaN coordinates')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        range: [[0, NaN], [0, 0]],
      }], false, 'Message.range should not contain NaN coordinates')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        range: [[0, 0], [NaN, 0]],
      }], false, 'Message.range should not contain NaN coordinates')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        range: [[0, 0], [0, NaN]],
      }], false, 'Message.range should not contain NaN coordinates')
    })
    it('cries if message.class is present and invalid', function() {
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        class: 5,
      }], false, 'Message.class must be a string')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        class: {},
      }], false, 'Message.class must be a string')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        class() {},
      }], false, 'Message.class must be a string')
    })
    it('cries if message.severity is present and invalid', function() {
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        severity: {},
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        severity: [],
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        severity() {},
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        severity: 'error-ish',
      }], false, "Message.severity must be 'error', 'warning' or 'info'")
    })
    it('cries if message.trace is present and invalid', function() {
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        trace: {},
      }], false, 'Message.trace must be an Array')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        trace() {},
      }], false, 'Message.trace must be an Array')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        trace: 5,
      }], false, 'Message.trace must be an Array')
    })
    it('cries if message.fix is present and invalid', function() {
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: {},
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: 5,
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix() {},
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: { range: 5, newText: 'some', oldText: 'some' },
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: { range: NaN, newText: 'some', oldText: 'some' },
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: { range: undefined, newText: 'some', oldText: 'some' },
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: { range: [[0, 0], [0, 0]], newText: 5, oldText: 'some' },
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: { range: [[0, 0], [0, 0]], newText: {}, oldText: 'some' },
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: { range: [[0, 0], [0, 0]], newText() { }, oldText: 'some' },
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: { range: [[0, 0], [0, 0]], newText: 'some', oldText: 5 },
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: { range: [[0, 0], [0, 0]], newText: 'some', oldText: {} },
      }], false, 'Message.fix must be valid')
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        fix: { range: [[0, 0], [0, 0]], newText: 'some', oldText() {} },
      }], false, 'Message.fix must be valid')
    })
    it('does not cry if the object is valid', function() {
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        filePath: 'some',
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        html: 'Some',
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        html: document.createElement('div'),
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        range: [[0, 0], [0, 0]],
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        class: 'some',
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        severity: 'error',
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        severity: 'info',
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        severity: 'warning',
      }], true)
      validateMessagesLegacy([{
        type: 'Error',
        text: 'some',
        trace: [],
      }], true)
    })
  })
})
