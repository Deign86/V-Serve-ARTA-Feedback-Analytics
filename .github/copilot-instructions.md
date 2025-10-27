## Brief
This file helps AI coding agents become productive in the V-Serve / ARTA Feedback Analytics repository by calling out the project's structure, important patterns, build/test commands, and integration points discovered in the codebase.

## High-level architecture (what to know fast)
- Monorepo layout with a Flutter frontend at `frontend/arta_css/` and an (empty) `backend/` folder. Docs live in `docs/`.
- The Flutter app is the primary deliverable in this repo: UI, routes and screens are under `frontend/arta_css/lib/` (e.g. `lib/main.dart`, `lib/screens/user_side/user_profile.dart`).
- A bundled Flutter SDK exists at `flutter/` at repo root; CI or local dev may prefer using that to ensure consistent tool versions.

## Why things are organized this way
- The repo keeps a self-contained Flutter app (desktop-friendly) with desktop window control via `window_manager` (see `lib/main.dart`). There is no obvious frontend HTTP client in the Flutter code — integration with backend services is not present in the frontend source tree and appears to be handled elsewhere or not yet implemented.

## Developer workflows / quick commands (Windows PowerShell)
Prefer the included SDK to avoid version drift. From repo root:

```powershell
# fetch packages
.\flutter\bin\flutter.bat pub get

# run on connected device / desktop (debug)
.\flutter\bin\flutter.bat run

# run unit/widget tests
.\flutter\bin\flutter.bat test

# static analysis (uses analysis_options.yaml at repo root)
.\flutter\bin\flutter.bat analyze frontend\arta_css
```

If you use a system-wide Flutter install, replace the path to the bundled `flutter` with `flutter` on your PATH.

## Project-specific conventions & patterns
- Routing: Named routes are defined in `frontend/arta_css/lib/main.dart`. Examples: `/profile` -> `UserProfileScreen`, `/citizenCharter`, `/sqd`, `/suggestions`.
- UI patterns: screens are mostly StatefulWidgets using `setState` and `Form`+`GlobalKey` for validation (see `frontend/arta_css/lib/screens/user_side/user_profile.dart`). Use Navigator.pushNamed for navigation.
- Desktop behavior: `window_manager` is initialized conditionally for Desktop platforms in `main.dart` — treat desktop-specific behavior (fixed window size, center) as intentional.
- Assets: static assets live in `frontend/arta_css/assets/` and are included via `pubspec.yaml` (top-level `assets:` entry). Use asset paths as in the code (e.g. `assets/city_bg2.png`, `assets/city_logo.png`).
- Fonts: Google Fonts are used via the `google_fonts` package instead of bundling custom fonts.
- Linting: `analysis_options.yaml` is present at repo root and in `frontend/arta_css/` — follow those rules for style and lints.

## Integration points & missing pieces (for an agent to flag)
- Frontend <> Backend integration: The frontend expects a backend API for feedback ingestion/retrieval. A lightweight Express backend lives under `backend/src/` with endpoints such as `/ping`, `POST /feedback`, `GET /feedback` and `GET /feedback/:id`.
  - The frontend code currently does not centralize HTTP clients; add a small client wrapper under `frontend/arta_css/lib/services/` when integrating a backend (see `config.dart` for `BASE_API_URL` usage). Prefer dependency injection or a single service to manage retries, timeouts, and error handling.
  - `frontend/arta_css/lib/services/offline_queue.dart` exists and currently writes directly to Firestore. Consider adapting it to POST to the backend instead of direct Firestore writes for better security and centralized validation.
  - Backend artifacts and security: the repo contains backend utility scripts and a service account file under `backend/` (e.g., `serviceAccountKey.json`, scripts under `backend/scripts/`). These may be sensitive; avoid committing long-lived service account keys to public branches. Use `git rm --cached` and `.gitignore` for secrets and provide CI secrets for deployments.
  - Scripts status: Some backend scripts are archived/inert to avoid accidental execution (they may be named like `admin_write_test.js`, `fetch_firestore_rules.js`). Inspect `backend/scripts/` before running — they perform admin operations against Firestore.

## Examples to reference (concrete snippets)
- Navigation and routing: `frontend/arta_css/lib/main.dart` — named routes map.
- Form & UI pattern: `frontend/arta_css/lib/screens/user_side/user_profile.dart` — uses `Form`, `GlobalKey`, `ChoiceChip`, `showDatePicker`, and `Navigator.pushNamed('/citizenCharter')`.
- Pubspec + plugins: `frontend/arta_css/pubspec.yaml` shows `window_manager` and `google_fonts` as explicit dependencies.

## Guidance for AI code changes
- Be minimal and repo-consistent: follow `analysis_options.yaml` and existing widget patterns (StatefulWidget + setState). Avoid large architectural rewrites unless requested.
- When adding networking, add the dependency to `frontend/arta_css/pubspec.yaml` (for example `http` or `dio`), add a small client wrapper under `lib/services/` and wire it via dependency injection or a single top-level service locator. Document created environment variables or constants in `README.md` or `docs/`.
- For any backend integration changes, create a short TODO in code and add a short note to the PR description referencing the `backend-integration` branch.

## Where to look next
- UI & routes: `frontend/arta_css/lib/main.dart` and `frontend/arta_css/lib/screens/`.
- Assets and dependency list: `frontend/arta_css/pubspec.yaml` and `frontend/arta_css/assets/`.
- Lint rules: root `analysis_options.yaml` and `frontend/arta_css/analysis_options.yaml`.
- Branching policy: `docs/README.md` — use feature branches with semantic names (e.g. `feature/login`).

---
If any of the above points are incomplete or you'd like me to include more examples (e.g., service skeletons, a small HTTP client, or VS Code launch configs), tell me which area to expand and I'll update this file.
