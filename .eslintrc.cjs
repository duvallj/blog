module.exports = {
  env: {
    node: true,
    es2022: true,
    browser: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended-type-checked",
    "plugin:astro/recommended",
  ],
  plugins: ["@typescript-eslint"],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: true,
    tsConfigRootDir: __dirname,
  },
  overrides: [
    {
      files: ["*.astro"],
      parser: "astro-eslint-parser",
      parserOptions: {
        parser: "@typescript-eslint/parser",
        parserOptions: {
          project: false,
        },
        extraFileExtensions: [".astro"],
      },
    },
  ],
};
