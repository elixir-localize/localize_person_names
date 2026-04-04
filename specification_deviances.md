# CLDR Person Names Specification Deviances

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
