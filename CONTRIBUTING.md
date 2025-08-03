# Contributing to FlowRecordDisplay

First off, thank you for considering contributing to FlowRecordDisplay! It's people like you that make FlowRecordDisplay such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

- **Use a clear and descriptive title** for the issue to identify the problem.
- **Describe the exact steps which reproduce the problem** in as many details as possible.
- **Provide specific examples to demonstrate the steps**.
- **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
- **Explain which behavior you expected to see instead and why.**
- **Include screenshots and animated GIFs** which show you following the described steps and clearly demonstrate the problem.
- **Include your Salesforce org edition** (e.g., Developer, Enterprise, Unlimited)
- **Include the API version** you're using

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title** for the issue to identify the suggestion.
- **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
- **Provide specific examples to demonstrate the steps**.
- **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
- **Explain why this enhancement would be useful** to most FlowRecordDisplay users.

### Pull Requests

Please follow these steps to have your contribution considered by the maintainers:

1. Follow all instructions in [the template](.github/pull_request_template.md)
2. Follow the [styleguides](#styleguides)
3. After you submit your pull request, verify that all [status checks](https://help.github.com/articles/about-status-checks/) are passing

## Styleguides

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line
- Consider starting the commit message with an applicable emoji:
  - 🎨 `:art:` when improving the format/structure of the code
  - 🐎 `:racehorse:` when improving performance
  - 📝 `:memo:` when writing docs
  - 🐛 `:bug:` when fixing a bug
  - 🔥 `:fire:` when removing code or files
  - ✅ `:white_check_mark:` when adding tests
  - 🔒 `:lock:` when dealing with security
  - ⬆️ `:arrow_up:` when upgrading dependencies
  - ⬇️ `:arrow_down:` when downgrading dependencies

### JavaScript Styleguide

All JavaScript code is linted with [ESLint](https://eslint.org/) and formatted with [Prettier](https://prettier.io/).

- Prefer the object spread operator (`{...anotherObj}`) to `Object.assign()`
- Inline `export`s with expressions whenever possible

  ```javascript
  // Use this:
  export default class ClassName {

  }

  // Instead of:
  class ClassName {

  }
  export default ClassName
  ```

- Place requires in the following order:
  - Built in Node Modules (such as `path`)
  - Built in Salesforce modules (such as `@salesforce/apex`)
  - Local Modules (using relative paths)

### Apex Styleguide

- Follow the [Apex Code Conventions](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_code_conv.htm)
- Use meaningful variable and method names
- Add proper documentation for all public methods
- Write test methods for all code paths (minimum 90% coverage)
- Use `@TestVisible` annotation for private methods that need testing

### LWC Styleguide

- Follow the [LWC Best Practices](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.best_practices)
- Use semantic HTML elements
- Keep components focused and single-purpose
- Use `@api` decorators for public properties
- Document all public properties and methods
- Write Jest tests for all components

## Development Process

### Setting Up Your Development Environment

1. **Fork the repo** and create your branch from `main`.
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/FlowRecordDisplay.git
   cd FlowRecordDisplay
   ```
3. **Install dependencies**:
   ```bash
   npm install
   ```
4. **Create a scratch org** (optional but recommended):
   ```bash
   sf org create scratch -f config/project-scratch-def.json -a myscratch
   ```
5. **Push source to scratch org**:
   ```bash
   sf project push -o myscratch
   ```

### Making Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/my-new-feature
   ```
2. **Make your changes** following the styleguides above
3. **Write/update tests** for your changes
4. **Run tests** to ensure they pass:
   ```bash
   npm test
   sf apex run test --test-level RunLocalTests
   ```
5. **Lint your code**:
   ```bash
   npm run lint
   ```
6. **Format your code**:
   ```bash
   npm run prettier
   ```

### Submitting Changes

1. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Add some feature"
   ```
2. **Push to your fork**:
   ```bash
   git push origin feature/my-new-feature
   ```
3. **Create a Pull Request** from your fork to the main repository

## Testing

### Running JavaScript Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:unit:watch

# Run tests with coverage
npm run test:unit:coverage
```

### Running Apex Tests

```bash
# Run all tests
sf apex run test --test-level RunLocalTests --code-coverage

# Run specific test class
sf apex run test --tests FlexiPageMetadataServiceTest --code-coverage
```

### Writing Tests

- Write tests for all new functionality
- Ensure tests are meaningful and test actual functionality
- Mock external dependencies appropriately
- Aim for at least 90% code coverage

## Documentation

- Update the README.md if you change functionality
- Update CLAUDE.md with any new commands or patterns
- Document complex logic with inline comments
- Add JSDoc comments for all public methods

## Questions?

Feel free to open an issue with your question or contact the maintainers directly.

Thank you for contributing! 🎉
