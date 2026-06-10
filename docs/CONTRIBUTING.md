# Contributing to HealthX

Thank you for contributing to the HealthX platform! Please adhere to the following workflow standards and guidelines to keep the codebase clean, readable, and highly maintainable.

---

## 🌿 Branch Naming Guidelines

Branch names should follow a clear structure based on the type of change:

- `feature/<short-description>` — Introducing a new feature.
- `fix/<short-description>` — Standard bug fixes.
- `hotfix/<short-description>` — Emergency patches for code in production.
- `chore/<short-description>` — Routine workspace tasks, configuration adjustments, or package updates.
- `docs/<short-description>` — Documentation improvements only.

---

## 📝 Commit Conventions

We strictly follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for all repository commit messages.
Format:

```
type(scope): short description in imperative, lower-case style
```

### Supported Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style modifications (formatting, white-space, semi-colons, etc.)
- `refactor`: Code restructuring without modifying functionality
- `test`: Adding or modifying test cases
- `chore`: Build steps, dependency changes, or auxiliary tool modifications

### Examples

- `feat(auth): add google oauth flow and token creation`
- `fix(payment): resolve razorpay webhook signature comparison error`
- `test(user): implement unit test for health metrics syncing`
- `docs(readme): update frontend quick-start instructions`

---

## 🔄 Pull Request Process

1. **Branch Source**: Always branch off the active development branch (`develop` or the target feature branch) — never commit or branch directly from `main`.
2. **Atomic Changes**: Keep your PRs scoped to a single logical change. Small, focused PRs are reviewed and merged much faster.
3. **CI/CD Checks**: Ensure all continuous integration gates pass (linting, compiler checks, and automated tests).
4. **Code Review**: A minimum of one reviewer approval is required before merging.
5. **Merge Strategy**: Squash merge your changes to retain a clean linear history.

---

## ⚙️ Code Quality & Formatting

We enforce strict linting and formatting on pre-commit hooks to keep the styling uniform.

### Backend (Node.js & TypeScript)

- **Linter**: ESLint is configured to identify code quality and type issues.
- **Formatter**: Prettier enforces formatting rules on save.
- **Type Safety**: Maintain strict type declarations — avoid the use of `any` without detailed justification.

```bash
# Check code style and rules
npm run lint

# Auto-fix linting formatting
npm run lint:fix
npm run format
```

### Frontend (Flutter & Dart)

- **Analyzer**: Strict rules are defined in `analysis_options.yaml` to ensure clean Dart usage.
- **Formatter**: Dart's built-in formatter is utilized.

From the `frontend/` directory:

```bash
# Format all Dart files
dart format .

# Run static analysis check
flutter analyze
```

---

## 🧪 Testing Requirements

Every new feature or bug fix must include appropriate unit or integration tests. We aim to keep test coverage above **80%**.

### Running Backend Tests

From the root directory:

```bash
npm test                      # Run all tests
npm run test:watch            # Start test suite in watch mode
```

### Running Frontend Tests

From the `frontend/` directory:

```bash
flutter test                  # Run unit and widget tests
```
