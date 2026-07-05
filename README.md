# Localize Person Names

Locale-aware person name formatting built on the Unicode CLDR [Person Names](https://www.unicode.org/reports/tr35/tr35-personNames.html) specification and the [Localize](https://hexdocs.pm/localize/) library.

## Installation

```elixir
def deps do
  [
    {:localize_person_names, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
# Create a person name
{:ok, name} = Localize.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")

# Format with defaults (locale-driven length, formality, addressing usage)
Localize.PersonName.to_string(name)
#=> {:ok, "José"}

# Format with explicit options
Localize.PersonName.to_string(name, format: :long, formality: :formal, usage: :referring)
#=> {:ok, "Mr. José Valim Ph.D."}

# Format in a different locale
Localize.PersonName.to_string(name, locale: :ja)
#=> {:ok, "バリム・ジョゼ"}
```

### Options

* `:format` — `:short`, `:medium`, or `:long`. Controls how many name parts appear. Default is derived from the formatting locale.

* `:usage` — `:addressing` (speaking to someone), `:referring` (speaking about someone), or `:monogram` (abbreviated, e.g., initials). Default is `:addressing`.

* `:formality` — `:formal` or `:informal`. Controls whether titles, credentials, and full names are used versus nicknames and abbreviated forms. Default is derived from the formatting locale.

* `:order` — `:given_first`, `:surname_first`, or `:sorting`. Default is derived from the person name's locale and the formatting locale.

* `:locale` — The formatting locale. Default is `Localize.get_locale()`.

### Person Name Fields

| Field | Description | Example |
|-------|-------------|---------|
| `given_name` | Primary given name (required) | "José" |
| `surname` | Family name | "Valim" |
| `title` | Honorific | "Mr.", "Dr." |
| `other_given_names` | Middle name(s) or patronymic | "Carlos" |
| `informal_given_name` | Nickname or casual form | "Zé" |
| `surname_prefix` | Tussenvoegsel / particle | "von", "de" |
| `other_surnames` | Secondary/maternal surname | "González" |
| `generation` | Generation marker | "Jr.", "III" |
| `credentials` | Accreditation | "Ph.D.", "MD" |
| `preferred_order` | Explicit ordering preference | `:given_first`, `:surname_first` |
| `locale` | Locale of the name data | `"pt"`, `Localize.LanguageTag.t()` |

## Integrating existing structs

Any struct can participate in person name formatting, either through the `Localize.PersonName.Convertible` protocol or through the `Localize.PersonName` behaviour. See [Integrating existing name structs](https://github.com/elixir-localize/localize_person_names/blob/main/guides/integrating_existing_structs.md) for the full comparison and recommendations.

## MF2 message formatting

A `:personName` MF2 function is provided as `Localize.PersonName.MF2` for use with [Localize.Message](https://hexdocs.pm/localize/Localize.Message.html). See [Using Localize.PersonName with Localize.Message](https://github.com/elixir-localize/localize_person_names/blob/main/guides/message_formatting.md) for formal and informal worked examples.

## Guides

* [Integrating existing name structs](https://github.com/elixir-localize/localize_person_names/blob/main/guides/integrating_existing_structs.md) — two ways to wire existing domain structs (`%User{}`, `%Customer{}`, etc.) into the formatter: the `Localize.PersonName.Convertible` protocol (recommended) and the `Localize.PersonName` behaviour.

* [Using Localize.PersonName with Localize.Message](https://github.com/elixir-localize/localize_person_names/blob/main/guides/message_formatting.md) — integrating person name formatting into MF2 message templates via a custom function, with formal and informal worked examples.

## Conformance

### Test coverage

39,731 tests across 120 CLDR locales, 0 failures. Test data is from the CLDR person name test suite, which provides format conformance tests for each locale covering all combinations of order, length, usage, and formality.

### Locale coverage

Of the 128 CLDR locale test data files available, 120 pass all tests. The 8 excluded locales and their reasons are documented in the conformance guide and summarised below:

| Locales | Failures | Cause |
|---------|----------|-------|
| si, my, km, ml | 61 | Word-break segmentation differences for transliterated foreign names in these scripts. |
| yo_BJ | 27 | CLDR test data expects initials but locale format data has no `-initial` modifier. |
| es_US, es_MX, es_419 | 28 | Format selection tiebreaker discrepancy between spec text and CLDR test data. |

### Specification deviances

See [CLDR Specification Conformance](https://github.com/elixir-localize/localize_person_names/blob/main/guides/conformance.md) for detailed analysis of four issues:

1. **Format selection tiebreaker** (es_US, es_MX, es_419) — Spec says "fewest unpopulated fields" but test data expects different selection.

2. **Empty field removal with grouping punctuation** (cs, sk) — Fixed in this implementation by detecting parentheses/brackets during literal coalescing.

3. **Initial derivation requires UAX #29 grapheme clusters** — Spec says "first grapheme cluster" without specifying UAX #29. This implementation uses UAX #29 extended grapheme clusters via `unicode_string`, which is required for correct initials in Brahmic scripts.

4. **Test data / locale data mismatch** (yo_BJ) — Test expectations don't match the current format patterns.

## Known Limitations

See [TODO.md](https://github.com/elixir-localize/localize_person_names/blob/main/TODO.md) for tracked implementation gaps.
