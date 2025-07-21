const auraPlugin = require("@salesforce/eslint-plugin-aura");
const lwcConfig = require("@salesforce/eslint-config-lwc/recommended");

module.exports = [
  ...lwcConfig,

  // Aura configuration
  {
    files: ["force-app/**/aura/**/*.js"],
    plugins: {
      "@salesforce/aura": auraPlugin
    },
    rules: {
      ...auraPlugin.configs.recommended.rules
    }
  }
];
