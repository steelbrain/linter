'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var FS = _interopDefault(require('sb-fs'));
var Path = _interopDefault(require('path'));
var atom$1 = require('atom');
var arrayUnique = _interopDefault(require('lodash.uniq'));
var SelectListView = _interopDefault(require('atom-select-list'));
var debounce = _interopDefault(require('sb-debounce'));

var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) {
  return typeof obj;
} : function (obj) {
  return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
};









var asyncToGenerator = function (fn) {
  return function () {
    var gen = fn.apply(this, arguments);
    return new Promise(function (resolve, reject) {
      function step(key, arg) {
        try {
          var info = gen[key](arg);
          var value = info.value;
        } catch (error) {
          reject(error);
          return;
        }

        if (info.done) {
          resolve(value);
        } else {
          return Promise.resolve(value).then(function (value) {
            step("next", value);
          }, function (err) {
            step("throw", err);
          });
        }
      }

      return step("next");
    });
  };
};

var classCallCheck = function (instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
};

var createClass = function () {
  function defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor) descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  return function (Constructor, protoProps, staticProps) {
    if (protoProps) defineProperties(Constructor.prototype, protoProps);
    if (staticProps) defineProperties(Constructor, staticProps);
    return Constructor;
  };
}();































var taggedTemplateLiteral = function (strings, raw) {
  return Object.freeze(Object.defineProperties(strings, {
    raw: {
      value: Object.freeze(raw)
    }
  }));
};

var Commands = function () {
  function Commands() {
    var _this = this;

    classCallCheck(this, Commands);

    this.emitter = new atom$1.Emitter();
    this.subscriptions = new atom$1.CompositeDisposable();

    this.subscriptions.add(this.emitter);
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'linter:enable-linter': function linterEnableLinter() {
        return _this.enableLinter();
      },
      'linter:disable-linter': function linterDisableLinter() {
        return _this.disableLinter();
      }
    }));
    this.subscriptions.add(atom.commands.add('atom-text-editor:not([mini])', {
      'linter:lint': function linterLint() {
        return _this.lint();
      },
      'linter:debug': function linterDebug() {
        return _this.debug();
      },
      'linter:toggle-active-editor': function linterToggleActiveEditor() {
        return _this.toggleActiveEditor();
      }
    }));
  }

  createClass(Commands, [{
    key: 'lint',
    value: function lint() {
      this.emitter.emit('should-lint');
    }
  }, {
    key: 'debug',
    value: function debug() {
      this.emitter.emit('should-debug');
    }
  }, {
    key: 'enableLinter',
    value: function enableLinter() {
      this.emitter.emit('should-toggle-linter', 'enable');
    }
  }, {
    key: 'disableLinter',
    value: function disableLinter() {
      this.emitter.emit('should-toggle-linter', 'disable');
    }
  }, {
    key: 'toggleActiveEditor',
    value: function toggleActiveEditor() {
      this.emitter.emit('should-toggle-active-editor');
    }
  }, {
    key: 'onShouldLint',
    value: function onShouldLint(callback) {
      return this.emitter.on('should-lint', callback);
    }
  }, {
    key: 'onShouldDebug',
    value: function onShouldDebug(callback) {
      return this.emitter.on('should-debug', callback);
    }
  }, {
    key: 'onShouldToggleActiveEditor',
    value: function onShouldToggleActiveEditor(callback) {
      return this.emitter.on('should-toggle-active-editor', callback);
    }
  }, {
    key: 'onShouldToggleLinter',
    value: function onShouldToggleLinter(callback) {
      return this.emitter.on('should-toggle-linter', callback);
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      this.subscriptions.dispose();
    }
  }]);
  return Commands;
}();

var VALID_SEVERITY = new Set(['error', 'warning', 'info']);

function showError(title, description, points) {
  var renderedPoints = points.map(function (item) {
    return '  \u2022 ' + item;
  });
  atom.notifications.addWarning('[Linter] ' + title, {
    dismissable: true,
    detail: description + '\n' + renderedPoints.join('\n')
  });
}

function validateUI(ui) {
  var messages = [];

  if (ui && (typeof ui === 'undefined' ? 'undefined' : _typeof(ui)) === 'object') {
    if (typeof ui.name !== 'string') {
      messages.push('UI.name must be a string');
    }
    if (typeof ui.didBeginLinting !== 'function') {
      messages.push('UI.didBeginLinting must be a function');
    }
    if (typeof ui.didFinishLinting !== 'function') {
      messages.push('UI.didFinishLinting must be a function');
    }
    if (typeof ui.render !== 'function') {
      messages.push('UI.render must be a function');
    }
    if (typeof ui.dispose !== 'function') {
      messages.push('UI.dispose must be a function');
    }
  } else {
    messages.push('UI must be an object');
  }

  if (messages.length) {
    showError('Invalid UI received', 'These issues were encountered while registering the UI named \'' + (ui && ui.name ? ui.name : 'Unknown') + '\'', messages);
    return false;
  }

  return true;
}

function validateLinter(linter, version) {
  var messages = [];

  if (linter && (typeof linter === 'undefined' ? 'undefined' : _typeof(linter)) === 'object') {
    if (typeof linter.name !== 'string') {
      if (version === 2) {
        messages.push('Linter.name must be a string');
      } else linter.name = 'Unknown';
    }
    if (typeof linter.scope !== 'string' || linter.scope !== 'file' && linter.scope !== 'project') {
      messages.push("Linter.scope must be either 'file' or 'project'");
    }
    if (version === 1 && typeof linter.lintOnFly !== 'boolean') {
      messages.push('Linter.lintOnFly must be a boolean');
    } else if (version === 2 && typeof linter.lintsOnChange !== 'boolean') {
      messages.push('Linter.lintsOnChange must be a boolean');
    }
    if (!Array.isArray(linter.grammarScopes)) {
      messages.push('Linter.grammarScopes must be an Array');
    }
    if (typeof linter.lint !== 'function') {
      messages.push('Linter.lint must be a function');
    }
  } else {
    messages.push('Linter must be an object');
  }

  if (messages.length) {
    showError('Invalid Linter received', 'These issues were encountered while registering a Linter named \'' + (linter && linter.name ? linter.name : 'Unknown') + '\'', messages);
    return false;
  }

  return true;
}

function validateIndie(indie) {
  var messages = [];

  if (indie && (typeof indie === 'undefined' ? 'undefined' : _typeof(indie)) === 'object') {
    if (typeof indie.name !== 'string') {
      messages.push('Indie.name must be a string');
    }
  } else {
    messages.push('Indie must be an object');
  }

  if (messages.length) {
    showError('Invalid Indie received', 'These issues were encountered while registering an Indie Linter named \'' + (indie && indie.name ? indie.name : 'Unknown') + '\'', messages);
    return false;
  }

  return true;
}

function validateMessages(linterName, entries) {
  var messages = [];

  if (Array.isArray(entries)) {
    var invalidURL = false;
    var invalidIcon = false;
    var invalidExcerpt = false;
    var invalidLocation = false;
    var invalidSeverity = false;
    var invalidSolution = false;
    var invalidReference = false;
    var invalidDescription = false;

    for (var i = 0, length = entries.length; i < length; ++i) {
      var message = entries[i];
      var reference = message.reference;
      if (!invalidIcon && message.icon && typeof message.icon !== 'string') {
        invalidIcon = true;
        messages.push('Message.icon must be a string');
      }
      if (!invalidLocation && (!message.location || _typeof(message.location) !== 'object' || typeof message.location.file !== 'string' || _typeof(message.location.position) !== 'object' || !message.location.position)) {
        invalidLocation = true;
        messages.push('Message.location must be valid');
      } else if (!invalidLocation) {
        var range = atom$1.Range.fromObject(message.location.position);
        if (Number.isNaN(range.start.row) || Number.isNaN(range.start.column) || Number.isNaN(range.end.row) || Number.isNaN(range.end.column)) {
          invalidLocation = true;
          messages.push('Message.location.position should not contain NaN coordinates');
        }
      }
      if (!invalidSolution && message.solutions && !Array.isArray(message.solutions)) {
        invalidSolution = true;
        messages.push('Message.solutions must be valid');
      }
      if (!invalidReference && reference && ((typeof reference === 'undefined' ? 'undefined' : _typeof(reference)) !== 'object' || typeof reference.file !== 'string' || _typeof(reference.position) !== 'object' || !reference.position)) {
        invalidReference = true;
        messages.push('Message.reference must be valid');
      } else if (!invalidReference && reference) {
        var position = atom$1.Point.fromObject(reference.position);
        if (Number.isNaN(position.row) || Number.isNaN(position.column)) {
          invalidReference = true;
          messages.push('Message.reference.position should not contain NaN coordinates');
        }
      }
      if (!invalidExcerpt && typeof message.excerpt !== 'string') {
        invalidExcerpt = true;
        messages.push('Message.excerpt must be a string');
      }
      if (!invalidSeverity && !VALID_SEVERITY.has(message.severity)) {
        invalidSeverity = true;
        messages.push("Message.severity must be 'error', 'warning' or 'info'");
      }
      if (!invalidURL && message.url && typeof message.url !== 'string') {
        invalidURL = true;
        messages.push('Message.url must a string');
      }
      if (!invalidDescription && message.description && typeof message.description !== 'function' && typeof message.description !== 'string') {
        invalidDescription = true;
        messages.push('Message.description must be a function or string');
      }
    }
  } else {
    messages.push('Linter Result must be an Array');
  }

  if (messages.length) {
    showError('Invalid Linter Result received', 'These issues were encountered while processing messages from a linter named \'' + linterName + '\'', messages);
    return false;
  }

  return true;
}

function validateMessagesLegacy(linterName, entries) {
  var messages = [];

  if (Array.isArray(entries)) {
    var invalidFix = false;
    var invalidType = false;
    var invalidClass = false;
    var invalidRange = false;
    var invalidTrace = false;
    var invalidContent = false;
    var invalidFilePath = false;
    var invalidSeverity = false;

    for (var i = 0, length = entries.length; i < length; ++i) {
      var message = entries[i];
      if (!invalidType && typeof message.type !== 'string') {
        invalidType = true;
        messages.push('Message.type must be a string');
      }
      if (!invalidContent && (typeof message.text !== 'string' && typeof message.html !== 'string' && !(message.html instanceof HTMLElement) || !message.text && !message.html)) {
        invalidContent = true;
        messages.push('Message.text or Message.html must have a valid value');
      }
      if (!invalidFilePath && message.filePath && typeof message.filePath !== 'string') {
        invalidFilePath = true;
        messages.push('Message.filePath must be a string');
      }
      if (!invalidRange && message.range && _typeof(message.range) !== 'object') {
        invalidRange = true;
        messages.push('Message.range must be an object');
      } else if (!invalidRange && message.range) {
        var range = atom$1.Range.fromObject(message.range);
        if (Number.isNaN(range.start.row) || Number.isNaN(range.start.column) || Number.isNaN(range.end.row) || Number.isNaN(range.end.column)) {
          invalidRange = true;
          messages.push('Message.range should not contain NaN coordinates');
        }
      }
      if (!invalidClass && message.class && typeof message.class !== 'string') {
        invalidClass = true;
        messages.push('Message.class must be a string');
      }
      if (!invalidSeverity && message.severity && !VALID_SEVERITY.has(message.severity)) {
        invalidSeverity = true;
        messages.push("Message.severity must be 'error', 'warning' or 'info'");
      }
      if (!invalidTrace && message.trace && !Array.isArray(message.trace)) {
        invalidTrace = true;
        messages.push('Message.trace must be an Array');
      }
      if (!invalidFix && message.fix && (_typeof(message.fix.range) !== 'object' || typeof message.fix.newText !== 'string' || message.fix.oldText && typeof message.fix.oldText !== 'string')) {
        invalidFix = true;
        messages.push('Message.fix must be valid');
      }
    }
  } else {
    messages.push('Linter Result must be an Array');
  }

  if (messages.length) {
    showError('Invalid Linter Result received', 'These issues were encountered while processing messages from a linter named \'' + linterName + '\'', messages);
    return false;
  }

  return true;
}

var UIRegistry = function () {
  function UIRegistry() {
    classCallCheck(this, UIRegistry);

    this.providers = new Set();
    this.subscriptions = new atom$1.CompositeDisposable();
  }

  createClass(UIRegistry, [{
    key: 'add',
    value: function add(ui$$1) {
      if (!this.providers.has(ui$$1) && validateUI(ui$$1)) {
        this.subscriptions.add(ui$$1);
        this.providers.add(ui$$1);
      }
    }
  }, {
    key: 'delete',
    value: function _delete(provider) {
      if (this.providers.has(provider)) {
        provider.dispose();
        this.providers.delete(provider);
      }
    }
  }, {
    key: 'render',
    value: function render(messages$$1) {
      this.providers.forEach(function (provider) {
        provider.render(messages$$1);
      });
    }
  }, {
    key: 'didBeginLinting',
    value: function didBeginLinting(linter$$1) {
      var filePath = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;

      this.providers.forEach(function (provider) {
        provider.didBeginLinting(linter$$1, filePath);
      });
    }
  }, {
    key: 'didFinishLinting',
    value: function didFinishLinting(linter$$1) {
      var filePath = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;

      this.providers.forEach(function (provider) {
        provider.didFinishLinting(linter$$1, filePath);
      });
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      this.providers.clear();
      this.subscriptions.dispose();
    }
  }]);
  return UIRegistry;
}();

var ToggleProviders = function () {
  function ToggleProviders(action, providers) {
    var _this = this;

    classCallCheck(this, ToggleProviders);

    this.action = action;
    this.emitter = new atom$1.Emitter();
    this.providers = providers;
    this.subscriptions = new atom$1.CompositeDisposable();

    this.subscriptions.add(this.emitter);
    this.subscriptions.add(atom.config.observe('linter.disabledProviders', function (disabledProviders) {
      _this.disabledProviders = disabledProviders;
    }));
  }

  createClass(ToggleProviders, [{
    key: 'getItems',
    value: function () {
      var _ref = asyncToGenerator(function* () {
        var _this2 = this;

        if (this.action === 'disable') {
          return this.providers.filter(function (name) {
            return !_this2.disabledProviders.includes(name);
          });
        }
        return this.disabledProviders;
      });

      function getItems() {
        return _ref.apply(this, arguments);
      }

      return getItems;
    }()
  }, {
    key: 'process',
    value: function () {
      var _ref2 = asyncToGenerator(function* (name) {
        if (this.action === 'disable') {
          this.disabledProviders.push(name);
          this.emitter.emit('did-disable', name);
        } else {
          var index = this.disabledProviders.indexOf(name);
          if (index !== -1) {
            this.disabledProviders.splice(index, 1);
          }
        }
        atom.config.set('linter.disabledProviders', this.disabledProviders);
      });

      function process(_x) {
        return _ref2.apply(this, arguments);
      }

      return process;
    }()
  }, {
    key: 'show',
    value: function () {
      var _ref3 = asyncToGenerator(function* () {
        var _this3 = this;

        var selectListView = new SelectListView({
          items: yield this.getItems(),
          emptyMessage: 'No matches found',
          filterKeyForItem: function filterKeyForItem(item) {
            return item;
          },
          elementForItem: function elementForItem(item) {
            var li = document.createElement('li');
            li.textContent = item;
            return li;
          },
          didConfirmSelection: function didConfirmSelection(item) {
            _this3.process(item).catch(function (e) {
              return console.error('[Linter] Unable to process toggle:', e);
            }).then(function () {
              return _this3.dispose();
            });
          },
          didCancelSelection: function didCancelSelection() {
            _this3.dispose();
          }
        });
        var panel = atom.workspace.addModalPanel({ item: selectListView });

        selectListView.focus();
        this.subscriptions.add(new atom$1.Disposable(function () {
          panel.destroy();
        }));
      });

      function show() {
        return _ref3.apply(this, arguments);
      }

      return show;
    }()
  }, {
    key: 'onDidDispose',
    value: function onDidDispose(callback) {
      return this.emitter.on('did-dispose', callback);
    }
  }, {
    key: 'onDidDisable',
    value: function onDidDisable(callback) {
      return this.emitter.on('did-disable', callback);
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      this.emitter.emit('did-dispose');
      this.subscriptions.dispose();
    }
  }]);
  return ToggleProviders;
}();

var $version = '__$sb_linter_version';
var $activated = '__$sb_linter_activated';
var $requestLatest = '__$sb_linter_request_latest';
var $requestLastReceived = '__$sb_linter_request_last_received';

function shouldTriggerLinter(linter, wasTriggeredOnChange, scopes) {
  if (wasTriggeredOnChange && !(linter[$version] === 2 ? linter.lintsOnChange : linter.lintOnFly)) {
    return false;
  }
  return scopes.some(function (scope) {
    return linter.grammarScopes.includes(scope);
  });
}

var arrayUnique$1 = void 0;
function getEditorCursorScopes(textEditor) {
  if (!arrayUnique$1) {
    arrayUnique$1 = require('lodash.uniq');
  }

  return arrayUnique$1(textEditor.getCursors().reduce(function (scopes, cursor) {
    return scopes.concat(cursor.getScopeDescriptor().getScopesArray());
  }, ['*']));
}

var minimatch = void 0;
function isPathIgnored(filePath, ignoredGlob, ignoredVCS) {
  if (!minimatch) {
    minimatch = require('minimatch');
  }

  if (ignoredVCS) {
    var repository = null;
    var projectPaths = atom.project.getPaths();
    for (var i = 0, length = projectPaths.length; i < length; ++i) {
      var projectPath = projectPaths[i];
      if (filePath.indexOf(projectPath) === 0) {
        repository = atom.project.getRepositories()[i];
        break;
      }
    }
    if (repository && repository.isPathIgnored(filePath)) {
      return true;
    }
  }
  var normalizedFilePath = process.platform === 'win32' ? filePath.replace(/\\/g, '/') : filePath;
  return minimatch(normalizedFilePath, ignoredGlob);
}

function subscriptiveObserve(object, eventName, callback) {
  var subscription = null;
  var eventSubscription = object.observe(eventName, function (props) {
    if (subscription) {
      subscription.dispose();
    }
    subscription = callback.call(this, props);
  });

  return new atom$1.Disposable(function () {
    eventSubscription.dispose();
    if (subscription) {
      subscription.dispose();
    }
  });
}

function messageKey(message) {
  var reference = message.reference;
  return ['$LINTER:' + message.linterName, '$LOCATION:' + message.location.file + '$' + message.location.position.start.row + '$' + message.location.position.start.column + '$' + message.location.position.end.row + '$' + message.location.position.end.column, reference ? '$REFERENCE:' + reference.file + '$' + (reference.position ? reference.position.row + '$' + reference.position.column : '') : '$REFERENCE:null', '$EXCERPT:' + message.excerpt, '$SEVERITY:' + message.severity, message.icon ? '$ICON:' + message.icon : '$ICON:null', message.url ? '$URL:' + message.url : '$URL:null'].join('');
}

function normalizeMessages(linterName, messages) {
  for (var i = 0, length = messages.length; i < length; ++i) {
    var message = messages[i];
    var reference = message.reference;
    if (Array.isArray(message.location.position)) {
      message.location.position = atom$1.Range.fromObject(message.location.position);
    }
    if (reference && Array.isArray(reference.position)) {
      reference.position = atom$1.Point.fromObject(reference.position);
    }
    if (message.solutions && message.solutions.length) {
      for (var j = 0, _length = message.solutions.length, solution; j < _length; j++) {
        solution = message.solutions[j];
        if (Array.isArray(solution.position)) {
          solution.position = atom$1.Range.fromObject(solution.position);
        }
      }
    }
    message.version = 2;
    message.linterName = linterName;
    message.key = messageKey(message);
  }
}

function messageKeyLegacy(message) {
  return ['$LINTER:' + message.linterName, '$LOCATION:' + (message.filePath || '') + '$' + (message.range ? message.range.start.row + '$' + message.range.start.column + '$' + message.range.end.row + '$' + message.range.end.column : ''), '$TEXT:' + (message.text || ''), '$HTML:' + (message.html || ''), '$SEVERITY:' + message.severity, '$TYPE:' + message.type, '$CLASS:' + (message.class || '')].join('');
}

function normalizeMessagesLegacy(linterName, messages) {
  for (var i = 0, length = messages.length; i < length; ++i) {
    var message = messages[i];
    var fix = message.fix;
    if (message.range && message.range.constructor.name === 'Array') {
      message.range = atom$1.Range.fromObject(message.range);
    }
    if (fix && fix.range.constructor.name === 'Array') {
      fix.range = atom$1.Range.fromObject(fix.range);
    }
    if (!message.severity) {
      var type = message.type.toLowerCase();
      if (type === 'warning') {
        message.severity = type;
      } else if (type === 'info' || type === 'trace') {
        message.severity = 'info';
      } else {
        message.severity = 'error';
      }
    }
    message.version = 1;
    message.linterName = linterName;
    message.key = messageKeyLegacy(message);

    if (message.trace) {
      normalizeMessagesLegacy(linterName, message.trace);
    }
  }
}

var IndieDelegate = function () {
  function IndieDelegate(indie$$1, version) {
    classCallCheck(this, IndieDelegate);

    this.indie = indie$$1;
    this.scope = 'project';
    this.version = version;
    this.emitter = new atom$1.Emitter();
    this.messages = new Map();
    this.subscriptions = new atom$1.CompositeDisposable();

    this.subscriptions.add(this.emitter);
  }

  createClass(IndieDelegate, [{
    key: 'getMessages',
    value: function getMessages() {
      return Array.from(this.messages.values()).reduce(function (toReturn, entry) {
        return toReturn.concat(entry);
      }, []);
    }
  }, {
    key: 'deleteMessages',
    value: function deleteMessages() {
      if (this.version === 1) {
        this.clearMessages();
      } else {
        throw new Error('Call to depreciated method deleteMessages(). Use clearMessages() insead');
      }
    }
  }, {
    key: 'clearMessages',
    value: function clearMessages() {
      if (!this.subscriptions.disposed) {
        this.emitter.emit('did-update', []);
        this.messages.clear();
      }
    }
  }, {
    key: 'setMessages',
    value: function setMessages(filePathOrMessages) {
      var messages$$1 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;

      // Legacy support area
      if (this.version === 1) {
        if (!Array.isArray(filePathOrMessages)) {
          throw new Error('Parameter 1 to setMessages() must be Array');
        }
        this.setAllMessages(filePathOrMessages);
        return;
      }

      // v2 Support from here on
      if (typeof filePathOrMessages !== 'string' || !Array.isArray(messages$$1)) {
        throw new Error('Invalid Parameters to setMessages()');
      }
      var filePath = filePathOrMessages;
      if (this.subscriptions.disposed || !validateMessages(this.name, messages$$1)) {
        return;
      }
      messages$$1.forEach(function (message) {
        if (message.location.file !== filePath) {
          console.debug('[Linter-UI-Default] Expected File', filePath, 'Message', message);
          throw new Error('message.location.file does not match the given filePath');
        }
      });

      normalizeMessages(this.name, messages$$1);
      this.messages.set(filePath, messages$$1);
      this.emitter.emit('did-update', this.getMessages());
    }
  }, {
    key: 'setAllMessages',
    value: function setAllMessages(messages$$1) {
      if (this.subscriptions.disposed) {
        return;
      }

      if (this.version === 1) {
        if (!validateMessagesLegacy(this.name, messages$$1)) return;
        normalizeMessagesLegacy(this.name, messages$$1);
      } else {
        if (!validateMessages(this.name, messages$$1)) return;
        normalizeMessages(this.name, messages$$1);
      }

      this.messages.clear();
      for (var i = 0, length = messages$$1.length; i < length; ++i) {
        var message = messages$$1[i];
        var filePath = message.version === 1 ? message.filePath : message.location.file;
        var fileMessages = this.messages.get(filePath);
        if (!fileMessages) {
          this.messages.set(filePath, fileMessages = []);
        }
        fileMessages.push(message);
      }
      this.emitter.emit('did-update', this.getMessages());
    }
  }, {
    key: 'onDidUpdate',
    value: function onDidUpdate(callback) {
      return this.emitter.on('did-update', callback);
    }
  }, {
    key: 'onDidDestroy',
    value: function onDidDestroy(callback) {
      return this.emitter.on('did-destroy', callback);
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      this.emitter.emit('did-destroy');
      this.subscriptions.dispose();
      this.messages.clear();
    }
  }, {
    key: 'name',
    get: function get$$1() {
      return this.indie.name;
    }
  }]);
  return IndieDelegate;
}();

var IndieRegistry = function () {
  function IndieRegistry() {
    classCallCheck(this, IndieRegistry);

    this.emitter = new atom$1.Emitter();
    this.delegates = new Set();
    this.subscriptions = new atom$1.CompositeDisposable();

    this.subscriptions.add(this.emitter);
  }

  createClass(IndieRegistry, [{
    key: 'register',
    value: function register(config, version) {
      var _this = this;

      if (!validateIndie(config)) {
        throw new Error('Error registering Indie Linter');
      }
      var indieLinter = new IndieDelegate(config, version);
      this.delegates.add(indieLinter);
      indieLinter.onDidDestroy(function () {
        _this.delegates.delete(indieLinter);
      });
      indieLinter.onDidUpdate(function (messages$$1) {
        _this.emitter.emit('did-update', { linter: indieLinter, messages: messages$$1 });
      });
      this.emitter.emit('observe', indieLinter);

      return indieLinter;
    }
  }, {
    key: 'observe',
    value: function observe(callback) {
      this.delegates.forEach(callback);
      return this.emitter.on('observe', callback);
    }
  }, {
    key: 'onDidUpdate',
    value: function onDidUpdate(callback) {
      return this.emitter.on('did-update', callback);
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = this.delegates[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          var entry = _step.value;

          entry.dispose();
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }

      this.subscriptions.dispose();
    }
  }]);
  return IndieRegistry;
}();

/* eslint-disable import/no-duplicates */

var $version$1 = $version;
var $activated$1 = $activated;
var $requestLatest$1 = $requestLatest;
var $requestLastReceived$1 = $requestLastReceived;

var LinterRegistry = function () {
  function LinterRegistry() {
    var _this = this;

    classCallCheck(this, LinterRegistry);

    this.emitter = new atom$1.Emitter();
    this.linters = new Set();
    this.subscriptions = new atom$1.CompositeDisposable();

    this.subscriptions.add(atom.config.observe('linter.lintOnChange', function (lintOnChange) {
      _this.lintOnChange = lintOnChange;
    }));
    this.subscriptions.add(atom.config.observe('core.excludeVcsIgnoredPaths', function (ignoreVCS) {
      _this.ignoreVCS = ignoreVCS;
    }));
    this.subscriptions.add(atom.config.observe('linter.ignoreGlob', function (ignoreGlob) {
      _this.ignoreGlob = ignoreGlob;
    }));
    this.subscriptions.add(atom.config.observe('linter.lintPreviewTabs', function (lintPreviewTabs) {
      _this.lintPreviewTabs = lintPreviewTabs;
    }));
    this.subscriptions.add(atom.config.observe('linter.disabledProviders', function (disabledProviders) {
      _this.disabledProviders = disabledProviders;
    }));
    this.subscriptions.add(this.emitter);
  }

  createClass(LinterRegistry, [{
    key: 'hasLinter',
    value: function hasLinter(linter$$1) {
      return this.linters.has(linter$$1);
    }
  }, {
    key: 'addLinter',
    value: function addLinter(linter$$1) {
      var legacy = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

      var version = legacy ? 1 : 2;
      if (!validateLinter(linter$$1, version)) {
        return;
      }
      linter$$1[$activated$1] = true;
      if (typeof linter$$1[$requestLatest$1] === 'undefined') {
        linter$$1[$requestLatest$1] = 0;
      }
      if (typeof linter$$1[$requestLastReceived$1] === 'undefined') {
        linter$$1[$requestLastReceived$1] = 0;
      }
      linter$$1[$version$1] = version;
      this.linters.add(linter$$1);
    }
  }, {
    key: 'getLinters',
    value: function getLinters() {
      return Array.from(this.linters);
    }
  }, {
    key: 'deleteLinter',
    value: function deleteLinter(linter$$1) {
      if (!this.linters.has(linter$$1)) {
        return;
      }
      linter$$1[$activated$1] = false;
      this.linters.delete(linter$$1);
    }
  }, {
    key: 'lint',
    value: function () {
      var _ref = asyncToGenerator(function* (_ref2) {
        var _this2 = this;

        var onChange = _ref2.onChange,
            editor = _ref2.editor;

        var filePath = editor.getPath();

        if (onChange && !this.lintOnChange || // Lint-on-change mismatch
        !filePath || // Not saved anywhere yet
        isPathIgnored(editor.getPath(), this.ignoreGlob, this.ignoreVCS) || // Ignored by VCS or Glob
        !this.lintPreviewTabs && atom.workspace.getActivePane().getPendingItem() === editor // Ignore Preview tabs
        ) {
            return false;
          }

        var scopes = getEditorCursorScopes(editor);

        var promises = [];

        var _loop = function _loop(linter$$1) {
          if (!shouldTriggerLinter(linter$$1, onChange, scopes)) {
            return 'continue';
          }
          if (_this2.disabledProviders.includes(linter$$1.name)) {
            return 'continue';
          }
          var number = ++linter$$1[$requestLatest$1];
          var statusBuffer = linter$$1.scope === 'file' ? editor.getBuffer() : null;
          var statusFilePath = linter$$1.scope === 'file' ? filePath : null;

          _this2.emitter.emit('did-begin-linting', { number: number, linter: linter$$1, filePath: statusFilePath });
          promises.push(new Promise(function (resolve) {
            // $FlowIgnore: Type too complex, duh
            resolve(linter$$1.lint(editor));
          }).then(function (messages$$1) {
            _this2.emitter.emit('did-finish-linting', { number: number, linter: linter$$1, filePath: statusFilePath });
            if (linter$$1[$requestLastReceived$1] >= number || !linter$$1[$activated$1] || statusBuffer && !statusBuffer.isAlive()) {
              return;
            }
            linter$$1[$requestLastReceived$1] = number;
            if (statusBuffer && !statusBuffer.isAlive()) {
              return;
            }

            if (messages$$1 === null) {
              // NOTE: Do NOT update the messages when providers return null
              return;
            }

            var validity = true;
            // NOTE: We are calling it when results are not an array to show a nice notification
            if (atom.inDevMode() || !Array.isArray(messages$$1)) {
              validity = linter$$1[$version$1] === 2 ? validateMessages(linter$$1.name, messages$$1) : validateMessagesLegacy(linter$$1.name, messages$$1);
            }
            if (!validity) {
              return;
            }

            if (linter$$1[$version$1] === 2) {
              normalizeMessages(linter$$1.name, messages$$1);
            } else {
              normalizeMessagesLegacy(linter$$1.name, messages$$1);
            }
            _this2.emitter.emit('did-update-messages', { messages: messages$$1, linter: linter$$1, buffer: statusBuffer });
          }, function (error) {
            _this2.emitter.emit('did-finish-linting', { number: number, linter: linter$$1, filePath: statusFilePath });
            atom.notifications.addError('[Linter] Error running ' + linter$$1.name, {
              detail: 'See Console for more info. (Open View -> Developer -> Toogle Developer Tools)'
            });
            console.error('[Linter] Error running ' + linter$$1.name, error);
          }));
        };

        var _iteratorNormalCompletion = true;
        var _didIteratorError = false;
        var _iteratorError = undefined;

        try {
          for (var _iterator = this.linters[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
            var linter$$1 = _step.value;

            var _ret = _loop(linter$$1);

            if (_ret === 'continue') continue;
          }
        } catch (err) {
          _didIteratorError = true;
          _iteratorError = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion && _iterator.return) {
              _iterator.return();
            }
          } finally {
            if (_didIteratorError) {
              throw _iteratorError;
            }
          }
        }

        yield Promise.all(promises);
        return true;
      });

      function lint(_x2) {
        return _ref.apply(this, arguments);
      }

      return lint;
    }()
  }, {
    key: 'onDidUpdateMessages',
    value: function onDidUpdateMessages(callback) {
      return this.emitter.on('did-update-messages', callback);
    }
  }, {
    key: 'onDidBeginLinting',
    value: function onDidBeginLinting(callback) {
      return this.emitter.on('did-begin-linting', callback);
    }
  }, {
    key: 'onDidFinishLinting',
    value: function onDidFinishLinting(callback) {
      return this.emitter.on('did-finish-linting', callback);
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      this.linters.clear();
      this.subscriptions.dispose();
    }
  }]);
  return LinterRegistry;
}();

var MessageRegistry = function () {
  function MessageRegistry() {
    classCallCheck(this, MessageRegistry);

    this.emitter = new atom$1.Emitter();
    this.messages = [];
    this.messagesMap = new Set();
    this.subscriptions = new atom$1.CompositeDisposable();
    this.debouncedUpdate = debounce(this.update, 100, true);

    this.subscriptions.add(this.emitter);
  }

  createClass(MessageRegistry, [{
    key: 'set',
    value: function set$$1(_ref) {
      var messages = _ref.messages,
          linter = _ref.linter,
          buffer = _ref.buffer;

      var found = null;
      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = this.messagesMap[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          var entry = _step.value;

          if (entry.buffer === buffer && entry.linter === linter) {
            found = entry;
            break;
          }
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }

      if (found) {
        found.messages = messages;
        found.changed = true;
      } else {
        this.messagesMap.add({ messages: messages, linter: linter, buffer: buffer, oldMessages: [], changed: true, deleted: false });
      }
      this.debouncedUpdate();
    }
  }, {
    key: 'update',
    value: function update() {
      var result = { added: [], removed: [], messages: [] };

      var _iteratorNormalCompletion2 = true;
      var _didIteratorError2 = false;
      var _iteratorError2 = undefined;

      try {
        for (var _iterator2 = this.messagesMap[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
          var entry = _step2.value;

          if (entry.deleted) {
            result.removed = result.removed.concat(entry.oldMessages);
            this.messagesMap.delete(entry);
            continue;
          }
          if (!entry.changed) {
            result.messages = result.messages.concat(entry.oldMessages);
            continue;
          }
          entry.changed = false;
          if (!entry.oldMessages.length) {
            // All messages are new, no need to diff
            // NOTE: No need to add .key here because normalizeMessages already does that
            result.added = result.added.concat(entry.messages);
            result.messages = result.messages.concat(entry.messages);
            entry.oldMessages = entry.messages;
            continue;
          }
          if (!entry.messages.length) {
            // All messages are old, no need to diff
            result.removed = result.removed.concat(entry.oldMessages);
            entry.oldMessages = [];
            continue;
          }

          var newKeys = new Set();
          var oldKeys = new Set();
          var _oldMessages = entry.oldMessages;
          var foundNew = false;
          entry.oldMessages = [];

          for (var i = 0, length = _oldMessages.length; i < length; ++i) {
            var message = _oldMessages[i];
            if (message.version === 2) {
              message.key = messageKey(message);
            } else {
              message.key = messageKeyLegacy(message);
            }
            oldKeys.add(message.key);
          }

          for (var _i = 0, _length = entry.messages.length; _i < _length; ++_i) {
            var _message = entry.messages[_i];
            if (newKeys.has(_message.key)) {
              continue;
            }
            newKeys.add(_message.key);
            if (!oldKeys.has(_message.key)) {
              foundNew = true;
              result.added.push(_message);
              result.messages.push(_message);
              entry.oldMessages.push(_message);
            }
          }

          if (!foundNew && entry.messages.length === _oldMessages.length) {
            // Messages are unchanged
            result.messages = result.messages.concat(_oldMessages);
            entry.oldMessages = _oldMessages;
            continue;
          }

          for (var _i2 = 0, _length2 = _oldMessages.length; _i2 < _length2; ++_i2) {
            var _message2 = _oldMessages[_i2];
            if (newKeys.has(_message2.key)) {
              entry.oldMessages.push(_message2);
              result.messages.push(_message2);
            } else {
              result.removed.push(_message2);
            }
          }
        }
      } catch (err) {
        _didIteratorError2 = true;
        _iteratorError2 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion2 && _iterator2.return) {
            _iterator2.return();
          }
        } finally {
          if (_didIteratorError2) {
            throw _iteratorError2;
          }
        }
      }

      if (result.added.length || result.removed.length) {
        this.messages = result.messages;
        this.emitter.emit('did-update-messages', result);
      }
    }
  }, {
    key: 'onDidUpdateMessages',
    value: function onDidUpdateMessages(callback) {
      return this.emitter.on('did-update-messages', callback);
    }
  }, {
    key: 'deleteByBuffer',
    value: function deleteByBuffer(buffer) {
      var _iteratorNormalCompletion3 = true;
      var _didIteratorError3 = false;
      var _iteratorError3 = undefined;

      try {
        for (var _iterator3 = this.messagesMap[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
          var entry = _step3.value;

          if (entry.buffer === buffer) {
            entry.deleted = true;
          }
        }
      } catch (err) {
        _didIteratorError3 = true;
        _iteratorError3 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion3 && _iterator3.return) {
            _iterator3.return();
          }
        } finally {
          if (_didIteratorError3) {
            throw _iteratorError3;
          }
        }
      }

      this.debouncedUpdate();
    }
  }, {
    key: 'deleteByLinter',
    value: function deleteByLinter(linter) {
      var _iteratorNormalCompletion4 = true;
      var _didIteratorError4 = false;
      var _iteratorError4 = undefined;

      try {
        for (var _iterator4 = this.messagesMap[Symbol.iterator](), _step4; !(_iteratorNormalCompletion4 = (_step4 = _iterator4.next()).done); _iteratorNormalCompletion4 = true) {
          var entry = _step4.value;

          if (entry.linter === linter) {
            entry.deleted = true;
          }
        }
      } catch (err) {
        _didIteratorError4 = true;
        _iteratorError4 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion4 && _iterator4.return) {
            _iterator4.return();
          }
        } finally {
          if (_didIteratorError4) {
            throw _iteratorError4;
          }
        }
      }

      this.debouncedUpdate();
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      this.subscriptions.dispose();
    }
  }]);
  return MessageRegistry;
}();

var EditorLinter = function () {
  function EditorLinter(editor) {
    var _this = this;

    classCallCheck(this, EditorLinter);

    if (!atom.workspace.isTextEditor(editor)) {
      throw new Error('EditorLinter expects a valid TextEditor');
    }

    this.editor = editor;
    this.emitter = new atom$1.Emitter();
    this.subscriptions = new atom$1.CompositeDisposable();

    this.subscriptions.add(this.editor.onDidDestroy(function () {
      return _this.dispose();
    }));
    this.subscriptions.add(this.editor.onDidSave(debounce(function () {
      return _this.emitter.emit('should-lint', false);
    }), 16, true));
    // NOTE: TextEditor::onDidChange immediately invokes the callback if the text editor was *just* created
    // Using TextBuffer::onDidChange doesn't have the same behavior so using it instead.
    this.subscriptions.add(subscriptiveObserve(atom.config, 'linter.lintOnChangeInterval', function (interval) {
      return _this.editor.getBuffer().onDidChange(debounce(function () {
        _this.emitter.emit('should-lint', true);
      }, interval));
    }));
  }

  createClass(EditorLinter, [{
    key: 'getEditor',
    value: function getEditor() {
      return this.editor;
    }
  }, {
    key: 'lint',
    value: function lint() {
      var onChange = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

      this.emitter.emit('should-lint', onChange);
    }
  }, {
    key: 'onShouldLint',
    value: function onShouldLint(callback) {
      return this.emitter.on('should-lint', callback);
    }
  }, {
    key: 'onDidDestroy',
    value: function onDidDestroy(callback) {
      return this.emitter.on('did-destroy', callback);
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      this.emitter.emit('did-destroy');
      this.subscriptions.dispose();
      this.emitter.dispose();
    }
  }]);
  return EditorLinter;
}();

var EditorRegistry = function () {
  function EditorRegistry() {
    var _this = this;

    classCallCheck(this, EditorRegistry);

    this.emitter = new atom$1.Emitter();
    this.subscriptions = new atom$1.CompositeDisposable();
    this.editorLinters = new Map();

    this.subscriptions.add(this.emitter);
    this.subscriptions.add(atom.config.observe('linter.lintOnOpen', function (lintOnOpen) {
      _this.lintOnOpen = lintOnOpen;
    }));
  }

  createClass(EditorRegistry, [{
    key: 'activate',
    value: function activate() {
      var _this2 = this;

      this.subscriptions.add(atom.workspace.observeTextEditors(function (textEditor) {
        _this2.createFromTextEditor(textEditor);
      }));
    }
  }, {
    key: 'get',
    value: function get$$1(textEditor) {
      return this.editorLinters.get(textEditor);
    }
  }, {
    key: 'createFromTextEditor',
    value: function createFromTextEditor(textEditor) {
      var _this3 = this;

      var editorLinter = this.editorLinters.get(textEditor);
      if (editorLinter) {
        return editorLinter;
      }
      editorLinter = new EditorLinter(textEditor);
      editorLinter.onDidDestroy(function () {
        _this3.editorLinters.delete(textEditor);
      });
      this.editorLinters.set(textEditor, editorLinter);
      this.emitter.emit('observe', editorLinter);
      if (this.lintOnOpen) {
        editorLinter.lint();
      }
      return editorLinter;
    }
  }, {
    key: 'observe',
    value: function observe(callback) {
      this.editorLinters.forEach(callback);
      return this.emitter.on('observe', callback);
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = this.editorLinters.values()[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          var entry = _step.value;

          entry.dispose();
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }

      this.subscriptions.dispose();
    }
  }]);
  return EditorRegistry;
}();

var Linter = function () {
  function Linter() {
    var _this = this;

    classCallCheck(this, Linter);

    this.commands = new Commands();
    this.registryUI = new UIRegistry();
    this.registryIndie = new IndieRegistry();
    this.registryEditors = new EditorRegistry();
    this.registryLinters = new LinterRegistry();
    this.registryMessages = new MessageRegistry();

    this.subscriptions = new atom$1.CompositeDisposable();

    this.subscriptions.add(this.commands);
    this.subscriptions.add(this.registryUI);
    this.subscriptions.add(this.registryIndie);
    this.subscriptions.add(this.registryMessages);
    this.subscriptions.add(this.registryEditors);
    this.subscriptions.add(this.registryLinters);

    this.commands.onShouldLint(function () {
      var editorLinter = _this.registryEditors.get(atom.workspace.getActiveTextEditor());
      if (editorLinter) {
        editorLinter.lint();
      }
    });
    this.commands.onShouldToggleActiveEditor(function () {
      var textEditor = atom.workspace.getActiveTextEditor();
      var editor = _this.registryEditors.get(textEditor);
      if (editor) {
        editor.dispose();
      } else if (textEditor) {
        _this.registryEditors.createFromTextEditor(textEditor);
      }
    });
    this.commands.onShouldDebug(asyncToGenerator(function* () {
      var linters = _this.registryLinters.getLinters();
      var textEditor = atom.workspace.getActiveTextEditor();
      var textEditorScopes = getEditorCursorScopes(textEditor);

      var manifest = atom.packages.getLoadedPackage('linter').metadata;
      var allLinters = linters.sort(function (a, b) {
        return a.name.localeCompare(b.name);
      }).map(function (linter) {
        return '  - ' + linter.name;
      }).join('\n');
      var matchingLinters = linters.filter(function (linter) {
        return shouldTriggerLinter(linter, false, textEditorScopes);
      }).sort(function (a, b) {
        return a.name.localeCompare(b.name);
      }).map(function (linter) {
        return '  - ' + linter.name;
      }).join('\n');
      var humanizedScopes = textEditorScopes.map(function (scope) {
        return '  - ' + scope;
      }).join('\n');
      var disabledLinters = atom.config.get('linter.disabledProviders').map(function (linter) {
        return '  - ' + linter;
      }).join('\n');

      atom.notifications.addInfo('Linter Debug Info', {
        detail: ['Platform: ' + process.platform, 'Atom Version: ' + atom.getVersion(), 'Linter Version: ' + manifest.version, 'All Linter Providers: \n' + allLinters, 'Matching Linter Providers: \n' + matchingLinters, 'Disabled Linter Providers; \n' + disabledLinters, 'Current File scopes: \n' + humanizedScopes].join('\n'),
        dismissable: true
      });
    }));
    this.commands.onShouldToggleLinter(function (action) {
      var toggleView = new ToggleProviders(action, arrayUnique(_this.registryLinters.getLinters().map(function (linter) {
        return linter.name;
      })));
      toggleView.onDidDispose(function () {
        _this.subscriptions.remove(toggleView);
      });
      toggleView.onDidDisable(function (name) {
        var linter = _this.registryLinters.getLinters().find(function (entry) {
          return entry.name === name;
        });
        if (linter) {
          _this.registryMessages.deleteByLinter(linter);
        }
      });
      toggleView.show();
      _this.subscriptions.add(toggleView);
    });
    this.registryIndie.observe(function (indieLinter) {
      indieLinter.onDidDestroy(function () {
        _this.registryMessages.deleteByLinter(indieLinter);
      });
    });
    this.registryEditors.observe(function (editorLinter) {
      editorLinter.onShouldLint(function (onChange) {
        _this.registryLinters.lint({ onChange: onChange, editor: editorLinter.getEditor() });
      });
      editorLinter.onDidDestroy(function () {
        _this.registryMessages.deleteByBuffer(editorLinter.getEditor().getBuffer());
      });
    });
    this.registryIndie.onDidUpdate(function (_ref2) {
      var linter = _ref2.linter,
          messages = _ref2.messages;

      _this.registryMessages.set({ linter: linter, messages: messages, buffer: null });
    });
    this.registryLinters.onDidUpdateMessages(function (_ref3) {
      var linter = _ref3.linter,
          messages = _ref3.messages,
          buffer = _ref3.buffer;

      _this.registryMessages.set({ linter: linter, messages: messages, buffer: buffer });
    });
    this.registryLinters.onDidBeginLinting(function (_ref4) {
      var linter = _ref4.linter,
          filePath = _ref4.filePath;

      _this.registryUI.didBeginLinting(linter, filePath);
    });
    this.registryLinters.onDidFinishLinting(function (_ref5) {
      var linter = _ref5.linter,
          filePath = _ref5.filePath;

      _this.registryUI.didFinishLinting(linter, filePath);
    });
    this.registryMessages.onDidUpdateMessages(function (difference) {
      _this.registryUI.render(difference);
    });

    this.registryEditors.activate();

    setTimeout(function () {
      // NOTE: Atom triggers this on boot so wait a while
      if (!_this.subscriptions.disposed) {
        _this.subscriptions.add(atom.project.onDidChangePaths(function () {
          _this.commands.lint();
        }));
      }
    }, 100);
  }

  createClass(Linter, [{
    key: 'dispose',
    value: function dispose() {
      this.subscriptions.dispose();
    }

    // API methods for providing/consuming services

  }, {
    key: 'addUI',
    value: function addUI(ui) {
      this.registryUI.add(ui);

      var messages = this.registryMessages.messages;
      if (messages.length) {
        ui.render({ added: messages, messages: messages, removed: [] });
      }
    }
  }, {
    key: 'deleteUI',
    value: function deleteUI(ui) {
      this.registryUI.delete(ui);
    }
  }, {
    key: 'addLinter',
    value: function addLinter(linter) {
      var legacy = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

      this.registryLinters.addLinter(linter, legacy);
    }
  }, {
    key: 'deleteLinter',
    value: function deleteLinter(linter) {
      this.registryLinters.deleteLinter(linter);
      this.registryMessages.deleteByLinter(linter);
    }
  }, {
    key: 'addIndie',
    value: function addIndie(indie) {
      this.registryIndie.register(indie, 2);
    }
  }, {
    key: 'addLegacyIndie',
    value: function addLegacyIndie(indie) {
      this.registryIndie.register(indie, 1);
    }
  }]);
  return Linter;
}();

var _templateObject = taggedTemplateLiteral(['\n      Hi Linter user! \uD83D\uDC4B\n\n      Linter has been upgraded to v2.\n\n      Packages compatible with v1 will keep working on v2 for a long time.\n      If you are a package author, I encourage you to upgrade your package to the Linter v2 API.\n\n      You can read [the announcement post on my blog](http://steelbrain.me/2017/03/13/linter-v2-released.html).\n    '], ['\n      Hi Linter user! \uD83D\uDC4B\n\n      Linter has been upgraded to v2.\n\n      Packages compatible with v1 will keep working on v2 for a long time.\n      If you are a package author, I encourage you to upgrade your package to the Linter v2 API.\n\n      You can read [the announcement post on my blog](http://steelbrain.me/2017/03/13/linter-v2-released.html).\n    ']);

var coolTrim = void 0;

function greet() {
  if (!coolTrim) {
    coolTrim = require('cool-trim');
  }

  return atom.notifications.addInfo('Welcome to Linter v2', {
    dismissable: true,
    description: coolTrim(_templateObject)
  });
}

// Greets
var Greeter = function () {
  function Greeter() {
    classCallCheck(this, Greeter);

    this.notifications = new Set();
  }

  createClass(Greeter, [{
    key: 'showWelcome',
    value: function showWelcome() {
      var _this = this;

      var notification = greet();
      notification.onDidDismiss(function () {
        return _this.notifications.delete(notification);
      });
      this.notifications.add(notification);
    }
  }, {
    key: 'dispose',
    value: function dispose() {
      this.notifications.forEach(function (n) {
        return n.dismiss();
      });
      this.notifications.clear();
    }
  }]);
  return Greeter;
}();

// Internal variables
var instance = void 0;

var idleCallbacks = new Set();

var index = {
  activate: function activate() {
    this.subscriptions = new atom$1.CompositeDisposable();

    instance = new Linter();
    this.subscriptions.add(instance);

    // TODO: Remove this after a few version bumps
    var oldConfigCallbackID = window.requestIdleCallback(function () {
      var _ref = asyncToGenerator(function* () {
        idleCallbacks.delete(oldConfigCallbackID);

        // Greet the user if they are coming from Linter v1
        var greeter = new Greeter();
        this.subscriptions.add(greeter);
        var linterConfigs = atom.config.get('linter');
        // Unset v1 configs
        var removedV1Configs = ['lintOnFly', 'lintOnFlyInterval', 'ignoredMessageTypes', 'ignoreVCSIgnoredFiles', 'ignoreMatchedFiles', 'showErrorInline', 'inlineTooltipInterval', 'gutterEnabled', 'gutterPosition', 'underlineIssues', 'showProviderName', 'showErrorPanel', 'errorPanelHeight', 'alwaysTakeMinimumSpace', 'displayLinterInfo', 'displayLinterStatus', 'showErrorTabLine', 'showErrorTabFile', 'showErrorTabProject', 'statusIconScope', 'statusIconPosition'];
        if (removedV1Configs.some(function (config) {
          return {}.hasOwnProperty.call(linterConfigs, config);
        })) {
          greeter.showWelcome();
        }
        removedV1Configs.forEach(function (e) {
          atom.config.unset('linter.' + e);
        });

        // There was an external config file in use briefly, migrate any use of that to settings
        var oldConfigFile = Path.join(atom.getConfigDirPath(), 'linter-config.json');
        if (yield FS.exists(oldConfigFile)) {
          var disabledProviders = atom.config.get('linter.disabledProviders');
          try {
            var oldConfigFileContents = yield FS.readFile(oldConfigFile, 'utf8');
            disabledProviders = disabledProviders.concat(JSON.parse(oldConfigFileContents).disabled);
          } catch (_) {
            console.error('[Linter] Error reading old state file', _);
          }
          atom.config.set('linter.disabledProviders', disabledProviders);
          try {
            yield FS.unlink(oldConfigFile);
          } catch (_) {/* No Op */}
        }
      });

      function linterOldConfigs() {
        return _ref.apply(this, arguments);
      }

      return linterOldConfigs;
    }().bind(this));
    idleCallbacks.add(oldConfigCallbackID);

    if (!atom.inSpecMode()) {
      var linterDepsCallback = window.requestIdleCallback(function linterDepsInstall() {
        idleCallbacks.delete(linterDepsCallback);
        require('atom-package-deps').install('linter', true);
      });
      idleCallbacks.add(linterDepsCallback);
    }
  },
  consumeLinter: function consumeLinter(linter) {
    var linters = [].concat(linter);
    var _iteratorNormalCompletion = true;
    var _didIteratorError = false;
    var _iteratorError = undefined;

    try {
      for (var _iterator = linters[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
        var entry = _step.value;

        instance.addLinter(entry);
      }
    } catch (err) {
      _didIteratorError = true;
      _iteratorError = err;
    } finally {
      try {
        if (!_iteratorNormalCompletion && _iterator.return) {
          _iterator.return();
        }
      } finally {
        if (_didIteratorError) {
          throw _iteratorError;
        }
      }
    }

    return new atom$1.Disposable(function () {
      var _iteratorNormalCompletion2 = true;
      var _didIteratorError2 = false;
      var _iteratorError2 = undefined;

      try {
        for (var _iterator2 = linters[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
          var _entry = _step2.value;

          instance.deleteLinter(_entry);
        }
      } catch (err) {
        _didIteratorError2 = true;
        _iteratorError2 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion2 && _iterator2.return) {
            _iterator2.return();
          }
        } finally {
          if (_didIteratorError2) {
            throw _iteratorError2;
          }
        }
      }
    });
  },
  consumeLinterLegacy: function consumeLinterLegacy(linter) {
    var linters = [].concat(linter);
    var _iteratorNormalCompletion3 = true;
    var _didIteratorError3 = false;
    var _iteratorError3 = undefined;

    try {
      for (var _iterator3 = linters[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
        var entry = _step3.value;

        linter.name = linter.name || 'Unknown';
        linter.lintOnFly = Boolean(linter.lintOnFly);
        instance.addLinter(entry, true);
      }
    } catch (err) {
      _didIteratorError3 = true;
      _iteratorError3 = err;
    } finally {
      try {
        if (!_iteratorNormalCompletion3 && _iterator3.return) {
          _iterator3.return();
        }
      } finally {
        if (_didIteratorError3) {
          throw _iteratorError3;
        }
      }
    }

    return new atom$1.Disposable(function () {
      var _iteratorNormalCompletion4 = true;
      var _didIteratorError4 = false;
      var _iteratorError4 = undefined;

      try {
        for (var _iterator4 = linters[Symbol.iterator](), _step4; !(_iteratorNormalCompletion4 = (_step4 = _iterator4.next()).done); _iteratorNormalCompletion4 = true) {
          var _entry2 = _step4.value;

          instance.deleteLinter(_entry2);
        }
      } catch (err) {
        _didIteratorError4 = true;
        _iteratorError4 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion4 && _iterator4.return) {
            _iterator4.return();
          }
        } finally {
          if (_didIteratorError4) {
            throw _iteratorError4;
          }
        }
      }
    });
  },
  consumeUI: function consumeUI(ui) {
    var uis = [].concat(ui);
    var _iteratorNormalCompletion5 = true;
    var _didIteratorError5 = false;
    var _iteratorError5 = undefined;

    try {
      for (var _iterator5 = uis[Symbol.iterator](), _step5; !(_iteratorNormalCompletion5 = (_step5 = _iterator5.next()).done); _iteratorNormalCompletion5 = true) {
        var entry = _step5.value;

        instance.addUI(entry);
      }
    } catch (err) {
      _didIteratorError5 = true;
      _iteratorError5 = err;
    } finally {
      try {
        if (!_iteratorNormalCompletion5 && _iterator5.return) {
          _iterator5.return();
        }
      } finally {
        if (_didIteratorError5) {
          throw _iteratorError5;
        }
      }
    }

    return new atom$1.Disposable(function () {
      var _iteratorNormalCompletion6 = true;
      var _didIteratorError6 = false;
      var _iteratorError6 = undefined;

      try {
        for (var _iterator6 = uis[Symbol.iterator](), _step6; !(_iteratorNormalCompletion6 = (_step6 = _iterator6.next()).done); _iteratorNormalCompletion6 = true) {
          var _entry3 = _step6.value;

          instance.deleteUI(_entry3);
        }
      } catch (err) {
        _didIteratorError6 = true;
        _iteratorError6 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion6 && _iterator6.return) {
            _iterator6.return();
          }
        } finally {
          if (_didIteratorError6) {
            throw _iteratorError6;
          }
        }
      }
    });
  },
  provideIndie: function provideIndie() {
    return function (indie) {
      return instance.addIndie(indie);
    };
  },
  provideIndieLegacy: function provideIndieLegacy() {
    return {
      register: function register(indie) {
        return instance.addLegacyIndie(indie);
      }
    };
  },
  deactivate: function deactivate() {
    idleCallbacks.forEach(function (callbackID) {
      return window.cancelIdleCallback(callbackID);
    });
    idleCallbacks.clear();
    this.subscriptions.dispose();
  }
};

module.exports = index;
