# Localize Person Names usage rules

Rules for LLM coding agents using `localize_person_names` as a dependency. Not exhaustive — see the HexDocs guides for full reference.

## What this package is for

Formatting a person's name the way their locale does, implementing the CLDR [Person Names](https://www.unicode.org/reports/tr35/tr35-personNames.html) specification. It handles given, middle, surname, generational and credential components, and the order, spacing and abbreviation rules that vary by locale.

Built on [`localize`](https://hex.pm/packages/localize).

## Core conventions

* Build a name with `Localize.PersonName.new/1`, which returns `{:ok, name}` or `{:error, exception}`. Never construct the struct literally.

* Components are named fields — `:given_name`, `:surname`, `:informal_given_name`, `:generation`, `:credentials` — not positional.

* A name carries its own `:locale`. That is the locale the *name* belongs to, which is not necessarily the locale you are formatting *for*; both matter, and CLDR's rules use each differently.

## Common idioms

```elixir
{:ok, name} = Localize.PersonName.new(given_name: "José", surname: "Valim", locale: "pt")
```

Format through the CLDR parameters rather than by concatenating: the specification defines `format` (`:long`, `:medium`, `:short`), `formality` (`:formal`, `:informal`), `usage` (`:referring`, `:addressing`, `:monogram`) and `order`.

The package also registers an MF2 function, so a name can be formatted inside a message:

```
{$name :personName format=long formality=formal usage=referring}
```

## Things not to do

* **Never build a display name by string concatenation.** `"#{given} #{surname}"` is wrong in a large fraction of the world's locales — surname-first ordering, no space, particles, and honorific placement all vary. This is the single mistake this package exists to prevent.

* Do not assume a person has exactly two name parts, or that either is mandatory. Many people have one name; many have four.

* Do not assume a "first name" is a given name or that it comes first.

* Do not derive initials or a monogram by taking the first character of each word. Use `usage: :monogram`, which follows the locale's rule.

* Do not store a formatted name and reformat from it later. Store the components and format at render time, for the reader's locale.
