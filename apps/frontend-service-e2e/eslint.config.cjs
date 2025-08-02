const cypress = require('eslint-plugin-cypress/flat');
const baseConfig = require('../../.eslintrc.cjs');

module.exports = [
  cypress.configs['recommended'],

  ...baseConfig,
  {
    // Override or add rules here
    rules: {},
  },
];
