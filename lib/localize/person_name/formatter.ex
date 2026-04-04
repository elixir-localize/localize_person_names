defmodule Localize.PersonName.Formatter do
  @moduledoc """
  Implements the person name formatting specification.

  """

  type_from_list = &Enum.reduce(&1, fn x, acc -> {:|, [], [x, acc]} end)

  @format [:short, :medium, :long]
  @usage [:addressing, :referring, :monogram]
  @formality [:formal, :informal]
  @default_usage :addressing
  @preferred_order [:given_first, :surname_first, :sorting]

  @format_options [:format, :usage, :order, :formality, :locale, :locale_switching]

  @typedoc "Valid :format option"
  @type format :: unquote(type_from_list.(@format))

  @typedoc "Valid :name_order option"
  @type name_order :: unquote(type_from_list.(@preferred_order))

  @typedoc "Valid :usage option"
  @type usage :: unquote(type_from_list.(@usage))

  @typedoc "Valid :formality option"
  @type formality :: unquote(type_from_list.(@formality))

  @typedoc "Valid options for Localize.PersonName.to_string/2"
  @type format_option ::
          {:format, format()}
          | {:name_order, name_order()}
          | {:usage, usage()}
          | {:formality, formality()}
          | {:locale, Localize.LanguageTag.t() | atom() | String.t()}

  @typedoc "Localize.PersonName.to_string/2 options list"
  @type format_options :: list(format_option())

  # These languages will have a different String.upcase/1 treatment than the default.
  # Turkish, Azeri, Tatar, Turkmen, Uygur, Uzbek
  @turkic_languages [:tr, :az, :tt, :tk, :ug, :uz]

  # Preference is given to the name's preferred order, then the locales preferred
  # order, then this default order.
  @default_order :given_first

  # ASCII space used in the templates
  @format_space " "

  @likely_subtags Localize.SupplementalData.likely_subtags()

  defguardp is_initial(term) when is_list(term)

  @doc false
  def valid_name_order do
    [:given_first, :surname_first, :sorting]
  end

  @doc false
  def to_iodata(name, formatting_locale, options) do
    locale_switching = Keyword.get(options, :locale_switching, false)

    with {:ok, name_locale} <- derive_name_locale(name, formatting_locale),
         {:ok, formatting_locale} <-
           maybe_switch_locale(locale_switching, name, formatting_locale, name_locale),
         {:ok, formats} <- formats(formatting_locale),
         {:ok, options} <- validate_options(formats, options),
         {:ok, options} <- determine_name_order(name, name_locale, options),
         {:ok, format} <- select_format(name, formats, options),
         {:ok, name, format} <- adjust_for_mononym(name, format) do
      name
      |> interpolate_format(formatting_locale, format, formats)
      |> foreign_or_native_space_replacement(name_locale, formatting_locale, formats)
      |> wrap(:ok)
    end
  end

  defp maybe_switch_locale(false, _name, formatting_locale, _name_locale) do
    {:ok, formatting_locale}
  end

  defp maybe_switch_locale(true, name, formatting_locale, name_locale) do
    derive_formatting_locale(name, formatting_locale, name_locale)
  end

  defp validate_options(formats, options) do
    options =
      default_options(formats)
      |> Keyword.merge(options)
      |> Keyword.delete(:locale)
      |> Keyword.delete(:locale_switching)
      |> Keyword.take(@format_options)

    Enum.reduce_while(options, {:ok, options}, fn
      {:format, value}, acc when value in @format ->
        {:cont, acc}

      {:usage, value}, acc when value in @usage ->
        {:cont, acc}

      {:order, value}, acc when value in @preferred_order ->
        {:cont, acc}

      {:formality, value}, acc when value in @formality ->
        {:cont, acc}

      {option, value}, _acc when option in @format_options ->
        {:halt, {:error, "Invalid value #{inspect(value)} for option #{inspect(option)}"}}

      {option, _value}, _acc ->
        {:halt, {:error, "Invalid option #{inspect(option)}"}}
    end)
  end

  defp default_options(formats) do
    [
      format: formats.length,
      formality: formats.formality,
      usage: @default_usage
    ]
  end

  # Interpolate the format
  @doc false
  def interpolate_format(name, locale, elements, formats) do
    elements
    |> Enum.map(&interpolate_element(name, &1, locale, formats))
    |> remove_leading_emptiness()
    |> remove_trailing_emptiness()
    |> remove_empty_fields()
    |> extract_values()
  end

  @doc false
  def remove_leading_emptiness([{:field, value} | rest]), do: [{:field, value} | rest]
  def remove_leading_emptiness([_first | rest]), do: remove_leading_emptiness(rest)
  def remove_leading_emptiness([]), do: []

  @doc false
  def remove_trailing_emptiness(elements) do
    elements
    |> Enum.reverse()
    |> maybe_remove_leading_emptiness()
    |> Enum.reverse()
  end

  @doc false
  def maybe_remove_leading_emptiness(elements) do
    Enum.reduce_while(elements, nil, fn
      nil, _acc ->
        {:halt, remove_leading_emptiness(elements)}

      {:field, _value}, _acc ->
        {:halt, elements}

      _other, acc ->
        {:cont, acc}
    end)
  end

  # Per the spec: "If there are two or more empty fields separated
  # only by literals, the fields and the literals between them are
  # removed." This clause handles the two-nil case first, consuming
  # both nils and the literal between them.
  @doc false
  def remove_empty_fields([literal_1, nil, literal_2, nil | rest])
      when is_binary(literal_1) and is_binary(literal_2) do
    remove_empty_fields([literal_1, nil | rest])
  end

  # Per the spec: "If there is a single empty field, it is removed."
  # When a single nil sits between two literals, remove the nil.
  # Normally the literal following the nil (a separator like ", ")
  # is dropped since the field it accompanies is absent. However,
  # when the following literal contains grouping punctuation
  # (parentheses, brackets), it is preserved by coalescing.
  def remove_empty_fields([literal_1, nil, literal_2 | rest])
      when is_binary(literal_1) and is_binary(literal_2) do
    if String.contains?(literal_2, ["(", ")", "[", "]"]) do
      remove_empty_fields([combine_binary(literal_1, literal_2) | rest])
    else
      remove_empty_fields([literal_1 | rest])
    end
  end

  def remove_empty_fields([nil | rest]) do
    case remove_up_to_nil(rest) do
      [] -> remove_empty_fields(rest)
      rest -> remove_empty_fields(rest)
    end
  end

  def remove_empty_fields([literal | rest]) when is_binary(literal) do
    case remove_empty_fields(rest) do
      [binary | rest] when is_binary(binary) ->
        [combine_binary(literal, binary) | rest]

      other ->
        [literal | other]
    end
  end

  def remove_empty_fields([first | rest]) do
    [first | remove_empty_fields(rest)]
  end

  def remove_empty_fields([]) do
    []
  end

  defp remove_up_to_nil([{:field, _value} | _rest]),
    do: []

  defp remove_up_to_nil([nil | rest]),
    do: rest

  defp remove_up_to_nil([binary | rest]) when is_binary(binary),
    do: remove_up_to_nil(rest)

  @doc false
  def combine_binary(first, ""), do: first
  def combine_binary("", second), do: second
  def combine_binary(first, first), do: first

  @doc false
  def combine_binary(first, second) do
    if String.ends_with?(first, second) do
      first
    else
      remove_duplicate_whitespace(first <> second)
    end
  end

  @doc false
  def remove_duplicate_whitespace(string) do
    case Regex.named_captures(~r/(?<whitespace>\s+)/u, string) do
      %{"whitespace" => whitespace} ->
        replacement = String.first(whitespace)
        String.replace(string, ~r/\s+/u, replacement)

      nil ->
        string
    end
  end

  defp extract_values(elements) do
    Enum.map(elements, fn
      {:field, value} -> value
      other -> other
    end)
  end

  # Setting the space replacement
  @doc false
  def foreign_or_native_space_replacement(list, name_locale, formatting_locale, formats) do
    replacement = foreign_or_native(name_locale.language, formatting_locale.language, formats)

    Enum.map(list, fn
      @format_space -> replacement
      other -> String.replace(other, @format_space, replacement)
    end)
  end

  @doc false
  def foreign_or_native(name_language, formatting_language, formats) do
    if considered_the_same_language?(name_language, formatting_language) do
      formats.native_space_replacement
    else
      formats.foreign_space_replacement
    end
  end

  defp considered_the_same_language?(language, language) do
    true
  end

  defp considered_the_same_language?(name_language, formatting_language) do
    name_language in [:ja, :zh, :yue] && formatting_language in [:ja, :zh, :yue]
  end

  @considered_the_same [:Jpan, :Hani, :Kana, :Hira]
  defp considered_the_same_script?(name_script, name_script) do
    true
  end

  defp considered_the_same_script?(name_script, formatting_script) do
    name_script in @considered_the_same and formatting_script in @considered_the_same
  end

  @doc false
  def wrap(term, atom) do
    {atom, term}
  end

  # Handle missing surname
  @doc false
  def adjust_for_mononym(%{surname: surname} = name, format) when is_binary(surname) do
    {:ok, name, format}
  end

  def adjust_for_mononym(name, format) do
    if format_has_full_given_name?(format) do
      {:ok, name, format}
    else
      name = move_given_to_surname(name)
      format = force_given_name_to_binary(format)
      {:ok, name, format}
    end
  end

  defp format_has_full_given_name?(format) do
    Enum.any?(format, &(is_list(&1) && hd(&1) == :given && :initial not in &1))
  end

  defp move_given_to_surname(name) do
    name
    |> Map.put(:surname, name.given_name)
    |> Map.put(:given_name, nil)
  end

  # Note: This function intentionally checks for :given_name (the
  # struct field name) rather than :given (the format field name).
  # Since format fields use :given, this is effectively a no-op.
  # The mononym handling works via move_given_to_surname/1 setting
  # given_name to nil, which causes interpolate_element to return
  # nil for any :given field — and nil values are properly removed
  # by the empty field removal logic.
  defp force_given_name_to_binary(format) do
    Enum.map(format, fn
      [:given_name | _rest] -> ""
      other -> other
    end)
  end

  defp interpolate_element(%{title: title}, [:title | transforms], locale, formats) do
    format_element(title, locale, transforms, formats)
  end

  defp interpolate_element(name, [:given, :informal | transforms], locale, formats) do
    format_element(name.informal_given_name || name.given_name, locale, transforms, formats)
  end

  defp interpolate_element(%{given_name: given_name}, [:given | transforms], locale, formats) do
    format_element(given_name, locale, transforms, formats)
  end

  defp interpolate_element(
         %{other_given_names: other_given_names},
         [:given2 | transforms],
         locale,
         formats
       )
       when is_binary(other_given_names) do
    format_element(other_given_names, locale, transforms, formats)
  end

  defp interpolate_element(
         %{surname_prefix: surname_prefix},
         [:surname, :prefix | transforms],
         locale,
         formats
       ) do
    format_element(surname_prefix, locale, transforms, formats)
  end

  defp interpolate_element(%{surname: surname}, [:surname, :core | transforms], locale, formats) do
    format_element(surname, locale, transforms, formats)
  end

  defp interpolate_element(name, [:surname, :monogram | transforms], locale, formats) do
    complete_surname = format_surname(name, locale, transforms, formats)

    if Enum.empty?(complete_surname) do
      nil
    else
      complete_surname
      |> :erlang.iolist_to_binary()
      |> monogram(locale)
      |> wrap(:field)
    end
  end

  defp interpolate_element(name, [:surname | transforms], locale, formats) do
    complete_surname =
      name
      |> format_surname(locale, transforms, formats)
      |> Enum.intersperse(@format_space)

    if Enum.empty?(complete_surname) do
      nil
    else
      complete_surname
      |> :erlang.iolist_to_binary()
      |> wrap(:field)
    end
  end

  defp interpolate_element(
         %{other_surnames: other_surnames},
         [:surname2 | transforms],
         locale,
         formats
       )
       when is_binary(other_surnames) do
    format_element(other_surnames, locale, transforms, formats)
  end

  defp interpolate_element(%{generation: generation}, [:generation | transforms], locale, formats)
       when is_binary(generation) do
    format_element(generation, locale, transforms, formats)
  end

  defp interpolate_element(
         %{credentials: credentials},
         [:credentials | transforms],
         locale,
         formats
       )
       when is_binary(credentials) do
    format_element(credentials, locale, transforms, formats)
  end

  defp interpolate_element(_name, element, _locale, _formats) when is_binary(element) do
    element
  end

  defp interpolate_element(_name, _element, _locale, _formats) do
    nil
  end

  # Formatting transforms

  defp format_element(nil, _locale, _transforms, _formats) do
    nil
  end

  defp format_element(value, locale, transforms, formats) do
    Enum.reduce(transforms, value, fn
      :all_caps, value ->
        language_mode = mode_from_locale(locale)
        String.upcase(value, language_mode)

      :monogram, value ->
        monogram(value, locale)

      :initial_cap, value ->
        language_mode = mode_from_locale(locale)
        String.capitalize(value, language_mode)

      :initial, value ->
        initialize_value(value, locale, transforms, formats)

      _other, value ->
        value
    end)
    |> wrap(:field)
  end

  defp format_surname(name, locale, [:initial | transforms], formats) do
    surname_prefix = format_element(name.surname_prefix, locale, [:initial | transforms], formats)
    surname = format_element(name.surname, locale, [:initial | transforms], formats)

    [surname_prefix, surname]
    |> extract_values()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&[&1])
    |> join_initials(formats)
  end

  defp format_surname(name, locale, transforms, formats) do
    surname_prefix = format_element(name.surname_prefix, locale, transforms, formats)
    surname = format_element(name.surname, locale, transforms, formats)

    [surname_prefix, surname]
    |> extract_values()
    |> Enum.reject(&is_nil/1)
  end

  defp initialize_value(value, locale, transforms, formats) do
    retain_punctuation? =
      Enum.any?(transforms, &(&1 == :retain))

    split_locale = locale_to_atom(locale)

    value
    |> Unicode.String.split(break: :word, trim: true, locale: split_locale)
    |> Enum.reduce([], &initialize_word(&1, locale, formats.initial, &2, retain_punctuation?))
    |> Enum.reverse()
    |> join_initials(formats)
    |> :erlang.iolist_to_binary()
  end

  # Starts with a letter, then letter or punctuation or a extended character
  @word_or_punctuation Unicode.Regex.compile!("^\\p{L}[\\p{L}\\p{P}\\p{word_break=extend}]*$")

  defp initialize_word(word, locale, initial_template, acc, false = _retain_punctuation?) do
    if Unicode.Regex.match?(@word_or_punctuation, word) do
      add_initial(word, locale, initial_template, acc)
    else
      acc
    end
  end

  defp initialize_word(word, locale, initial_template, acc, true = _retain_punctuation?) do
    if Unicode.Regex.match?(@word_or_punctuation, word) do
      add_initial(word, locale, initial_template, acc)
    else
      add_to_list(word, acc)
    end
  end

  defp add_initial(word, _locale, initial_template, acc) do
    word
    |> first_grapheme()
    |> Localize.Substitution.substitute(initial_template)
    |> add_to_list(acc)
  end

  defp add_to_list(element, list) do
    [element | list]
  end

  defp monogram(word, %{cldr_locale_id: locale}) do
    monogram(word, locale)
  end

  defp monogram(word, :el) do
    word
    |> first_grapheme()
    |> Unicode.unaccent()
  end

  defp monogram(word, _locale) do
    first_grapheme(word)
  end

  # Use Unicode.String grapheme break segmentation rather than Elixir's
  # String.first/1, because Erlang's built-in grapheme clustering
  # differs from UAX #29 for complex scripts (Indic, Khmer, etc.).
  # For example, Kannada ಕ್ಯಾಥಿ splits as ["ಕ್ಯಾ", "ಥಿ"] in Erlang
  # but as ["ಕ್", "ಯಾ", "ಥಿ"] per UAX #29, and initials need "ಕ್".
  defp first_grapheme(word) do
    case Unicode.String.split(word, break: :grapheme) do
      [first | _] -> first
      [] -> word
    end
  end

  defp locale_to_atom(%Localize.LanguageTag{cldr_locale_id: locale_id})
       when not is_nil(locale_id),
       do: locale_id

  defp locale_to_atom(%Localize.LanguageTag{language: language}), do: language
  defp locale_to_atom(locale) when is_atom(locale), do: locale
  defp locale_to_atom(_locale), do: :en

  defp mode_from_locale(%{cldr_locale_id: locale}) do
    mode_from_locale(locale)
  end

  defp mode_from_locale(:el), do: :greek
  defp mode_from_locale(locale) when locale in @turkic_languages, do: :turkic
  defp mode_from_locale(_), do: :default

  # Join multiple initials together

  defp join_initials([], _formats) do
    []
  end

  defp join_initials([first], _formats) do
    [first]
  end

  defp join_initials([first, second | rest], formats)
       when is_initial(first) and is_initial(second) do
    substitution = Localize.Substitution.substitute([first, second], formats.initial_sequence)
    join_initials([substitution | rest], formats)
  end

  defp join_initials([first | rest], formats) do
    [first | join_initials(rest, formats)]
  end

  # Derive the name locale
  @doc false
  def derive_name_locale(
        %{locale: %Localize.LanguageTag{} = name_locale} = name,
        _formatting_locale
      ) do
    name_script = dominant_script(name)

    if name_locale.script == name_script do
      {:ok, name_locale}
    else
      locale_name =
        Localize.Locale.locale_id_from(
          name_locale.language,
          name_script,
          name_locale.territory,
          []
        )

      Localize.validate_locale(locale_name)
    end
  end

  def derive_name_locale(%{locale: nil} = name, _formatting_locale) do
    name_script = dominant_script(name)

    case find_likely_locale(name_script) do
      {:ok, name_locale} when not is_nil(name_locale) -> {:ok, name_locale}
      _ -> {:error, "No locale resolved for script #{inspect(name_script)}"}
    end
  end

  # Derive the formatting locale per the spec:
  # "If the name script doesn't match the formatting script:
  #  1. If the name locale has name formatting data, then set
  #     the formatting locale to the name locale.
  #  2. Otherwise, set the formatting locale to the maximal
  #     likely locale for und + name script + name region."
  @doc false
  def derive_formatting_locale(_name, formatting_locale, name_locale) do
    if considered_the_same_script?(formatting_locale.script, name_locale.script) do
      {:ok, formatting_locale}
    else
      name_cldr_id = Localize.Locale.to_locale_id(name_locale)

      if Localize.PersonName.FormatParser.has_formatting_data?(name_cldr_id) do
        {:ok, name_locale}
      else
        name_script = name_locale.script

        case find_likely_locale(name_script, name_locale.territory) do
          {:ok, nil} -> {:ok, formatting_locale}
          {:ok, candidate} -> {:ok, candidate}
          {:error, _} -> {:ok, formatting_locale}
        end
      end
    end
  end

  # Per the spec: "Iterate through the characters of the surname,
  # then through the given name." Return the script of the first
  # character whose script is not Common, Inherited, or Unknown.
  defp dominant_script(name) do
    text =
      [name.surname, name.given_name]
      |> Enum.filter(&is_binary/1)
      |> Enum.join()

    text
    |> Unicode.script()
    |> Enum.reject(&(&1 in [:common, :inherited, :unknown]))
    |> resolve_cldr_script_name()
  end

  defp resolve_cldr_script_name([]) do
    Localize.Validity.Script.unicode_to_subtag!(:unknown)
  end

  defp resolve_cldr_script_name([name | _rest]) do
    Localize.Validity.Script.unicode_to_subtag!(name)
  end

  defp find_likely_locale(script) do
    key = "und-#{script}"

    case Map.get(@likely_subtags, key) do
      nil ->
        # Fall back to "und" which maps to en-Latn-US
        case Map.get(@likely_subtags, "und") do
          nil ->
            {:ok, nil}

          %{language: language, script: sc, territory: territory} ->
            locale_id = Localize.Locale.locale_id_from(language, sc, territory, [])
            Localize.validate_locale(locale_id)
        end

      %{language: language, script: sc, territory: territory} ->
        locale_id = Localize.Locale.locale_id_from(language, sc, territory, [])
        Localize.validate_locale(locale_id)
    end
  end

  defp find_likely_locale(script, territory) do
    key = "und-#{script}-#{territory}"

    case Map.get(@likely_subtags, key) do
      nil ->
        find_likely_locale(script)

      %{language: language, script: sc, territory: terr} ->
        locale_id = Localize.Locale.locale_id_from(language, sc, terr, [])
        Localize.validate_locale(locale_id)
    end
  end

  @doc false
  def formats(formatting_locale) do
    case Localize.PersonName.FormatParser.formats_for(formatting_locale) do
      {:ok, formats} ->
        {:ok, formats}

      {:error, _} ->
        Localize.PersonName.FormatParser.formats_for(:und)
    end
  end

  # Per the spec, derive name order by:
  # 1. API-requested sorting order (handled by caller via :order option)
  # 2. PersonName preferredOrder field
  # 3. Walk the parent locale chain for the name ordering locale,
  #    checking nameOrderLocales at each step. At each locale L1,
  #    also check L2 = und-variant (language replaced by "und").
  @doc false
  def determine_name_order(name, name_locale, options) do
    case Localize.PersonName.FormatParser.formats_for(name_locale) do
      {:ok, formats} ->
        order =
          options[:order] ||
            name.preferred_order ||
            walk_locale_order(name_locale, formats.locale_order) ||
            @default_order

        {:ok, Keyword.put(options, :order, order)}

      {:error, _} ->
        order = options[:order] || name.preferred_order || @default_order
        {:ok, Keyword.put(options, :order, order)}
    end
  end

  # Walk the parent locale chain looking for a match in the
  # nameOrderLocales data. At each step, try the locale itself
  # and an "und" variant (language replaced by "und").
  defp walk_locale_order(locale, locale_order) do
    candidates = locale_chain_candidates(locale)

    Enum.find_value(candidates, fn candidate ->
      locale_order[candidate]
    end)
  end

  # Build the candidate list for nameOrderLocales matching.
  # For each locale in the parent chain, produce both the
  # locale itself and an und-variant. Candidates are strings
  # matching the format of nameOrderLocales entries (language
  # subtags, optionally with script and territory).
  defp locale_chain_candidates(%Localize.LanguageTag{} = tag) do
    chain = parent_chain(tag, [tag])

    Enum.flat_map(chain, fn locale_tag ->
      l1 = locale_candidate_string(locale_tag)

      l2 =
        if locale_tag.language != :und do
          locale_candidate_string(%{locale_tag | language: :und})
        else
          nil
        end

      if l2 && l2 != l1, do: [l1, l2], else: [l1]
    end)
  end

  # Convert a LanguageTag to the string format used in
  # nameOrderLocales entries (e.g., "de", "und-Latn", "und-JP").
  defp locale_candidate_string(%{language: lang, script: nil, territory: nil}) do
    to_string(lang)
  end

  defp locale_candidate_string(%{language: lang, script: script, territory: nil}) do
    "#{lang}-#{script}"
  end

  defp locale_candidate_string(%{language: lang, script: nil, territory: territory}) do
    "#{lang}-#{territory}"
  end

  defp locale_candidate_string(%{language: lang, script: script, territory: territory}) do
    "#{lang}-#{script}-#{territory}"
  end

  # Walk up the parent locale chain, collecting all locales
  # from the given tag up to (and including) "und".
  defp parent_chain(tag, acc) do
    case Localize.Locale.parent(tag) do
      {:ok, parent} ->
        parent_chain(parent, [parent | acc])

      {:error, _} ->
        Enum.reverse(acc)
    end
  end

  @doc false
  def select_format(name, formats, options) do
    keys = [:person_name, options[:order], options[:format], options[:usage], options[:formality]]

    case get_in(formats, keys) do
      nil ->
        {:error, "No format found for options #{inspect(options)}"}

      format_list ->
        format = choose_format(name, format_list)
        {:ok, format}
    end
  end

  defp choose_format(_name, [{_priority, format}]) do
    format
  end

  defp choose_format(name, formats) do
    {_populated, _unpopulated, _index, format} =
      Enum.reduce(formats, [], fn {index, format}, acc ->
        {fields, populated} = score(name, format)
        unpopulated = fields - populated

        [{-populated, unpopulated, index, format} | acc]
      end)
      |> Enum.sort(&compare_format/2)
      |> hd()

    format
  end

  defp compare_format(a, b) do
    format_to_term(a) < format_to_term(b)
  end

  defp format_to_term({populated, unpopulated, _index, format}) do
    string_format =
      format
      |> Enum.map(fn
        binary when is_binary(binary) -> binary
        list when is_list(list) -> Enum.map(list, &to_string/1)
      end)
      |> List.flatten()
      |> Enum.join()

    {populated, unpopulated, string_format}
  end

  @doc false
  def score(name, format) do
    Enum.reduce(format, {0, 0}, fn
      binary, {fields, populated} when is_binary(binary) ->
        {fields, populated}

      field, {fields, populated} ->
        fields = fields + 1
        if filled?(field, name), do: {fields, populated + 1}, else: {fields, populated}
    end)
  end

  defp filled?([:title | _], %{title: title}),
    do: is_binary(title)

  defp filled?([:given2 | _], %{other_given_names: other_given_names}),
    do: is_binary(other_given_names)

  defp filled?([:given, :informal | _], name),
    do: is_binary(name.informal_given_name) || is_binary(name.given_name)

  defp filled?([:given | _], %{given_name: given_name}),
    do: is_binary(given_name)

  defp filled?([:surname, :prefix | _], %{surname_prefix: surname_prefix}),
    do: is_binary(surname_prefix)

  defp filled?([:surname | _], %{surname: surname}),
    do: is_binary(surname)

  defp filled?([:surname2 | _], %{other_surnames: other_surnames}),
    do: is_binary(other_surnames)

  defp filled?([:generation | _], %{generation: generation}),
    do: is_binary(generation)

  defp filled?([:credentials | _], %{credentials: credentials}),
    do: is_binary(credentials)
end
