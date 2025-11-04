# Backend (Firestore) integration

This folder contains a minimal Node/Express backend scaffold that connects to Firestore using the Firebase Admin SDK.

What I added
- `package.json` - scripts: `npm run start`, `npm run dev` (nodemon)
- `.gitignore` - ignores `node_modules/` and `serviceAccountKey.json`
- `src/firestore.js` - initializes Firebase Admin; prefers `backend/serviceAccountKey.json` but falls back to Application Default Credentials (ADC)
- `src/index.js` - minimal Express API with endpoints:
  - `GET /ping` - health check
  - `POST /feedback` - create feedback document
  - `GET /feedback/:id` - fetch a feedback
  - `GET /feedback?limit=20` - list recent feedbacks

Quick start (Windows PowerShell)

1. Install dependencies

```powershell
cd backend
npm install
```

2. Connect the backend to your Firebase project

Recommended (service account):

- Go to Firebase Console → Project Settings → Service accounts → Generate new private key
- Save the downloaded JSON file as `backend/serviceAccountKey.json` (this file is ignored by git via `.gitignore`).

Alternative (Application Default Credentials):

- Install Google Cloud SDK and run:

```powershell
gcloud auth application-default login
```

Environment (.env)

You can also store configuration in a `.env` file in `backend/`. A `.env.example` is provided. Example keys:

- `SERVICE_ACCOUNT_PATH` — path to the service account JSON (relative or absolute). If not set, the server looks for `backend/serviceAccountKey.json`.
- `PORT` — port the server listens on (default 5000).

Copy `.env.example` to `.env` and update values before running in development.

3. (Optional) Use Firebase CLI to set the active project

```powershell
npx firebase login
npx firebase projects:list
npx firebase use --add v-serve-arta-feedback-survey
```

Note: the Firebase CLI helps manage active project context and deploy functions/hosting if you later initialize `firebase init`.

4. Run the server

```powershell
# dev (auto restart)
npm run dev

# production
npm start
```

Try the API (examples):

```powershell
# health
curl http://localhost:5000/ping

# create feedback
curl -X POST http://localhost:5000/feedback -H "Content-Type: application/json" -d '{"name":"John","rating":5,"comment":"Great service"}'

# list
curl http://localhost:5000/feedback
```

Security notes
- Do NOT commit `serviceAccountKey.json` to version control. Keep it secret.
- In production, prefer environment-based secrets (e.g., set `GOOGLE_APPLICATION_CREDENTIALS` to a secure path or use a secrets manager).

Next steps (suggested)
- Add input validation and better error handling for the API.
- Add CORS if frontend will call the backend directly from a browser.
- Optionally scaffold Cloud Functions (`firebase init functions`) if you want serverless deployment with tight Firebase integration.
