/* @flow */

export function showError(title: string, description: string, points: Array<string>) {
  const renderedPoints = points.map(item => `  • ${item}`)
  atom.notifications.addWarning(`[Linter] ${title}`, {
    dismissable: true,
    detail: `${description}\n${renderedPoints.join('\n')}`,
  })
}
