# MILI typography — Noto Sans Georgian

## Default family

Application-owned text uses **Noto Sans Georgian v2.005**, bundled from the user-provided `NotoSansGeorgian-v2.005.zip`. Archive SHA-256: `10e85011008108308e6feab0408242acb07804da61ede3d3ff236461ae07ab1b`.

Use the archive's `googlefonts/ttf` full-coverage files, which contain Georgian, Mtavruli uppercase, Latin and the lari sign. The Georgian-only/unhinted subsets are not used. All nine genuine normal-width weights (100–900) are registered explicitly. Source TTFs are unmodified; web assets are WOFF2 conversions. The SIL OFL license and author/contributor notices are included.

The archive has no Cyrillic. Preserve the user's previously approved **Cyrillic-only bundled fallback**, `MILI Cyrillic`, whose cmap is restricted to U+0400–052F, U+2DE0–2DFF and U+A640–A69F. It cannot substitute Georgian or Latin text. Its original source, hashes and Apache license remain beside the assets.

The archive has no italic master. Existing semantic italic/emphasis styling uses a renderer-generated slant of the Noto face where supported; it does not load a second Georgian/Latin family. Web synthesis permits style only, never synthetic weight. The Cyrillic fallback retains its genuine italic faces.

## Roles

| Text role | Treatment |
|---|---|
| Short page/section headings and category labels | Noto Bold; Unicode uppercase where the UI opts into CAPS |
| Product/store names, forms, descriptions and chat | Noto normal letterforms; preserve authored case |
| Prices, totals and primary actions | Medium, SemiBold or Bold as already selected by the UI |
| Short existing emphasis and citations | Preserve semantic italic emphasis; no long italic body passages |

Mtavruli/CAPS uses uppercase characters in the same Noto family; no separate CAPS face is needed. Display transformations retain original semantics labels in Flutter. Identifiers, URLs, authentication, amounts, API payloads and stored values are not changed by typography.

`MiliTypography` defines Flutter families and fallback. Existing style-variable identifiers remain compatible with their callers but now use Noto; medium, semibold and black aliases use their genuine 500, 600 and 900 weights. Web family names are centralized in `src/theme/typography.js`. All text font files are local, primary faces are preloaded, and Google Maps font injection remains disabled.

Icon fonts, native emoji, operating-system interfaces, map tile imagery, raster branding and third-party hosted payment pages remain independent of the application's text renderer.

## Verification and release boundaries

The adjacent `font-manifest.json` records all source/output hashes. Regression tests cover text shaping, Cyrillic fallback, light/dark appearances, scaled text, forms and app bars. Browser checks inspect the actual rendered family and face, not just the declared CSS.

AAB/APK/iOS builds remain on hold until a separate explicit user command. Older app-local and canonical release artifacts predate this typography and cannot represent the updated source. The known unrelated Counter template test in each Flutter repo is excluded from the regression run; other available tests are run.

Live deployment preserves production-only footer layout and environment configuration, backs up old source/build/assets, verifies new fonts over HTTP, and removes retired font files from the active site. Historical Git commits and rollback backups are intentionally retained.
