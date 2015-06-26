'use strict';

class BottomStatus extends HTMLElement {

  initialize(params) {
    // We accept two types,
    // `warning` and `error`
    this.messageType = params.type

    // Let's assume default case
    // is `error` messageType
    switch (params.type) {

      case 'warning':
        this.singularType = 'Warning'
        this.pluralType = 'Warnings'
        this.icon = 'icon-info'
        break;

      default:
        this.singularType = 'Error'
        this.pluralType = 'Errors'
        this.icon = 'icon-x'

    }

    this.classList.add('inline-block')
    this.classList.add('linter-highlight')

    this.iconSpan = document.createElement('span')
    this.iconSpan.classList.add('icon')
    this.appendChild(this.iconSpan)

    this.count = 0
  }

  set count(Value) {
    if (Value) {
      this.classList.remove('status-success')
      this.iconSpan.classList.remove('icon-check')

      this.classList.add(`status-${this.messageType}`)
      this.iconSpan.classList.add(this.icon)

      this.iconSpan.textContent = Value === 1 ? `1 ${this.singularType}` : `${Value} ${this.pluralType}`
    } else {
      this.classList.remove(`status-${this.messageType}`)
      this.iconSpan.classList.remove(this.icon)

      this.classList.add('status-success')
      this.iconSpan.classList.add('icon-check')

      this.iconSpan.textContent = `No ${this.pluralType}`
    }
  }

}

module.exports = BottomStatus = document.registerElement('linter-bottom-status', {prototype: BottomStatus.prototype})
