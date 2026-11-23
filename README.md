# Zombie Nightfall

A standalone, offline HTML5 Canvas2D top-down zombie survival game. The complete game is `index.html`; it has no runtime asset, font, library, or network dependencies.

## Play locally
Open `index.html` in a modern browser. Desktop: WASD/arrows move, mouse aim and hold left button to fire, Space dash, R reload, 1–3 switch weapon, P/Escape pause. Touch: left stick moves; touch/drag on the right aims and fires; on-screen buttons reload, dash, switch weapon, and pause. Audio starts after interaction and can be toggled.

## Android debug APK with GitHub Actions
This repository ZIP has project files at its root. Push the extracted contents to the root of a GitHub repository, then open **Actions → Build Android debug APK → Run workflow** (or push to `main`/`master`). The workflow uses Node 24 and Java 21, installs Android API 36/build-tools 36.0.0, copies the offline game to `www/index.html`, adds/syncs Capacitor Android, and builds the debug APK. Download the `zombie-nightfall-debug-apk` artifact from the completed workflow run.

APK output is checked at `android/app/build/outputs/apk/debug/app-debug.apk` before upload. This repository contains no APK or signing keystore: CI produces an unsigned-for-release, debug-signed APK suitable for testing, not a Play Store release.

## Contents
`index.html`, `package.json`, `capacitor.config.json`, `README.md`, `.gitignore`, and `.github/workflows/build-android.yml` are all at the repository root/tree as listed.
