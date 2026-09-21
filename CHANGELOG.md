# Changelog

All notable changes to this project will be documented in this file. This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

* Conformance test data is CLDR 49 alpha2 and mirrors `common/testData/personNameTest` exactly: sixteen regional files CLDR retired in CLDR 45 are removed and `br` is added. Only `my` is excluded now, for one word-break failure.

### Fixed

* Initial generation takes a word's initial whenever its first code point is a letter, as CLDR's reference formatter does. Sinhala words with a zero-width joiner and Malayalam words containing a digit were dropped, which is why `si`, `km` and `ml` were excluded.

* Dead documentation links: the README and the cultural naming conventions guide pointed at a `v0.1.0` tag that was never published and at `specification_deviances.md`, which became `guides/conformance.md`. Closes [#1](https://github.com/elixir-localize/localize_person_names/issues/1).

## [1.0.0] - 2026-07-31

### Added

* `Localize.PersonName.Ecto.Map.Type` stores a name as `jsonb`, keeping its parts separate so a stored name still renders per locale, format and order rather than being frozen as one string.

* The stored form converts the two non-string parts: `:preferred_order` as its string form, and `:locale` as its canonical language tag, loaded back through `Localize.validate_locale/1`. Neither conversion interns an atom, so form input cannot grow the atom table.

### Changed

* `ecto` is an optional dependency; the Ecto type compiles only when it is present.

* The `:personName` MF2 function reports a failure as `{:formatter_failed, message}`, following the Localize 1.0 message interpreter. Code matching on the previous bare string needs updating.

### Fixed

* Formatting no longer calls `Localize.Locale.to_locale_id/1`, which Localize 1.0 removed.

## [0.1.0] - 2026-04-15

### Highlights

Initial release of `localize_person_names`, providing localized name formatting following the CLDR Person Names specification.


See the [README](README.md) for full documentation and usage examples.