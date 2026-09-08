# Production audit follow-up ? 2026-09-06

The audit branch is integrated with the current main branch, including existing Noto Sans Georgian typography. UI changes preserve API contracts and release versions.

## Corrections

- Shared actions wrap long labels without shrinking the font. Their bounds remain stable while loading, duplicate submissions are disabled, and loading is announced to assistive technology.
- Loading indicators and page transitions respect reduced motion. System text scaling and bottom safe areas are retained.
- Shared fields tolerate optional controllers/country codes, use multiline validation messages and accessible password-toggle labels. Customer focus listeners follow replaced focus nodes.
- The vendor amount formatter retains its previous input behavior; the unrelated audit-branch formatter change was not carried forward.
- The obsolete Flutter counter template test is replaced with application component regressions. The Customer harness uses GetMaterialApp, matching its context-dependent sizing.
- CI pins Flutter 3.41.5 and Java 17, checks main and pull requests, and fails on missing or unsuccessful analyzer, tests or debug compilation. Kotlin 2.2.20 is retained from the audit fix.

## Evidence and limits

- Courier: 33 passing tests, including narrow layouts at 320/390/768 logical pixels and text scale 1/1.5/2, stable loading geometry and duplicate-submit rejection. Existing typography, authentication and application-specific regression suites are included.
- App analyzer: no errors; existing warnings and information messages remain visible in the CI artifact.
- Static inventory: 388 Dart files, 54 screen/page files, 146 widget/component files. `production-audit-inventory.json` lists every scanned file and every risk candidate. Counts are static file categories, not a claim that every screen was visually exercised.
- Device-only plugins, real login/SMS, live payment providers, physical Android/iOS rendering and every authenticated screen are not certified by widget tests. The approved test scope uses local fixtures, never real transactions.
- CI Android compilation is a debug smoke check. No AAB/IPA release, version promotion or installation is authorized by this audit; the AAB hold remains active.
