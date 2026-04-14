# CLDR Specification Conformance

THe implementation fully meets the [TR35-8 PersonNames](https://www.unicode.org/reports/tr35/tr35-personNames.html) specification but there are some differences in test results for a few locales.

This document describes cases where the CLDR person name test data produces results that are inconsistent with the specification text in [TR35-8 PersonNames](https://www.unicode.org/reports/tr35/tr35-personNames.html). These are filed as potential specification or test data bugs.

## 1. Format Selection Tiebreaker Inconsistency (es_US, es_MX, es_419)

### Affected locales

`es_US`, `es_MX`, `es_419`

### Summary

When two namePatterns have equal numbers of populated fields, the spec says to select the pattern with the fewest unpopulated fields. The CLDR test data expects the pattern with MORE unpopulated fields to be selected in certain cases, contradicting the spec.

### Specification text

From [Choose a namePattern](https://www.unicode.org/reports/tr35/tr35-personNames.html#choose-a-namepattern):

> 1. Find the set of patterns with the most populated fields.
> 2. If there is just one element in that set, use it.
> 3. Otherwise, among that set, find the set of patterns with the fewest unpopulated fields.
> 4. If there is just one element in that set, use it.
> 5. Otherwise, take the pattern that is alphabetically least.

### How to reproduce

Locale `es_MX`, format parameters: `order: sorting, length: long, usage: referring, formality: informal`.

The locale provides two sorting patterns for this combination:

```
Pattern A: {surname} {surname2}, {given-informal}    (3 fields)
Pattern B: {surname}, {given-informal}                (2 fields)
```

Input PersonName: `given: "Käthe", surname: "Müller"` (no surname2).

Scoring:

| Pattern | Total fields | Populated | Unpopulated |
|---------|-------------|-----------|-------------|
| A       | 3           | 2         | 1           |
| B       | 2           | 2         | 0           |

Per the spec, both have 2 populated fields (tied at step 1). At step 3, Pattern B has fewer unpopulated fields (0 vs 1), so **Pattern B should be selected**.

Pattern B produces: `"Müller, Käthe"` (with comma separator).

### Expected result (from CLDR test data)

`"Müller Käthe"` (no comma)

This is the result of Pattern A, where the empty `{surname2}` field and its surrounding comma are removed by the empty field processing rules, leaving `"Müller Käthe"`.

### Actual result (per specification algorithm)

`"Müller, Käthe"` (with comma)

Pattern B is selected because it has fewer unpopulated fields. Its comma separator is between two populated fields and is preserved.

### Analysis

The CLDR test data expects Pattern A to be selected, despite Pattern B having strictly fewer unpopulated fields. This suggests the ICU reference implementation uses a different format selection algorithm than what the specification describes.

Possible interpretations:

* The ICU implementation may prefer document order (first pattern) over the "fewest unpopulated" criterion when populated counts are equal.

* The ICU implementation may not implement step 3 at all, effectively using only step 1 (most populated) followed by document order or alphabetical tiebreaker.

* The spec text may need to be updated to reflect the actual ICU behavior.

The same pattern appears across 28 test cases in `es_US`, `es_MX`, and `es_419`, all involving sorting-order formats where one pattern includes `{surname2}` and the other does not.

### Test data references

* `es_MX.txt` line 645: `parameters; sorting; long; referring; informal` → expected `"Müller Käthe"`
* `es_US.txt` line 124: `parameters; sorting; medium; referring; formal` → expected `"García Pérez, Lucía"`
* `es_419.txt` line 134: `parameters; sorting; long; referring; informal` → expected `"Jacobsen Christopher"`

## 2. Empty Field Removal Drops Grouping Punctuation (cs, sk — now fixed)

### Affected locales

`cs`, `sk` (previously failing, now fixed in our implementation)

### Summary

The spec's empty field removal rules, as literally described, would drop grouping punctuation (opening parentheses) when a nil field precedes a parenthetical group. The spec describes removing a single empty field and then coalescing adjacent literals, but the coalescing rules can lose structural characters in certain literal combinations.

### Specification text

From [Process a namePattern](https://www.unicode.org/reports/tr35/tr35-personNames.html#process-a-namepattern):

> 1. If there are two or more empty fields separated only by literals, the fields and the literals between them are removed.
> 2. If there is a single empty field, it is removed.
> 3. If the processing from step 3 results in two adjacent literals (call them A and B), they are coalesced into one literal as follows:
>    * If either is empty the result is the other one.
>    * If B matches the end of A, then the result is A.
>    * Otherwise the result is A + B, further modified by replacing any sequence of two or more white space characters by the first whitespace character.

### How to reproduce

Locale `cs`, format parameters: `order: sorting, length: long, usage: referring, formality: formal`.

The format pattern is:

```
{surname-core}, {given} {given2} {surname-prefix} ({title}, {credentials})
```

Input PersonName: `title: "paní", given: "Alexandra", given2: "Zuzana", surname: "Machová", credentials: "Ph.D."` (no surname-prefix).

After field interpolation, the relevant segment is:

```
..., " ", nil, " (", {:field, "paní"}, ...
```

Where `nil` is the empty `{surname-prefix}` field, `" "` is the literal before it, and `" ("` is the literal after it.

### Expected result (from CLDR test data)

`"Machová, Alexandra Zuzana (paní, Ph.D.)"`

The opening parenthesis is preserved.

### Result from literal spec application

Applying the spec literally to `" ", nil, " ("`:

1. Single empty field (nil) → remove it.
2. Adjacent literals `" "` (A) and `" ("` (B) → coalesce.
3. B (`" ("`) does not match the end of A (`" "`).
4. Result: A + B = `" " + " ("` = `"  ("` → whitespace dedup → `" ("`.

The coalescing rules actually DO produce the correct result (`" ("`) in this specific case. However, most implementations handle `[literal, nil, literal]` by dropping one of the literals to handle the common separator case (like dropping `", "` when the field it accompanies is absent), which inadvertently drops the `" ("`.

### Analysis

The spec's coalescing rules technically handle this case correctly, but the interaction between "remove separator literals for absent fields" and "preserve grouping punctuation" requires careful implementation. A naive implementation that drops the literal following a nil (to handle common separator patterns) will fail for grouping punctuation.

Our implementation resolves this by detecting grouping punctuation characters (`(`, `)`, `[`, `]`) in the following literal and coalescing instead of dropping in those cases.

The spec could be improved by explicitly addressing how grouping punctuation should be preserved during empty field removal, or by providing test cases that exercise this interaction.

### Test data references

* `cs.txt` line 316: `parameters; sorting; long; referring; formal` → expected `"Machová, Alexandra Zuzana (paní, Ph.D.)"`
* `sk.txt` line 307: `parameters; sorting; long; referring; formal` → expected `"Machová, Alexandra Zuzana (paní, Ph.D.)"`

## 3. Initial Derivation Requires UAX #29 Grapheme Clusters, Not Default Unicode Grapheme Clusters

### Affected locales

`kn` (Kannada), `km` (Khmer), `ml` (Malayalam), `si` (Sinhala), `my` (Myanmar) — and potentially any locale using a complex Brahmic script.

### Summary

The spec says initials are derived by taking the "first grapheme cluster" of each word, but does not specify which grapheme cluster algorithm to use. The CLDR test data expects results consistent with [UAX #29 (Unicode Text Segmentation)](https://www.unicode.org/reports/tr29/) grapheme cluster boundaries, which differ from the default Unicode grapheme cluster boundaries defined in [UAX #44 (Unicode Character Database)](https://www.unicode.org/reports/tr44/) and implemented by most standard library string functions.

The distinction matters for Brahmic scripts (Devanagari, Kannada, Khmer, Malayalam, Sinhala, Myanmar, etc.) where a virama (halant) character joins consonants into conjuncts. The two algorithms produce different first-grapheme results for conjunct consonants, and the CLDR test data is consistent only with the UAX #29 definition.

### Specification text

From [Derive Initials](https://www.unicode.org/reports/tr35/tr35-personNames.html#derive-initials):

> To derive an initial from a name field value, the first grapheme cluster is extracted.

The spec does not qualify which grapheme cluster definition to use.

### The two grapheme cluster standards

**Default (legacy) grapheme clusters** are defined in [UAX #44, Section 5.15](https://www.unicode.org/reports/tr44/#Default_Grapheme_Cluster_Boundary). This is the algorithm used by most programming language standard libraries, including Erlang/OTP's `string` module (which underlies Elixir's `String.first/1` and `String.graphemes/1`). In this algorithm, a virama (U+0CCD in Kannada, U+17D2 in Khmer, etc.) is a combining mark that joins with the preceding AND following characters into a single cluster.

**Extended grapheme clusters** are defined in [UAX #29, Section 3.1](https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries). This algorithm includes script-specific tailoring rules via the `Grapheme_Cluster_Break` property. For Indic scripts, UAX #29 defines `InCB` (Indic Conjunct Break) properties that cause the virama to break the cluster at the conjunct boundary, producing shorter clusters.

### How to reproduce

Kannada word `ಕ್ಯಾಥಿ` (transliterated "Kyāthi"), composed of the codepoints:

| Codepoint | Character | Name |
|-----------|-----------|------|
| U+0C95 | ಕ | KANNADA LETTER KA |
| U+0CCD | ್ | KANNADA SIGN VIRAMA |
| U+0CAF | ಯ | KANNADA LETTER YA |
| U+0CBE | ಾ | KANNADA VOWEL SIGN AA |
| U+0CA5 | ಥ | KANNADA LETTER THA |
| U+0CBF | ಿ | KANNADA VOWEL SIGN I |

**Default grapheme clusters** (Erlang/Elixir `String.graphemes/1`):

```
["ಕ್ಯಾ", "ಥಿ"]   — 2 clusters
```

The virama (U+0CCD) joins KA + YA + AA into one large conjunct cluster.

**UAX #29 extended grapheme clusters** (ICU, `Unicode.String.split(break: :grapheme)`):

```
["ಕ್", "ಯಾ", "ಥಿ"]   — 3 clusters
```

The virama only joins with the preceding KA, and YA starts a new cluster.

### Expected result (from CLDR test data)

The initial for `ಕ್ಯಾಥಿ` is `ಕ್` (KA + VIRAMA, 2 codepoints) — the first UAX #29 extended grapheme cluster.

### Actual result using default grapheme clusters

The initial is `ಕ್ಯಾ` (KA + VIRAMA + YA + AA, 4 codepoints) — the first default grapheme cluster, which includes the full conjunct.

### Further examples across scripts

| Script | Word | Default first cluster | UAX #29 first cluster | CLDR expected |
|--------|------|----------------------|----------------------|---------------|
| Kannada | ಕ್ಯಾಥಿ | ಕ್ಯಾ (4 codepoints) | ಕ್ (2 codepoints) | ಕ್ |
| Khmer | ហ្សាសាស្តូ | ហ្ (2 codepoints) | ហ្សា (4 codepoints) | ហ្សា |
| Malayalam | സ്‌റ്റോബർ | സ്‌റ്റോ (7 codepoints) | സ്‌ (3 codepoints) | സ്‌ |

Note that Khmer is the inverse case: the default cluster is too SHORT and the UAX #29 cluster is LONGER. This is because Khmer's coeng (U+17D2) has different `Grapheme_Cluster_Break` properties than Indic viramas, and UAX #29 correctly groups the subscript consonant with its base.

### Analysis

The spec should explicitly state that initial derivation uses **UAX #29 extended grapheme clusters**, not default grapheme clusters. This distinction is critical because:

1. **Most standard library implementations use default clusters.** Erlang/OTP, Go's `unicode/utf8`, Python's `grapheme` module, and many others implement the simpler default algorithm. Only libraries that specifically implement UAX #29 (such as ICU, Rust's `unicode-segmentation` crate, and the Elixir `unicode_string` package) produce the correct results.

2. **The difference is significant for Brahmic scripts.** These scripts represent roughly 40% of the world's writing systems by user population (Devanagari, Bengali, Tamil, Telugu, Kannada, Malayalam, Sinhala, Thai, Lao, Khmer, Myanmar, Tibetan, and others). An implementation using default grapheme clusters will produce incorrect initials for names in any of these scripts.

3. **The two algorithms diverge specifically at virama/halant boundaries.** The virama character (or its equivalent: coeng in Khmer, asat in Myanmar, al-lakuna in Sinhala) is the point where the algorithms differ. UAX #29's `InCB` (Indic Conjunct Break) property tables define script-specific rules for how these characters interact with cluster boundaries.

### Suggested spec clarification

The phrase "first grapheme cluster" in the initial derivation section should be amended to read:

> To derive an initial from a name field value, the first **extended grapheme cluster** (as defined by [UAX #29](https://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries)) is extracted.

### Test data references

* `kn.txt` line 522: initial for `ಕ್ಯಾಥಿ` → expected `ಕ್.`
* `km.txt` line 444: initial for `ហ្សាសាស្តូ` → expected `ហ្សា.`
* `ml.txt` line 440: initial for `സ്‌റ്റോബർ` → expected `സ്‌.`

## 4. Test Data / Locale Data Mismatch for yo_BJ (Yoruba-Benin)

### Affected locales

`yo_BJ`

### Summary

The `yo_BJ` test data expects initials (e.g., `"O. Adeboye"`) for `short/referring/formal` formats, but the `yo_BJ` locale data contains no `-initial` modifier in those format patterns. The format pattern `{given} {given2} {surname} {credentials}` outputs full names, not initials. The parent locale `yo` has identical format patterns and its test data correctly expects full names for the same format combinations.

### How to reproduce

Locale `yo_BJ`, format parameters: `order: givenFirst, length: short, usage: referring, formality: formal`.

The locale format pattern is:

```
{given} {given2} {surname} {credentials}
```

Input PersonName: `given: "Olabisi", surname: "Adeboye"`, locale: `yo_BJ`.

### Expected result (from CLDR test data)

`"O. Adeboye"` — initial + surname.

### Actual result (per locale format data)

`"Olabisi Adeboye"` — full given name + surname, because the format pattern has no `-initial` modifier on the `{given}` field.

### Comparison with parent locale yo

The `yo` locale has the identical format pattern for `givenFirst/short/referring/formal`:

```
{given} {given2} {surname} {credentials}
```

The `yo` test data expects `"Olabisi Adeboye"` (full name) for this same combination — and this passes correctly.

### Analysis

The `yo_BJ` test data appears to have been generated against a different version of the `yo_BJ` locale data that included `-initial` modifiers in the short/formal format patterns (e.g., `{given-initial} {given2-initial} {surname}`). The current locale data does not include these modifiers, making the test expectations inconsistent with the format patterns.

This affects 27 test cases in `yo_BJ.txt`, all involving `short/referring` or `medium/referring` format combinations where initials are expected but not produced.

### Test data references

* `yo_BJ.txt` line 152: `parameters; givenFirst; short; referring; formal` → expected `"O. Adeboye"`, actual `"Olabisi Adeboye"`
* `yo_BJ.txt` line 252: `parameters; sorting; short; referring; formal` → expected `"Akintola, A. A."`, actual `"Akintola, Adeolu Adegboyega"`
* Compare `yo.txt` line 143: `parameters; givenFirst; short; referring; formal` → expected `"Olabisi Adeboye"` (full name, matches format data)
