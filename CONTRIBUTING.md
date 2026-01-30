# Contributing

When contributing to this repository, please first discuss the change you wish to make by creating a new [GitHub issue](https://github.com/affinidi/affinidi-tdk-dart/issues/new).

## Development Requirements

### Prerequisites

- **Dart SDK**: Version 3.8.0 or higher (check with `dart --version`).
- **Flutter SDK**: Required if working on Flutter-specific packages (check with `flutter --version`).
- **Melos**: Version 7.0.0-dev.9 or higher for monorepo management (install with `dart pub global activate melos`).

### Setting Up Your Development Environment

1. Clone the repository:

    ```bash
    git clone git@github.com:affinidi/affinidi-tdk-dart.git
    ```

2. Bootstrap the project using Melos:

   ```bash
   melos bootstrap
   ```

   This command will:
   - Install dependencies for all packages and clients.
   - Link local package dependencies.
   - Generate necessary files.

### Working with the Monorepo

This repository uses [Melos](https://melos.invertase.dev/) to manage the monorepo. Melos provides scripts for common tasks:

- **Fix code issues automatically**: `melos fix` - Applies automated fixes using `dart fix --apply`.
- **Analyse all packages**: `melos analyze` - Runs static analysis across all packages.
- **Run all tests**: `melos test` - Executes Flutter tests, Dart tests, and generates coverage report.
- **Run Flutter tests only**: `melos test-flutter` - Runs tests in Flutter packages with coverage.
- **Run Dart tests only**: `melos test-dart` - Runs tests in Dart-only packages with coverage.
- **Run integration tests**: `melos test-integration` - Executes integration test suite.
- **Generate coverage report**: `melos coverage-report` - Creates comprehensive coverage report.
- **Run a command in a specific package**: `melos exec --scope=<package_name> -- <command>`.

When making changes:

- Use `melos bootstrap` after pulling changes to ensure dependencies are up-to-date.
- Test your changes in the specific package you're modifying.
- If your changes affect multiple packages, test all affected packages.
- Use Melos scripts to ensure consistency across the monorepo.
- Run `melos fix` to automatically apply available fixes before committing.

### Code Quality Expectations

1. **Analysis**: Ensure your code passes static analysis.

   ```bash
   # Analyse all packages in the monorepo
   melos analyze

   # Analyse a specific package
   melos exec --scope=<package_name> -- dart analyze

   # Analyse from a specific directory
   dart analyze
   ```

   Fix all errors and warnings before submitting a PR.

2. **Formatting**: Use Dart's built-in formatter.

   ```bash
   # Format all files in the current directory
   dart format .

   # Format a specific package
   melos exec --scope=<package_name> -- dart format .
   ```

   All code must be formatted using `dart format` with default settings (120 character line length).

3. **Testing**: Ensure your code is covered with tests.

   ```bash
   # Run all tests across the monorepo (Flutter + Dart + coverage report)
   melos test

   # Run tests for Dart packages only (with coverage)
   melos test-dart

   # Run tests for Flutter packages only (with coverage)
   melos test-flutter

   # Run integration tests
   melos test-integration

   # Generate coverage report
   melos coverage-report

   # Run tests for a specific Dart package
   melos exec --scope=<package_name> -- dart run coverage:test_with_coverage

   # Run tests for a specific Flutter package
   melos exec --scope=<package_name> -- flutter test --coverage
   ```

   - Write unit tests for all public APIs.
   - Add integration tests for end-to-end scenarios (NOTE: no mocks/stubs in integration tests).
   - For Flutter packages: write widget tests for UI components.
   - Aim for meaningful test coverage, not just high percentages.
   - Tests should be deterministic and not depend on external services.
   - Coverage is automatically generated when running `melos test-dart` or `melos test-flutter`.

4. **Documentation**: Document all public APIs.

   - Use `///` for documentation comments (DartDoc format).
   - Include code examples for complex APIs.
   - Document parameters, return values, and exceptions.
   - Generate docs locally with `dart doc` to verify formatting.

5. **Linting**: Follow the project's linting rules.

   - The project uses `package:dart_flutter_team_lints`.
   - Check [analysis_options.yaml](analysis_options.yaml) for specific rules.
   - All public members must have API documentation (`public_member_api_docs` rule).

6. **Code Style**:

   - Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.
   - Use meaningful, descriptive names for variables, functions, and classes.
   - Avoid single-letter variable names except for standard cases (e.g., `i` in short loops, `e` for exceptions).
   - Prefer `final` over `var` when variables won't be reassigned.
   - Use `const` constructors and values where possible for performance.
   - Avoid `print()` statements - use proper logging mechanisms instead.

7. **Pull Request Quality**:

   - Ensure all CI/CD pipeline checks pass.
   - Run `melos fix` to apply automated fixes.
   - Run `melos analyze` to check for analysis errors.
   - Run `melos test` to execute all tests with coverage.
   - Remove debugging code, commented-out code, and unnecessary print statements.
   - Keep commits focused and atomic.
   - Write clear commit messages following conventional commit format.
   - Self-review your code before requesting review from others.

8. **Code Clarity**:

   - Code should be self-explanatory; avoid comments that simply restate what the code does.
   - Use comments to explain *why*, not *what*.
   - Extract complex logic into well-named functions.
   - Keep functions focused on a single responsibility.

### Package-Specific Guidelines

When working on packages in the `packages/` directory:

- Update `CHANGELOG.md` with your changes following the established format.
- Ensure `pubspec.yaml` version constraints are appropriate.
- Add examples in the `example/` directory for new features.
- Update the package README with usage instructions.
- Verify that your package builds successfully before submitting.

### Client-Specific Guidelines

When working on API clients in the `clients/` directory:

- Ensure API client methods are properly typed and documented.
- Update client documentation when API endpoints change.
- Test client integration with actual or mocked API responses.
- Follow consistent error handling patterns across all clients.

## Code of Conduct

### Our Pledge

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to make participation in our project and
our community a harassment-free experience for everyone, regardless of age, body
size, disability, ethnicity, gender identity and expression, level of experience,
nationality, personal appearance, race, religion, or sexual identity and
orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment
include:

- Using welcoming and inclusive language.
- Being respectful of differing viewpoints and experiences.
- Gracefully accepting constructive criticism.
- Focusing on what is best for the community.
- Showing empathy towards other community members.
- Avoiding obvious comments about things like code styling and indentation.
  **If you see yourself wanting to do that more than once - open an issue to update the `analysis_options.yaml` rules to address this concern once and for all. Code reviews should be about logic, not formatting or indentation** (use `dart format` for that).

Examples of unacceptable behavior by participants include:

- The use of sexualized language or imagery and unwelcome sexual attention or
  advances.
- Trolling, insulting/derogatory comments, and personal or political attacks.
- Public or private harassment.
- Publishing others' private information, such as a physical or electronic
  address, without explicit permission.
- Other conduct which could reasonably be considered inappropriate in a
  professional setting.
