/* @flow */

// Greets
import greetV2Welcome from './greet-v2-welcome'

// Note: This package should not be used from "Main" class,
// Instead it should be used from the main package entry point directly
class Greeter {
  notifications: Set<Object>;
  constructor() {
    this.notifications = new Set()
  }
  showWelcome(): void {
    const notification = greetV2Welcome()
    notification.onDidDismiss(() => this.notifications.delete(notification))
    this.notifications.add(notification)
  }
  dispose() {
    this.notifications.forEach(n => n.dismiss())
    this.notifications.clear()
  }
}

module.exports = Greeter
