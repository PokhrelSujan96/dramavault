# DramaByte

DramaByte is prepared as a feature-first Flutter application using Cubit and
onion architecture.

## Structure

- `lib/app`: application composition and startup
- `lib/core`: shared configuration, DI, routing, security, network, logging,
  theme, constants, errors, and use-case contracts
- `lib/features`: independent product slices
- `data`: data sources, DTOs, and repository implementations
- `domain`: entities, repository contracts, and use cases
- `presentation`: Cubits, states, pages, and widgets

## Configuration

Runtime configuration uses compile-time values so secrets are not stored in
source files.

```sh
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=https://api.example.com
```

Use an HTTPS API URL. Never place private server credentials, signing files,
service-account files, or privileged API keys in the app bundle.

## Release

Replace Android debug signing with a private release keystore before shipping.
Keep the keystore and its credentials outside version control. Use obfuscation
and split debug information for production builds where appropriate.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
