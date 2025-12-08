## Brief
This file helps AI coding agents become productive in the V-Serve / ARTA Feedback Analytics repository. It documents the project's structure, key patterns, build/test commands, services architecture, and integration points.

## High-level architecture (what to know fast)
- **Monorepo layout**: Flutter frontend at `frontend/arta_css/`, backend at `backend/`, docs in `docs/`
- **Primary deliverable**: Flutter web/desktop app for ARTA Client Satisfaction Survey feedback collection and analytics
- **State management**: Provider pattern with ChangeNotifier services
- **Backend**: Firebase/Firestore for data persistence, lightweight Express API under `backend/src/`
- **Bundled SDK**: A Flutter SDK exists at `flutter/` at repo root for version consistency

## Project structure

```
frontend/arta_css/lib/
├── main.dart                    # App entry, routes, providers setup
├── models/
│   ├── survey_data.dart         # SurveyData model for feedback
│   └── user_model.dart          # User/role models
├── screens/
│   ├── admin/
│   │   ├── admin_screens.dart       # Analytics, Feedback Browser, Survey Config, Settings
│   │   └── role_based_dashboard.dart # Main admin dashboard with role-based access
│   ├── user_side/
│   │   ├── landing_page.dart        # Survey entry point
│   │   ├── user_profile.dart        # Part 1: User demographics
│   │   ├── citizen_charter.dart     # Part 2: Citizen's Charter awareness
│   │   ├── sqd.dart                 # Part 3: Service Quality Dimensions
│   │   └── suggestions.dart         # Part 4: Open feedback & thank you
│   └── role_based_login_screen.dart # Admin login
├── services/
│   ├── auth_services.dart           # Authentication & role management
│   ├── feedback_service.dart        # Firestore CRUD for survey data
│   ├── survey_config_service.dart   # Survey section toggles
│   ├── export_service.dart          # CSV/JSON/PDF export
│   ├── offline_queue.dart           # Offline-first submission queue
│   └── qr_code_service.dart         # QR code generation for survey links
└── widgets/
    └── role_based_widget.dart       # Role/permission-based UI visibility
```

## Developer workflows / quick commands (Windows PowerShell)

From repo root, prefer the bundled SDK:

```powershell
# Install dependencies
.\flutter\bin\flutter.bat pub get

# Run in debug mode (web)
.\flutter\bin\flutter.bat run -d chrome

# Run in debug mode (desktop)
.\flutter\bin\flutter.bat run -d windows

# Build for production (web)
.\flutter\bin\flutter.bat build web --release

# Run tests
.\flutter\bin\flutter.bat test

# Static analysis (should pass with 0 issues)
.\flutter\bin\flutter.bat analyze frontend\arta_css
```

## Key patterns & conventions

### State management
- **Provider + ChangeNotifier**: All services extend `ChangeNotifier` and are provided via `MultiProvider` in `main.dart`
- **Consumer widgets**: Use `Consumer<ServiceName>` or `context.watch<ServiceName>()` for reactive UI
- **Service locator**: Access services via `Provider.of<ServiceName>(context)` or `context.read<ServiceName>()`

### Navigation
- Named routes defined in `main.dart`: `/profile`, `/citizenCharter`, `/sqd`, `/suggestions`, `/admin`
- Survey flow: Landing → User Profile → Citizen Charter → SQD → Suggestions → Thank You
- Admin flow: Login → Role-based Dashboard (Analytics, Feedback Browser, Survey Config, Settings)

### UI conventions
- **Widgets**: StatefulWidget + `setState` for local state; Provider for shared state
- **Forms**: `Form` + `GlobalKey<FormState>` for validation
- **Styling**: `GoogleFonts.montserrat()` for headings, `GoogleFonts.poppins()` for body text
- **Colors**: Brand blue `Color(0xFF003366)`, Brand red `brandRed`, use theme colors
- **Responsive**: Check `MediaQuery.of(context).size.width < 900` for mobile layouts

### Export functionality
- `ExportService` provides static methods: `exportCsv()`, `exportJson()`, `exportPdf()`
- Platform-specific implementations via conditional imports (`export_service_web.dart`, `export_service_native.dart`)

### Async context safety
- Always check `if (!mounted) return;` after `await` before using `context`
- Or capture `ScaffoldMessenger.of(context)` before `await` calls

## Dependencies (key packages)

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `firebase_core`, `cloud_firestore` | Backend data persistence |
| `fl_chart` | Analytics charts (radar, bar, pie) |
| `google_fonts` | Typography |
| `shared_preferences` | Local persistence (settings) |
| `csv`, `pdf`, `printing` | Data export |
| `qr_flutter` | QR code generation |
| `window_manager` | Desktop window control (dev dependency) |

## Integration points

### Firebase/Firestore
- Collection: `feedbacks` for survey submissions
- `FeedbackService` handles CRUD with real-time listeners
- `OfflineQueue` buffers submissions when offline

### Backend API (optional)
- Express server at `backend/src/index.js`
- Endpoints: `/ping`, `POST /feedback`, `GET /feedback`, `GET /feedback/:id`
- Frontend can integrate via `http` package (already in pubspec)

### Security notes
- `backend/serviceAccountKey.json` is sensitive — never commit to public repos
- Use `.gitignore` and CI secrets for deployments
- Scripts in `backend/scripts/` perform admin operations — review before running

## Guidance for AI code changes

### Do
- Follow existing patterns (Provider, StatefulWidget, named routes)
- Run `flutter analyze` before committing — should have 0 issues
- Use `withValues(alpha:)` instead of deprecated `withOpacity()`
- Add `mounted` checks after async operations
- Place new services in `lib/services/`, new widgets in `lib/widgets/`

### Don't
- Don't use deprecated APIs without `// ignore:` comment and migration note
- Don't commit sensitive keys or credentials
- Don't modify survey flow without updating route definitions in `main.dart`
- Don't add large architectural changes without explicit request

### When adding features
1. Create service in `lib/services/` if shared state is needed
2. Add Provider in `main.dart` if service is new
3. Create screen in appropriate folder (`admin/` or `user_side/`)
4. Register route in `main.dart` if navigable
5. Update this file if adding significant patterns

## File reference quick links

| What | Where |
|------|-------|
| App entry & routes | `lib/main.dart` |
| Admin dashboard | `lib/screens/admin/role_based_dashboard.dart` |
| Admin screens (tabs) | `lib/screens/admin/admin_screens.dart` |
| Survey screens | `lib/screens/user_side/*.dart` |
| All services | `lib/services/*.dart` |
| Data models | `lib/models/*.dart` |
| Reusable widgets | `lib/widgets/*.dart` |
| Dependencies | `pubspec.yaml` |
| Lint rules | `analysis_options.yaml` |

## Branching & deployment

- **Branch naming**: `feature/<name>`, `fix/<name>`, `chore/<name>`
- **Current branch**: Check with `git branch --show-current`
- **Deploy**: Vercel for web hosting (see `vercel.json` at repo root)
- **Build output**: `frontend/arta_css/build/web/`

---
*Last updated: December 2024. Ping the maintainer if sections become stale.*
