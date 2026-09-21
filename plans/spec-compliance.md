# Spec compliance notes

**Status:** reference, 2026-09-21

How the three subtler parts of the CLDR person-name specification are
implemented, and why one locale is excluded from the conformance suite.
The tracked work is in [TODO.md](../TODO.md).

## Formatting locale switching

Implemented, opt-in via the `:locale_switching` option. Spec section:
[Derive the formatting locale](https://www.unicode.org/reports/tr35/tr35-personNames.html#deriving-the-formatting-locale).

`derive_formatting_locale/3` implements the spec's locale switching algorithm
with a proper data availability check (`FormatParser.has_formatting_data?/1`).
It is available via the `:locale_switching` option on `to_string/2` and
`to_iodata/2`. Default is `false`.

The CLDR test data was generated without locale switching enabled. Both this
implementation and the original `cldr_person_names` library disable it by
default to match the test expectations. Enabling it (`locale_switching: true`)
switches the formatting locale when the name's script differs from the
formatting locale's script — for example, a Latin-script name in a Japanese
formatter will use Latin-based formatting patterns.

The data availability check works per the spec: a locale is considered to have
formatting data when its `nameOrderLocales` lists (`given_first` or
`surname_first`) differ from root.

## Name order parent locale chain

Implemented. Spec section:
[Derive the name order](https://www.unicode.org/reports/tr35/tr35-personNames.html#derive-the-name-order).

`determine_name_order/3` walks the CLDR parent locale chain using
`Localize.Locale.parent/1`. At each step in the chain, both the locale itself
and an `und`-language variant are checked against the `nameOrderLocales`
entries. For example, `de-Latn-DE` produces candidates: `de-Latn-DE`,
`und-Latn-DE`, `de-Latn`, `und-Latn`, `de`, `und`.

Note: current CLDR data contains only bare language codes in
`nameOrderLocales` (e.g., `"ja"`, `"ko"`, `"und"`), not territory-based
entries like `"und-JP"`. The chain walk is correct per the spec and
future-proofs against CLDR adding territory-based entries, but currently
produces the same results as a flat language lookup.

## Core/prefix field synthesis

Implemented. Spec section:
[Handle core and prefix](https://www.unicode.org/reports/tr35/tr35-personNames.html#handle-core-and-prefix).

The spec's 8-row truth table for `{surname}`, `{surname-prefix}`, and
`{surname-core}` interaction is fully implemented:

* `{surname-core}` falls back to plain `surname` when no explicit core exists
  (rows 2–4).
* `{surname}` (plain) combines `prefix + " " + core` when both exist (row 5).
* `{surname-prefix}` is cleared when prefix exists but surname (core/plain) is
  absent (row 7). This also applies to the combined plain `{surname}` value —
  `format_surname` suppresses the prefix when no surname exists.

Note: in our data model, the struct has `surname_prefix` and `surname` (no
separate core field). Both `"surname"` and `"surname-core"` from CLDR test
data map to `:surname`, so core and plain are the same field. This means rows
1–4 (core absent, plain present) and row 5 (plain absent, core present) are
handled implicitly by the data model.

## Excluded locales

The conformance suite mirrors CLDR's `common/testData/personNameTest`
directory exactly. As of the CLDR 49 alpha2 data one locale is excluded.

### Word-break segmentation (my)

One failure (`my.txt` line 756, givenFirst/short/referring/informal) where
`unicode_string`'s dictionary word break splits the transliterated Myanmar
given name `အာဒါ ကွန်နီလီယာ` into six words where ICU finds two, so the short
format produces extra initials.

To fix: improve dictionary coverage in `unicode_string` for transliterated
loanwords, or add heuristics for non-dictionary character sequences in the
dictionary break algorithm.

### Previously excluded

* `si`, `km`, `ml` were excluded as word-break failures. They were not: the
  initial filter required every character after the first to be a letter,
  punctuation or extend character, which dropped Sinhala words carrying a
  zero-width joiner and the Malayalam sample name containing a digit
  homoglyph. Aligning the filter with CLDR's reference formatter (a word takes
  an initial when its first code point is a letter) fixed all three.

* `yo_BJ`, `es_US`, `es_MX`, `es_419` were regional test files CLDR retired
  in CLDR 45. This repository carried stale 2023 copies until the CLDR 49
  update. The analysis stays in
  [guides/conformance.md](../guides/conformance.md) as history.
