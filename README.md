# Clearline for macOS

Clearline detects a Samsung phone connected over USB, helps its rightful owner check common eligibility requirements, and opens the original carrier’s official unlock path. It deliberately does **not** bypass carrier authorization, blacklists, payment status, or theft protections.

Current release: **1.0.4 (build 5)**. This release embeds Sparkle under `Contents/Frameworks`, includes the required runtime search path, and detects Samsung hardware through both `system_profiler` and IOKit. Optional ADB enrichment supports model and original-carrier hints.

## Build the drag-to-Applications installer

```bash
./scripts/build-dmg.sh
```

This creates `outputs/Clearline-1.0.4.dmg` with the standard macOS Clearline → Applications installation layout.

## Run locally

```bash
swift run Clearline
```

To preview the connected-device interface without hardware:

```bash
CLEARLINE_DEMO_DEVICE=1 swift run Clearline
```

For richer model details, Android Platform Tools (`adb`) may be installed separately and USB debugging enabled on the owner’s phone. Basic Samsung detection does not require it.

## Product brief

- **Audience:** Samsung owners switching carriers or preparing a paid-off phone for resale.
- **Job:** Identify the attached phone and reach the correct official carrier process without guesswork.
- **Emotional target:** Calm confidence at a consequential service-bench moment.
- **Primary journey:** Ownership notice → USB detection → carrier selection → eligibility confirmation → official carrier handoff.
- **Visual concept:** “Service-bench calm”—quiet neutral surfaces, green/blue semantic status, compact technical details, and a single forward action.
- **Trust boundary:** The carrier alone authorizes an unlock. Clearline never asks for carrier credentials and does not transmit device identifiers.

## Privacy and security

Device discovery runs locally with macOS `system_profiler`, with optional read-only Android properties through `adb`. Serial numbers are masked in the interface. No analytics, accounts, remote API, or credential storage are included.

## Signed automatic updates

Clearline integrates Sparkle 2.9.2. A published build requires an HTTPS appcast and the public half of a Sparkle EdDSA key:

```bash
CLEARLINE_UPDATE_FEED_URL="https://updates.example.com/clearline/appcast.xml" \
CLEARLINE_UPDATE_PUBLIC_KEY="BASE64_PUBLIC_KEY" \
CLEARLINE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
./scripts/build-app.sh
```

Use Sparkle's `generate_keys` and `generate_appcast` tools to create and sign releases. Keep the private EdDSA key out of the repository and update server. Public releases should also be Developer ID signed and notarized by Apple.

Changes pushed to `main`, release tags matching `v*`, and manual release runs invoke `.github/workflows/release.yml`. The workflow tests and builds the app, publishes a ZIP for Sparkle and a DMG for people, then commits the signed `appcast.xml` update feed to the default branch. Appcast-only bot commits are ignored so publishing a feed cannot trigger an update loop.
