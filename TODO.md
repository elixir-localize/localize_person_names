# TODO

Tracked spec compliance gaps and implementation improvements.

## Spec Compliance

### Formatting locale switching

**Status:** Implemented (opt-in via `:locale_switching` option)
**Spec section:** [Derive the formatting locale](https://www.unicode.org/reports/tr35/tr35-personNames.html#deriving-the-formatting-locale)

`derive_formatting_locale/3` implements the spec's locale switching algorithm with a proper data availability check (`FormatParser.has_formatting_data?/1`). It is available via the `:locale_switching` option on `to_string/2` and `to_iodata/2`. Default is `false`.

The CLDR test data was generated without locale switching enabled. Both this implementation and the original `cldr_person_names` library disable it by default to match the test expectations. Enabling it (`locale_switching: true`) switches the formatting locale when the name's script differs from the formatting locale's script — for example, a Latin-script name in a Japanese formatter will use Latin-based formatting patterns.

The data availability check works per the spec: a locale is considered to have formatting data when its `nameOrderLocales` lists (`given_first` or `surname_first`) differ from root.

### Name order parent locale chain

**Status:** Implemented
**Spec section:** [Derive the name order](https://www.unicode.org/reports/tr35/tr35-personNames.html#derive-the-name-order)

`determine_name_order/3` walks the CLDR parent locale chain using `Localize.Locale.parent/1`. At each step in the chain, both the locale itself and an `und`-language variant are checked against the `nameOrderLocales` entries. For example, `de-Latn-DE` produces candidates: `de-Latn-DE`, `und-Latn-DE`, `de-Latn`, `und-Latn`, `de`, `und`.

Note: current CLDR data contains only bare language codes in `nameOrderLocales` (e.g., `"ja"`, `"ko"`, `"und"`), not territory-based entries like `"und-JP"`. The chain walk is correct per the spec and future-proofs against CLDR adding territory-based entries, but currently produces the same results as a flat language lookup.

### Core/prefix field synthesis

**Status:** Implemented
**Spec section:** [Handle core and prefix](https://www.unicode.org/reports/tr35/tr35-personNames.html#handle-core-and-prefix)

The spec's 8-row truth table for `{surname}`, `{surname-prefix}`, and `{surname-core}` interaction is fully implemented:

* `{surname-core}` falls back to plain `surname` when no explicit core exists (rows 2–4).
* `{surname}` (plain) combines `prefix + " " + core` when both exist (row 5).
* `{surname-prefix}` is cleared when prefix exists but surname (core/plain) is absent (row 7). This also applies to the combined plain `{surname}` value — `format_surname` suppresses the prefix when no surname exists.

Note: in our data model, the struct has `surname_prefix` and `surname` (no separate core field). Both `"surname"` and `"surname-core"` from CLDR test data map to `:surname`, so core and plain are the same field. This means rows 1–4 (core absent, plain present) and row 5 (plain absent, core present) are handled implicitly by the data model.

## Excluded Locales

### Word-break segmentation (si, my, km, ml)

**Priority:** Medium (depends on `unicode_string`)

61 failures across 4 locales caused by word-break segmentation differences between `unicode_string` and ICU for transliterated foreign names in Sinhala, Myanmar, Khmer, and Malayalam scripts. The dictionary break algorithm works correctly for native-language words, but transliterated names (e.g., "Hamish" in Myanmar script) split at syllable boundaries instead of word boundaries.

**To fix:** Improve dictionary coverage in `unicode_string` for transliterated loanwords, or add heuristics for non-dictionary character sequences in the dictionary break algorithm.

### Test data mismatch (yo_BJ)

**Priority:** Low (upstream CLDR issue)

27 failures where the test data expects initials but the locale format data has no `-initial` modifier. The parent locale `yo` has identical format patterns and its test data correctly expects full names.

**To fix:** Report upstream to CLDR. Either the test data needs updating to match the current format patterns, or the format patterns need `-initial` modifiers added.

### Format selection tiebreaker (es_US, es_MX, es_419)

**Priority:** Low (upstream CLDR spec issue)

28 failures where the spec's format selection algorithm produces a different result than the CLDR test data expects. Documented in detail in `specification_deviances.md`.

**To fix:** Report upstream to CLDR. Either the spec text needs to describe the actual ICU tiebreaker logic, or the test data needs to match the spec's algorithm.
