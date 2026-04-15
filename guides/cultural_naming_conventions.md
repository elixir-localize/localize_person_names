# Cultural naming conventions: a field guide

Personal names are among the most culturally sensitive data points an application ever handles. The same sequence of characters that looks like a normal name in one country can be a legal identifier in another, an informal nickname in a third, and an inadvertent drug reference or slur in a fourth. This guide surveys how people identify themselves around the world, the formality and context conventions that govern when to use which form, the concrete harm caused by getting it wrong, and the research showing how much commercial value is at stake.

The goal is to help developers, product managers, and designers understand the underlying cultural landscape their systems operate in, and to make informed decisions about how to collect, store, and display names. The technical mechanisms for doing this correctly are in the [CLDR Person Names specification](https://www.unicode.org/reports/tr35/tr35-personNames.html) and in `Localize.PersonName.to_string/2` — this guide is the "why" that the code's "how" serves.

## The core problem: names resist simplification

In 2010, Patrick McKenzie published [Falsehoods Programmers Believe About Names](https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/), a list of 40 assumptions about personal names that programmers routinely make and that are routinely wrong. Fifteen years later, the article is still being translated, cited, and re-linked — because its examples remain live bugs in production systems everywhere.

A partial list of the assumptions the article dismantles:

* People have exactly one canonical full name. (No — McKenzie himself accepts six different "full" names as correct for various purposes, and most systems he encounters accept none of them.)
* Names are composed of a given name and a surname. (No — half the world orders surname first; some cultures use patronymics; Indonesian mononyms are a single name with no surname at all.)
* People's names fit in a Latin-1 character set, or an ASCII character set, or 40 characters, or any specific length. (No on all counts. Names include Chinese characters, Arabic right-to-left scripts, Devanagari conjuncts, and arbitrary Unicode; the Māori king's name is 85 characters.)
* Names don't change. (No — marriage, divorce, adoption, religious conversion, gender transition, and legal order all change names. Culturally, Japanese family registers can record multiple historical names; Spanish women may use maiden names professionally and married names legally.)
* Punctuation in names is decorative. (No — the Irish surname `O'Hara` is not the same as the Japanese-romanised surname `Ohara`. The ogonek in `Wałęsa` distinguishes real people. The apostrophe is a functional part of the name, not noise to be stripped.)

The underlying principle: a name is whatever the bearer says it is, in whatever form they say it is. A system that tells a user their name is wrong is not validating data — it is failing to model reality.

## How the world identifies itself

CLDR groups the world's naming practices into a small number of structural patterns. The specification is exhaustive; this section covers the ones most developers hit in practice.

### Given-first vs surname-first ordering

The most visible divide is the order of the given name and the surname.

* *Given-first* cultures place the given name before the surname. English `John Smith`, French `Marie Dupont`, German `Johann Bach`, and most European-language conventions follow this pattern. In business correspondence, the given name is frequently dropped in favour of the title and surname ("Dr. Smith").

* *Surname-first* cultures place the family name first. Chinese `毛泽东` (Mao Zedong — family name Mao, given name Zedong), Japanese `宮崎駿` (Miyazaki Hayao — family name Miyazaki, given name Hayao), Korean `김민준` (Kim Min-jun — family name Kim, given name Min-jun), Vietnamese `Nguyễn Văn A` (family name Nguyễn first), and Hungarian `Bartók Béla` (family name Bartók first, uniquely among European languages) all follow this pattern.

When a Japanese person's name appears in English text, Western journalism has historically reversed the order to "Hayao Miyazaki" — but Japanese government guidance since 2020 has encouraged English-language publications to preserve surname-first order, and the Japanese Ministry of Foreign Affairs now writes its ministers' names in family-name-first order even in English. Many systems still reverse the order automatically; this is no longer considered correct.

### Prefixes, particles, and compound surnames

Dutch surnames frequently include a `tussenvoegsel` — a particle like `van`, `van der`, `de`, `den`, or `ter`. The Dutch painter `Vincent van Gogh` has surname parts that do not sort alphabetically the same way: in Dutch phone directories he appears under `G` (Gogh, van), but in English-language directories under `V` (van Gogh, Vincent). The particle is part of the surname legally but is treated differently for sorting, capitalisation (lowercase in Dutch, capitalised at the start of a sentence), and informal address ("meneer Van Gogh" vs "meneer Gogh").

German, French, and Italian have similar patterns — `von Bismarck`, `de Gaulle`, `di Caprio`. In Spanish, the `de` or `de la` joins naming components but typically does not separate into an independent sortable particle.

Spanish and Portuguese naming adds another dimension: most Spanish and Portuguese speakers carry **two surnames**, one from each parent. `Gabriel García Márquez` is surname `García` (paternal) and surname2 `Márquez` (maternal), with given name `Gabriel`. In Spanish, the paternal surname sorts first and is used in short references; in Portuguese the order is reversed (maternal first, paternal last). Omitting one of the surnames is not a shortening — it's picking a different name. Legal documents require both; social contexts typically use both; some people use only one professionally.

Arabic names use a patronymic chain: `Osama bin Laden` means "Osama, son of Laden" — `bin` (son of) is a functional particle, and formal Arabic names extend the chain through multiple generations. Russian uses a similar system with patronymic middle names derived from the father's given name: `Vladimir Vladimirovich Putin` is "Vladimir, son of Vladimir, family name Putin". Russian patronymics change form depending on the child's gender (`-ovich`/`-evich` for sons, `-ovna`/`-evna` for daughters). Addressing a Russian adult formally uses the given name + patronymic, *not* the family name: a direct translation of "Mr. Putin" is considered impolite.

Icelandic names are patronymic or matronymic rather than having family names at all. `Björk Guðmundsdóttir` means "Björk, daughter of Guðmundur" — `Guðmundsdóttir` is not a surname she shares with her brother (who is `Guðmundsson`) or her children. Icelandic phone directories sort by given name. Systems that assume `-dóttir` is a surname and try to display "Ms. Guðmundsdóttir" are categorically wrong in a way that cannot be papered over.

### Scripts and segmentation

Chinese names are typically two or three Chinese characters with no space. The family name is usually the first character; `李` is a family name, `白` is a given name, and `李白` is the poet Li Bai. Japanese names combine a family name (often two characters) and a given name (often two characters) with no separating space in native script — but a space *is* used when romanised, and the CLDR specification provides a `nativeSpaceReplacement` (empty string) and `foreignSpaceReplacement` (`・`, the katakana middle dot) to handle the distinction when formatting foreign names in Japanese text. "Albert Einstein" in Japanese is written `アルベルト・アインシュタイン` — the middle dot is not decoration, it's the glue that tells a Japanese reader "these are two separable words, because this is a foreign name".

Thai names include both a given name and a surname, but Thai society strongly prefers nicknames in informal contexts. A Thai person named `Somchai Sornprakhon` may be known to colleagues as `Chai` or as a completely unrelated nickname ("Toto", "Nam"); formal contexts require the full given + surname; official documents require all of this plus honorifics like `นาย` (Mr.) or `นางสาว` (Miss).

Indic scripts add further complexity. Kannada, Malayalam, Khmer, Myanmar, Sinhala, and many other Brahmic scripts build consonant clusters using a virama (halant) character that visually joins letters into conjuncts. The first "letter" of a name in these scripts is not necessarily the first codepoint or even the first grapheme cluster under the default Unicode algorithm — it's the first extended grapheme cluster under [UAX #29](https://unicode.org/reports/tr29/). Getting this wrong produces nonsense initials.

### Mononyms and anonyms

Some cultures do not use family names at all, or use them inconsistently. Indonesian identity cards historically recorded only a single name — the actor `Suharto` went by a single name for his entire life and was elected president of Indonesia under that single name. Ethiopian and Eritrean names use the father's given name in place of a surname, so "Abebe Bikila" is "Abebe, whose father is Bikila", and his son would be "X Abebe" rather than "X Bikila". Icelandic names, as noted above, are patronymic.

Systems that require a surname field and reject a single-name submission exclude all of these people from participation. The CLDR spec explicitly handles mononyms — when only a given name is supplied, formatters rewrite the pattern rather than outputting an error.

## Formality and context

Names don't appear in a single form. The same person has a cluster of legitimate names for different contexts, and CLDR models this along four axes.

### Length

`short`, `medium`, `long`. A long formal American name might be "Dr. Robert John Smith III, PhD". The same person's medium form might be "Robert J. Smith". Short might be "Dr. Smith" or just "Robert". The right length depends on the medium: a legal document uses long; an email salutation uses short; an avatar uses a monogram.

### Usage

* *Addressing* — speaking *to* someone. "Dear Dr. Smith,". The vocative case. Titles dominate; given names are often omitted in formal contexts.

* *Referring* — speaking *about* someone. "Dr. Smith has approved the report." The nominative case. Formal references include the full name; informal references may use just the given name.

* *Monogram* — an abbreviated identifier, typically for avatars. A Western "Robert John Smith" monogram might be "RJS"; a Japanese "宮崎駿" monogram might be "宮" (just the family name's first character). A Kannada name's monogram is an akshara, not a Unicode codepoint.

These three contexts have different rules. A letter addressed "Dear Mr. Smith," but signed by "Mr. Smith" reads as comical because the signatory should refer to themselves (referring usage) while addressing the recipient (addressing usage). Software that uses the same name string for both contexts produces this error constantly.

### Formality

* *Formal* — full titles, credentials, generation markers. `Prof. Dr. Ada Cornelia von Brühl Jr., MD DDS`.

* *Informal* — nicknames where the locale's data provides them; no titles; often just the given name or a short form. `Neele`, `Bob`, `Хасан`.

Informal forms are locale-specific and often data-driven — the CLDR specification notes that informal forms cannot safely be *derived* (Beth/Betsy/Bette/Liz all derive from Elizabeth, and choosing one is a personal decision), only stored as an explicit field the user provides.

### The four-axis matrix

The combinations matter. A short-informal-addressing form is what you put on a conference badge ("Jo"). A long-formal-referring form is what you put on a diploma ("Josephine Margaret Nguyen, PhD"). A medium-formal-addressing form is what you put in an automated email salutation ("Dear Dr. Nguyen,"). These are not interchangeable — using the diploma form on the badge is absurd; using the badge form on the diploma is insulting.

## The risks of getting it wrong

Name-handling bugs range from amusing to career-ending. A survey of documented cases:

### Accidental offensive initials

The blog article [多文化環境におけるパーソナルネームの扱い方](https://zenn.dev/blue_jam/articles/5553aec104e710) (Handling personal names in multicultural environments) documents a specific Japanese failure mode: using both family-name and given-name initials together.

* **不破 貞仁 (Fuwa Sadahito)** — family initial `不` + given initial `貞` = `不貞` (infidelity).

* **大谷 麻美 (Ōtani Asami)** — family initial `大` + given initial `麻` = `大麻` (marijuana / cannabis).

These are not contrived examples — they are real Japanese surnames and given names, and the compounds they form are real Japanese words with deeply unwelcome meanings. A Western-originated monogram convention ("use the first letter of each name part") is not just unidiomatic in Japanese context — it actively generates offensive strings. CLDR recommends using only the family name initial for Japanese monograms, avoiding the compound problem entirely. The referenced article also cites McKenzie's *Falsehoods Programmers Believe About Names* as required background reading for international software developers.

### Database rejection of legitimate names

The Polish politician `Lech Wałęsa` has an ogonek (`ę`) and a Polish `ł`. Systems that restrict names to `[A-Za-z]` reject his real name and store a wrong version. Airline reservation systems historically strip diacritics and mangle non-Latin characters — `Björk Guðmundsdóttir` becomes `BJORK GUDMUNDSDOTTIR` on her boarding pass, which can cause identity-verification problems at passport control when the boarding pass says `GUDMUNDSDOTTIR` but her passport says `Guðmundsdóttir`.

The Dutch writer `Max Havelaar` has the real surname `Multatuli` as his pen name. A system that treats pen names as illegitimate and demands a legal name is enforcing a narrower conception of "real name" than the user's government does.

### Name-order reversal

Major US newspapers historically wrote Japanese prime ministers' names in given-first order ("Shinzo Abe") even though Japanese press releases used surname-first order. In 2020 the Japanese government formally requested that English-language media preserve Japanese name order; most outlets complied. Software that auto-reverses based on a "this looks Asian" heuristic is still producing the old, wrong output.

Hungarian names are the most commonly mishandled case in Europe. `Bartók Béla` (surname Bartók first) is the correct Hungarian order; "Béla Bartók" is the English convention. A system that assumes all European names are given-first produces "Béla Bartók" even in Hungarian locales, and a system that assumes all surname-first names are East Asian applies a Japanese middle dot (`・`) to Hungarian names, producing `Bartók・Béla` — which is several kinds of wrong simultaneously.

### Pronoun and honorific guessing

Systems that guess gender from given names to pick an honorific ("Mr." vs "Ms.") fail in many cultures and fail for individuals whose name's gender presentation differs from their identity. The given name `Andrea` is male in Italian and female in English. `Ashley` has swapped genders in English over the past 50 years. Guessing is wrong so often that major CRM vendors now recommend asking users directly rather than inferring.

### Legal consequences

In the US, the Transportation Security Administration's Secure Flight program requires the name on a boarding pass to match the name on the traveller's ID exactly, including middle names and suffixes. Passengers with non-standard name handling — name changes after marriage, multiple legal names across jurisdictions, non-Latin native names — regularly have boarding passes rejected. Airlines have paid settlements to passengers denied boarding because of systemic name-handling bugs.

In the European Union, the General Data Protection Regulation treats names as personal data; storing a wrong version of someone's name (for example, an asciified version that the user did not provide) has been argued in data-protection complaints to constitute inaccurate processing under GDPR Article 5(1)(d).

## The business impact of getting it right

Getting names right is not only a courtesy — it's a measurable commercial lever.

* *Personalized experiences drive purchase behaviour.* Epsilon's [Power of Me research](https://www.businesswire.com/news/home/20210914005231/en/80-of-Consumers-More-Likely-to-Shop-with-Brands-that-Show-they-Understand-Them) found that **80% of consumers are more likely to purchase from a brand that provides personalized experiences**, and 90% find personalization appealing.

* *Mishandled personalization creates frustration.* McKinsey's research ["The value of getting personalization right — or wrong — is multiplying"](https://www.mckinsey.com/capabilities/growth-marketing-and-sales/our-insights/the-value-of-getting-personalization-right-or-wrong-is-multiplying) found that **71% of consumers expect companies to deliver personalized interactions, and 76% get frustrated when this doesn't happen**. McKinsey concluded that companies that grow faster drive 40% more of their revenue from personalization than slower-growing peers.

* *Personalization materially affects retention.* Salesforce's Connected Customer research ([Personalization, Data Security, and Speed Drive Customer Loyalty](https://www.salesforce.com/news/stories/customer-spending/)) identified personalization as one of the top three drivers of customer loyalty, alongside data security and service speed, with particular importance during periods of economic uncertainty when consumers actively reassess where they spend.

* *Retail buyers name personalization as a retention driver.* McKinsey's retail-sector research ([Personalizing the customer experience: Driving differentiation in retail](https://www.mckinsey.com/industries/retail/our-insights/personalizing-the-customer-experience-driving-differentiation-in-retail)) found that 53% of retailers surveyed said personalization benefits included increased customer loyalty and retention.

Names are the most personal of personalizations. Getting someone's name wrong in an email salutation is a worse experience than not sending the email at all, because it tells the recipient that the sender has their data but can't be bothered to use it correctly. A single incident is tolerable; a pattern of wrong-name emails from the same brand produces churn. Epsilon's data says 80% of consumers weigh personalization in their purchase decisions; McKinsey's data says 76% are frustrated when personalization fails; the product teams of any company sending more than a few thousand emails a month are running a name-handling quality gate whether they realise it or not.

## How this library addresses the problem

`Localize.PersonName` is a direct implementation of the [CLDR Person Names specification](https://www.unicode.org/reports/tr35/tr35-personNames.html), so the cultural patterns described above are built into its data model, its formatting algorithm, and the 120 locale-specific pattern sets it ships with. The sections below map each class of problem raised in this guide to the specific mechanism the library uses to handle it.

### Unicode preservation — no silent mangling

Names are stored and formatted as arbitrary Unicode strings. There is no character-class validation, no length limit, no normalization that could discard combining marks. `Wałęsa`, `Björk Guðmundsdóttir`, `O'Hara`, `Ōtani`, and `宮崎駿` all round-trip through `Localize.PersonName.to_string/2` unchanged. The library's job is to arrange name parts according to locale rules — not to gatekeep what a name can contain.

### Name order derived from locale data, not heuristics

The library never guesses name order from character ranges or script detection. It reads the [`nameOrderLocales` data from CLDR](https://www.unicode.org/reports/tr35/tr35-personNames.html#deriving-the-name-order) for each locale, which explicitly lists which languages prefer surname-first ordering. Japanese `宮崎駿`, Chinese `李白`, Korean `김민준`, Vietnamese `Nguyễn Văn A`, and Hungarian `Bartók Béla` all format correctly because Hungarian is listed as `surnameFirst` in its own locale data, not because the library guesses from the Latin-script characters. The explicit `preferred_order` field on the struct lets an individual name override the locale default when the bearer has expressed a preference.

### Tussenvoegsels and particle-aware surnames

The `surname_prefix` field holds `van`, `van der`, `de`, `von`, `di`, and other particles separately from the core surname. Dutch `van Gogh` formats as `van Gogh` in display order but as `Gogh, Vincent van` in sorting order, because the Dutch locale's sorting pattern is `{surname-core}, {given} {surname-prefix}`. The same data drives correct German `von Bismarck` handling and Italian `di Caprio` handling without any locale-specific code in the application.

### Double surnames (Spanish, Portuguese)

The `surname` and `other_surnames` fields carry the paternal and maternal surnames separately. Spanish `Gabriel García Márquez` formats fully in formal contexts (`Gabriel García Márquez`) and with only the paternal surname in short contexts (`García`). The library's format selection algorithm picks the pattern that uses the fields that are actually populated — a customer record with only a single surname gets the single-surname pattern automatically, not a misleading double-surname display.

### Patronymics

Russian `Vladimir Vladimirovich Putin` uses `other_given_names` for the patronymic. Russian addressing patterns include the patronymic (the equivalent of "Mr. Putin" is usually "Vladimir Vladimirovich"), and the library's Russian addressing patterns reflect that. Icelandic `Björk Guðmundsdóttir` is modelled as `given: "Björk", surname: "Guðmundsdóttir"`, and Icelandic's own `nameOrderLocales` data drives the resulting display — the library does not impose a surname-last assumption on a culture that doesn't share it.

### Monograms that avoid accidental compounds

The Japanese monogram problem described above — where `不破 貞仁` produces the offensive compound `不貞` if both initials are combined — is handled by the Japanese locale's CLDR monogram patterns, which the library uses directly. A Japanese formal monogram uses only the family-name initial (`{surname-monogram}`), not a compound; a Japanese informal monogram uses only the given-name initial. `Localize.PersonName.to_string(name, usage: :monogram, locale: :ja)` produces `宮` for `宮崎駿`, not `宮駿` or `宮崎駿` or `宮宮`. The compound problem cannot occur because the library never constructs compound monograms in Japanese contexts.

### Script-aware initial generation

For Indic and Southeast Asian scripts, "first letter" is not "first codepoint" or "first default grapheme cluster" — it's the first extended grapheme cluster under [UAX #29](https://unicode.org/reports/tr29/). The library delegates grapheme segmentation to [`unicode_string`](https://hex.pm/packages/unicode_string), which implements the UAX #29 algorithm with Indic conjunct break handling. A Kannada name like `ಕ್ಯಾಥಿ` produces the initial `ಕ್` (Ka + virama), which is what a Kannada reader expects — not `ಕ್ಯಾ` (the full first conjunct) or `ಕ` (just the base consonant). See the [specification deviances document](https://github.com/elixir-localize/localize_person_names/blob/v0.1.0/specification_deviances.md) for the full discussion.

### Native vs foreign space replacement

Japanese `native_space_replacement` is empty (`宮崎駿` has no space), but `foreign_space_replacement` is `・` (the katakana middle dot, as in `アルベルト・アインシュタイン`). The library applies the correct replacement based on whether the name's language matches the formatting locale's language. A Japanese native name formats without spaces; a foreign name formatted in Japanese gets the middle dot; a foreign name formatted in English gets a normal space. The Hungarian surname-first case does *not* get the Japanese middle dot because Hungarian's `foreign_space_replacement` is a regular space, as expected.

### Mononyms and missing fields

Indonesian `Zendaya` (given name only) formats as `Zendaya` across all formats, usages, and formalities. The library's format selection algorithm handles single-name submissions automatically by applying the "missing surname" rule from the CLDR specification: when the name has no surname and the chosen pattern uses only the given name or an initial of it, the given name is moved into the surname slot so sorting and addressing contexts produce sensible output. Users who do not have a surname are not forced to invent one.

### Length, usage, and formality are first-class

The `:format`, `:usage`, and `:formality` options exist precisely because a conference-badge name ("Jo"), an email salutation ("Dear Dr. Nguyen,"), and a diploma name ("Josephine Margaret Nguyen, PhD") are different strings for the same person. The library provides the right string for each context rather than forcing callers to choose a single "display name" that's wrong in most contexts. The [MF2 integration](https://github.com/elixir-localize/localize_person_names/blob/v0.1.0/guides/message_formatting.md) makes these options available inside message templates, so a letter template can request the addressing form and a signature block can request the referring form from the same bound variable.

### Opt-in locale switching for cross-script names

When a Japanese formatter encounters a Latin-script name (for example a Western customer's name displayed in a Japanese UI), the CLDR specification defines an optional locale-switching step: format the name using a locale appropriate to its script, rather than forcing the formatting locale's patterns onto text that doesn't fit them. The library implements this behind the `:locale_switching` option. Default is `false` (matching the CLDR test data); set `locale_switching: true` in any `to_string/2` call to get script-aware switching.

### Integration paths that fit existing code

Applications rarely model people as generic `Localize.PersonName` structs — they have `%User{}`, `%Customer{}`, `%Employee{}` domain structs. The [`Localize.PersonName.Convertible` protocol](https://github.com/elixir-localize/localize_person_names/blob/v0.1.0/guides/integrating_existing_structs.md) lets a single `defimpl` block turn any existing struct into something the formatter accepts, without modifying the struct's module. This means the library can be adopted incrementally in a large codebase: add the protocol implementation, then gradually replace string concatenation with `Localize.PersonName.to_string/2` at each call site.

### What the library does not do

The library does not collect name data, pick honorifics, or decide whether a name is "valid". Those are product and UX decisions that the library explicitly does not take a position on. What it does is: given a correctly-collected name and a target locale, produce the string that a reader of that locale expects to see.

## Recommendations

For anyone building systems that handle names:

* *Store names as the user provides them.* Do not strip diacritics, lowercase, reorder, or split into given/family unless the user explicitly provides the split. Preserve the exact Unicode sequence, including punctuation and combining marks.

* *Allow single-name submissions.* Make the surname field optional at the schema level. Handle mononyms in display logic by using the given name in place of the surname when necessary (the CLDR spec does this automatically).

* *Use locale-aware formatting libraries rather than string concatenation.* `"#{first_name} #{last_name}"` is wrong for at least half the world. A library like this one (or ICU's `PersonName` API) handles order, spacing, and script-specific rules.

* *Ask for the form needed for the context.* A registration form can ask for legal name, preferred name, and display name as separate fields, and let the user decide which to use where. The Salesforce and Slack approaches to "display name" versus "legal name" are good baselines.

* *Test with names from the cultures you serve.* Staff from the target culture should review how the system renders example names before launch. A naming bug that ships to production is more expensive than one caught in QA, and a naming bug that ships to a specific culture signals that the company does not value users from that culture.

* *Never guess at gender or honorifics from a name.* Ask, and let the user skip the question. Default to no honorific rather than a wrong one.

* *Document the scope of your name handling.* If you only support Latin-alphabet names up to 50 characters, say so up front so users can make informed decisions. Silent truncation and silent transliteration are worse than an honest limitation.

## Further reading

* [Unicode Technical Standard #35: Person Names](https://www.unicode.org/reports/tr35/tr35-personNames.html) — the authoritative specification this library implements.

* [Falsehoods Programmers Believe About Names](https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/) by Patrick McKenzie, 2010. Still the canonical primer; read in full before designing any system that collects names.

* [多文化環境におけるパーソナルネームの扱い方](https://zenn.dev/blue_jam/articles/5553aec104e710) — a focused examination of how Western monogram conventions produce offensive strings in Japanese contexts.

* [Personalizing the customer experience](https://www.mckinsey.com/industries/retail/our-insights/personalizing-the-customer-experience-driving-differentiation-in-retail) and [The value of getting personalization right](https://www.mckinsey.com/capabilities/growth-marketing-and-sales/our-insights/the-value-of-getting-personalization-right-or-wrong-is-multiplying) — McKinsey's research on the commercial impact of personalization.

* [80% of Consumers More Likely to Shop with Brands that Show they Understand Them](https://www.businesswire.com/news/home/20210914005231/en/80-of-Consumers-More-Likely-to-Shop-with-Brands-that-Show-they-Understand-Them) — Epsilon's Power of Me study.

* [Personalization, Data Security, and Speed Drive Customer Loyalty](https://www.salesforce.com/news/stories/customer-spending/) — Salesforce's State of the Connected Customer research.

Sources:

* [Unicode TR35 Person Names](https://www.unicode.org/reports/tr35/tr35-personNames.html)
* [Falsehoods Programmers Believe About Names](https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/)
* [多文化環境におけるパーソナルネームの扱い方](https://zenn.dev/blue_jam/articles/5553aec104e710)
* [Epsilon: 80% of Consumers More Likely to Shop with Brands that Show they Understand Them](https://www.businesswire.com/news/home/20210914005231/en/80-of-Consumers-More-Likely-to-Shop-with-Brands-that-Show-they-Understand-Them)
* [McKinsey: The value of getting personalization right — or wrong — is multiplying](https://www.mckinsey.com/capabilities/growth-marketing-and-sales/our-insights/the-value-of-getting-personalization-right-or-wrong-is-multiplying)
* [McKinsey: Personalizing the customer experience in retail](https://www.mckinsey.com/industries/retail/our-insights/personalizing-the-customer-experience-driving-differentiation-in-retail)
* [Salesforce: Personalization, Data Security, and Speed Drive Customer Loyalty](https://www.salesforce.com/news/stories/customer-spending/)
