# Landing page + privacy policy site — design

**Date:** 2026-09-12
**Status:** approved

## Purpose

TFI Bagundaali needs a public web presence before Play Store submission, primarily to host a URL for the privacy policy (required by Play Console's data-safety and account-deletion policy forms). A small marketing landing page rides along on the same deploy.

## Scope

New `web/` folder at repo root, deployed as a standalone static site on Vercel (root directory set to `web/` in the Vercel project). No build step, no framework — plain HTML/CSS.

Two pages:

- `web/index.html` — landing page
  - Hero: app icon, name, one-line tagline, "Coming soon on Google Play" badge (no link yet — app isn't published)
  - Features section: solo speed round, 2-player pass-and-play, online multiplayer, Telugu-cinema sticker theme (copy adapted from [README.md](../../../README.md) / pubspec description)
  - Footer: link to `privacy.html`, contact email (priyathamkatta@gmail.com)
- `web/privacy.html` — styled HTML version of [PRIVACY_POLICY.md](../../../PRIVACY_POLICY.md)
  - Content duplicated from the markdown source, not generated — two copies to keep in sync by hand. Acceptable given how rarely a privacy policy changes; not worth a build step for.

`web/styles.css` — shared stylesheet reusing the app's palette from [theme.dart](../../../lib/core/theme.dart): ivory `#FAF7ED`, sand `#EADCC8`, charcoal `#1A1A1A`, cinema red `#C63B2B`, mustard `#F4C542`, teal `#2E6F73`.

`web/assets/` — app launcher icon copied in for the hero; optionally one sticker asset from `assets/stickers/` for visual flavor.

## Out of scope

- No JS framework, no CMS, no build tooling
- No real screenshots (app not shipped yet — add later once available)
- No live Play Store link (swap in once the listing exists)
- Actual Vercel project creation/connection — that's a manual step for the user; this spec covers only the file contents to deploy

## Testing

Static site — open `web/index.html` and `web/privacy.html` directly in a browser to check layout, and check on a mobile viewport width.
