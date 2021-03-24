module.exports = {
  ...require('prettier-config-atomic'),
  // this just to minimize the changes for linter-ui-default
  printWidth: 125,
  singleQuote: true,
  arrowParens: 'avoid',
  trailingComma: 'all',
}
