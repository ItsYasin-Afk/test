# Zombie Survival — Godot 4.4.1

A procedural 2D top-down survival prototype targeting Android portrait devices.

## Included

- Dual virtual sticks (movement + aim/fire direction), keyboard/mouse fallback.
- Auto-aim assistance, four selectable weapon profiles, reload timers and ammunition.
- Runner, Normal, Heavy and every-fifth-wave Boss enemies.
- Wave progression, score, four upgrade choices, health and temporary damage immunity.
- Procedural arena, actors, projectiles and impact particles.
- Android ARM64 debug export preset and GitHub Actions artifact workflow.

## Build locally

1. Install Godot **4.4.1** and its matching Android export templates.
2. Install OpenJDK 17 and Android SDK; configure their paths in Godot Editor Settings → Export → Android.
3. Open this folder in Godot.
4. Run the project, or export using the `Android` preset.

The preset points to `debug.keystore` with the standard Android debug alias/password. For a local export, either place a debug keystore at that path or configure the debug keystore in Editor Settings.

## Build with GitHub Actions

1. Create a GitHub repository and push this folder to `main`.
2. Open **Actions** → **Build Android Debug APK**.
3. Wait for the workflow to finish.
4. Download the `ZombieSurvival-Android-debug` artifact.

The workflow uses `barichello/godot-ci:4.4.1`, sets SDK environment variables, ensures a debug keystore exists, limits export time, and uploads the APK.

## Controls

- Desktop: WASD / arrow keys to move, mouse button to fire toward the current aim direction, Q to switch weapon, R to reload.
- Android: left stick to move, right stick to aim and fire, NEXT and RELOAD buttons.

## Important limitations

This is a complete **playable starter prototype**, not a commercially production-ready release. It intentionally uses simple procedural visuals and basic pursuit AI. Before publishing, test on real Android devices, tune touch hit areas and safe-area layout, add audio/art, validate all export settings against your installed SDK, add save data and accessibility options, and perform performance and gameplay QA.

The generated debug APK is for testing. Do not use the debug keystore for a Play Store release; create and protect a separate release signing key.
