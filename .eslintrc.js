module.exports = {
  "extends": [
    "standard",
    'plugin:vue/recommended',
    'plugin:n/recommended'
  ],
  "parserOptions": {
    "sourceType": "module"
  },
  "plugins": [
    "vue",
    "vitest",
    "vitest-globals"
  ],
  "env": {
    "vitest-globals/env": true
  },
  "rules": {
    "n/no-extraneous-import": "off",
    "n/no-missing-import": "off",
    "vue/multi-word-component-names": "off"
  }
};
