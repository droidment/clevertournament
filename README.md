# clevertournament

A new Flutter project.

## Deployment (Firebase Hosting via GitHub Actions)

This repo is configured to build Flutter Web and deploy to Firebase Hosting on:
- Pull Requests to `main`: preview channel deployments (commented in the PR)
- Pushes to `main`: production (live) deployment

### Setup

1. Create or use an existing Firebase project in the Firebase console.
2. In this GitHub repository, add the following:
   - Repository secret `FIREBASE_SERVICE_ACCOUNT`: contents of a Firebase Service Account JSON with Hosting Admin permissions (Project → IAM → Service Accounts → Create Key).
   - Repository variable `FIREBASE_PROJECT_ID`: your Firebase Project ID (e.g., `my-project`).

Tip: You can scope secrets/variables at the organization level if preferred.

### How it works

The workflow defined in `.github/workflows/firebase-hosting.yml`:
- Sets up Flutter `stable` and builds the web app: `flutter build web --release`
- Uses `firebase.json` with `public: build/web`
- Deploys using `FirebaseExtended/action-hosting-deploy@v0`

### Local build

```bash
flutter pub get
flutter build web --release
```

The built site is in `build/web`.


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
