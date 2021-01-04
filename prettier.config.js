// Add to .prettierignore to ignore files and folders

// This configuration all the formats including typescript, javascript, json, yaml, markdown
module.exports = {
  tabWidth: 2,
  printWidth: 125,
  semi: false,
  singleQuote: true, // this just to minimize the changes for linter-ui-default
  arrowParens: 'avoid', // ditto
  trailingComma: 'all', // ditto
  overrides: [
    {
      files: '{*.json}',
      options: {
        parser: 'json',
        trailingComma: 'es5',
      },
    },
    {
      files: '{*.md}',
      options: {
        parser: 'markdown',
        proseWrap: 'preserve',
      },
    },
  ],
}
