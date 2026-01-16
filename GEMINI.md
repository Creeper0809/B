# Gemini Customization

This file is used to provide Gemini with specific instructions, context, or guidelines for interacting with this project.

## Instructions:
- Adhere to the existing code style and conventions found in the `B/v3_15/src` directory.
- Prioritize clear, readable code over overly clever or concise solutions.
- When adding new features, include corresponding tests in the `B/v3_15/test` directory.
- If you need to make changes to build scripts or configuration files, please describe the changes before applying them.

## Project Context:
- The project is a compiler written in a custom language.
- The `B/v3_15` directory contains the latest version of the compiler's source code.
- The `basm` and `v2c` binaries in the `bin` directory are related to the project but are older versions or tools.

## Example:
If you need to define specific linting rules, you could add them here:
```yaml
lint_rules:
  - no-unused-vars: error
  - indent: [error, 4]
```
