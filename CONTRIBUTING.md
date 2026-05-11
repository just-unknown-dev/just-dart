# Contributing to just_dart

Thank you for your interest in contributing to **just_dart**. We welcome all contributions: bug fixes, features, documentation improvements, and tests.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Submitting a Pull Request](#submitting-a-pull-request)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Convention](#commit-message-convention)
- [License](#license)

---

## Code of Conduct

This project follows our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to abide by its terms. Please report unacceptable behaviour to the maintainers.

---

## Getting Started

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/just-unknown-dev/just-dart.git
   cd just-dart
   ```
3. **Install dependencies:**
   ```bash
   dart pub get
   ```
4. **Run tests and analysis** to make sure everything is green before you start:
   ```bash
   dart test
   dart analyze
   ```

---

## How to Contribute

### Reporting Bugs

Before opening an issue, please:
- Search [existing issues](../../issues) to avoid duplicates.
- Confirm the bug is reproducible on the latest version.

When opening a bug report, include:
- A clear, descriptive title.
- Steps to reproduce the problem.
- Expected vs. actual behavior.
- Dart SDK version (`dart --version`).
- A minimal code sample or link to a reproduction repo if possible.

### Suggesting Features

- Open a [GitHub Discussion](../../discussions) or issue labeled **`enhancement`**.
- Describe the problem your feature solves and how you'd like it to behave.
- Check that the feature aligns with the package scope (shared, framework-agnostic Dart utilities for Just engine packages).

### Submitting a Pull Request

1. Create a topic branch from `main`:
   ```bash
   git checkout -b feat/my-new-feature
   ```
2. Make your changes, following the [Coding Guidelines](#coding-guidelines).
3. Add or update tests for any changed behavior.
4. Ensure all tests pass:
   ```bash
   dart test
   dart analyze
   ```
5. Commit with a [conventional commit message](#commit-message-convention).
6. Push to your fork and open a Pull Request against `main`.
7. Fill in the PR template - describe what changed and why.
8. Address any review feedback promptly.

> **Small PRs are easier to review.** If your change is large, consider opening an issue first to discuss the approach.

---

## Development Setup

| Tool | Minimum Version | Recommended Version |
|------|------------------|---------------------|
| Dart SDK | 3.11.0 | 3.11.x |

`just_dart` is a pure-Dart package with no Flutter runtime APIs.
If you're working from this monorepo, run commands from `packages/just_dart`.

```bash
# Fetch dependencies
dart pub get

# Run tests
dart test

# Analyze
dart analyze
```

---

## Coding Guidelines

- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- All public APIs must have **doc comments** (`///`).
- Prefer `const` constructors wherever possible.
- Do not introduce new dependencies without prior discussion in an issue.
- Keep modules decoupled and reusable across packages.
- Match the existing file and folder structure under `lib/src/`.
- Prefer deterministic behavior and avoid introducing hidden global state.

---

## Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>
```

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Build process, tooling, dependencies |

**Examples:**
```
feat(math): add immutable matrix utility helpers
fix(vector3): correct normalization edge case for zero length
docs(contributing): add development setup section
```

---

## License

By contributing to this repository, you agree that your contributions will be licensed under the [BSD-3-Clause License](LICENSE).
