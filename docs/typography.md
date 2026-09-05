# MILI typography

## Faces and scope

Application-owned text uses the bundled BPG SSP Crystal family supplied in `BPG_SSP_Crystal.zip` (SHA-256 `17625a809627336d12c54cb153607a39733464c17a68271f1d0fb4069b370846`). Regular, Bold, Italic and Bold Italic are registered separately for both the ordinary and CAPS families. The 2019 regular/bold pair is used because its vertical metrics align with the CAPS faces; all BPG TTFs are unchanged source files.

The archive has no Cyrillic glyphs. The user explicitly approved a **Cyrillic-only bundled fallback**. MILI Cyrillic is a subset of Roboto from the pinned Google Fonts source recorded in `font-manifest.json`; its cmap is restricted to U+0400–052F, U+2DE0–2DFF and U+A640–A69F. It cannot replace Georgian or Latin glyphs. Its Apache license is included beside the files. Web faces use WOFF2; Flutter uses TTF. No font CDN or runtime font download is required for these faces.

Material/Cupertino icon fonts and native emoji rendering remain independent: they draw pictograms, not an alternate UI text face. OS interfaces, third-party hosted payment content, map tile imagery and raster brand artwork are outside the application text renderer.

## Usage policy

| Role | Family and treatment |
|---|---|
| Page titles, short section headings, category labels | CAPS, usually Bold; complete headings/words, never Georgian title casing |
| Product/store names, descriptions, chat messages, forms | Ordinary family; preserve authored text and case |
| Prices, totals, primary actions, selected or important labels | Ordinary Bold |
| Explicit short emphasis, citations and existing rich-text `<em>` or markdown emphasis | Genuine Italic, or Bold Italic when both are intended |
| Long body copy, hints, errors and navigation instructions | Ordinary; avoid long CAPS or italic passages |

Only display text is capitalized. Identifiers, URLs, credentials, API values and stored product names are unchanged. Flutter app-bar/section-title capitalization retains the original text as its semantics label. Web product/store display helpers preserve authored case; category labels keep their CAPS behavior.

Flutter's `MiliTypography` defines global families/fallbacks and semantic styles. Legacy `robotoRegular`/`robotoBold` variable names remain compatible with their callers but resolve to BPG; old Roboto and auth-only text font assets are removed. Only genuine 400 and 700 faces exist, so legacy medium/semibold/black aliases resolve to Regular/Bold without a separate synthetic face.

Web family names are centralized in `src/theme/typography.js`. All font faces are local, the primary faces are preloaded, and `font-synthesis: none` prevents fabricated bold/italic. Existing Google/Rubik font links and Quicksand/monospace/system font declarations were removed. The shared Google Maps loader suppresses its own Google Fonts injection, and map UI text uses the local family. Body line-height uses scalable ratios instead of the old sub-font-size fixed line heights.

## Validation and boundaries

Font manifests record source and output SHA-256 values. Tests verify the asset hashes, preservation of names, local-only declarations, real Cyrillic fallback, scaled/light/dark Flutter rendering, forms and app bars. Browser verification records the actual rendered font family/PostScript face rather than relying only on computed CSS. The current en/ka/ru application translation letters and currency symbols are covered by BPG plus the permitted Cyrillic subset. Existing emoji remain native pictograms.

No AAB, APK or iOS build is part of this typography change. The user placed AAB work on hold pending a separate command. The older app-local Customer AAB predates these font changes and must not be promoted as the typography release.

The previously identified unrelated `test/widget_test.dart` Counter template in each app is excluded from the regression run; other available regression tests are run. Physical-device and third-party hosted UI behavior cannot be proven by widget/browser fixtures alone.

## Sources informing the policy

- [Flutter community: explicit weight/style registration](https://www.reddit.com/r/flutterhelp/comments/oyb6tj)
- [Flutter community: bundled fonts and unexpected font downloads](https://www.reddit.com/r/flutterhelp/comments/1pj26in/flutter_web_force_app_to_use_only_bundled_fonts/)
- [Typography community: distinguish body emphasis from attention-grabbing bold](https://www.reddit.com/r/typography/comments/1h7ee2m/504_rules_of_type_my_professor_made_this/)
- [UX discussion: All Caps versus Bold](https://ux.stackexchange.com/questions/110132/all-caps-vs-bold)
- [UX discussion: italic text and readability](https://ux.stackexchange.com/questions/62742/are-italics-on-the-web-bad-for-accessibility)
- [Georgian text guidance: Mtavruli is whole-word/all-caps typography](https://www.w3.org/TR/geor-lreq/)
- [Flutter custom-font registration](https://docs.flutter.dev/cookbook/design/fonts)

Community opinions inform the design; they do not establish a universally best design or replace validation in MILI's layouts.
