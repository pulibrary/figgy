const path = require("path")

module.exports = {
  rootDir: path.resolve(__dirname, "../../../"),
  modulePaths: ["<rootDir>"],
  moduleFileExtensions: ["js", "json", "vue"],
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/app/javascript/$1",
  },
  transform: {
    "^.+\\.js$": "<rootDir>/node_modules/babel-jest",
    ".*\\.(vue)$": "<rootDir>/node_modules/vue-jest",
  },
  snapshotSerializers: ["<rootDir>/node_modules/jest-serializer-vue"],
  setupFiles: ["<rootDir>/app/javascript/tests/setup"],
  coverageDirectory: "<rootDir>/app/javascript/tests/coverage",
  testPathIgnorePatterns: [
    "<rootDir>/config/*"
  ],
  collectCoverageFrom: [
    "<rootDir>/app/javascript/components/*.{js,vue}",
  ],
}
