# TODO

Tracked implementation gaps and release chores. Analysis of the spec's subtler parts and of excluded conformance locales lives in [plans/spec-compliance.md](plans/spec-compliance.md).

## Open

* [ ] **Report the Malayalam sample-name homoglyph upstream** — CLDR 49's `ml` sample names use U+0D6A digit four where the chillu U+0D7C is meant. Details in [guides/conformance.md](guides/conformance.md) section 5.

* [ ] **Align `retain` handling with the reference formatter** — CLDR's formatter keeps non-letter, non-space tokens as separators between initials rather than as list items. No CLDR test exercises the difference yet.

## Blocked

* [ ] **Restore the hex `localize` dependency** — the `cldr-49` branch uses `path: "../localize"` for CLDR 49 locale data. Blocked on Localize 1.4.0, the first release with CLDR 49; 1.3.0 (2026-09-21) is still CLDR 48.2.

* [ ] **Myanmar word-break exclusion** — one `my` conformance test fails because a transliterated given name splits into six words instead of two. Blocked on `unicode_string` dictionary coverage for transliterated Myanmar names.

## Done

* [x] **CLDR 49 alpha2 conformance data** — test data mirrors CLDR exactly, sixteen regional files CLDR retired in v45 removed, Breton added. 2026-09-21.

* [x] **Initial filter matches CLDR's reference formatter** — a word takes an initial when its first code point is a letter; `si`, `km` and `ml` now pass in full. 2026-09-21.

* [x] **Formatting locale switching** — opt-in via `:locale_switching`, with the spec's data-availability check. v1.0.0.

* [x] **Name order parent locale chain** — walks the CLDR parent chain checking both the locale and its `und` variant. v1.0.0.

* [x] **Core/prefix field synthesis** — the spec's eight-row surname, prefix and core truth table. v1.0.0.
