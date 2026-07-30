defmodule Localize.PersonName.FormatParser do
  @moduledoc false

  # Loads person name format data from locale ETF files,
  # parses format strings into internal representations,
  # and caches the result in :persistent_term.

  alias Localize.Substitution

  @doc false
  @spec formats_for(atom() | Localize.LanguageTag.t()) :: {:ok, map()} | {:error, term()}
  def formats_for(%Localize.LanguageTag{cldr_locale_id: locale_id}) do
    formats_for(locale_id)
  end

  def formats_for(locale_id) when is_atom(locale_id) do
    cache_key = {__MODULE__, locale_id}

    case :persistent_term.get(cache_key, :not_found) do
      :not_found ->
        case load_and_parse(locale_id) do
          {:ok, formats} ->
            :persistent_term.put(cache_key, formats)
            {:ok, formats}

          error ->
            error
        end

      formats ->
        {:ok, formats}
    end
  end

  def formats_for(locale_id) when is_binary(locale_id) do
    formats_for(String.to_atom(locale_id))
  end

  @doc """
  Returns whether a locale has person name formatting data that
  differs from the root locale.

  Per the CLDR spec, a locale "has name formatting data" when its
  `nameOrderLocales` lists (`given_first` or `surname_first`) differ
  from root. This is used to decide whether the formatting locale
  should be switched to the name locale when scripts differ.

  """
  @spec has_formatting_data?(atom() | Localize.LanguageTag.t()) :: boolean()
  def has_formatting_data?(%Localize.LanguageTag{cldr_locale_id: locale_id}) do
    has_formatting_data?(locale_id)
  end

  def has_formatting_data?(locale_id) when is_atom(locale_id) do
    with {:ok, locale_data} <- Localize.Locale.get(locale_id, [:person_names]),
         {:ok, root_data} <- Localize.Locale.get(:und, [:person_names]) do
      locale_given = Map.get(locale_data || %{}, :given_first, [])
      locale_surname = Map.get(locale_data || %{}, :surname_first, [])
      root_given = Map.get(root_data || %{}, :given_first, [])
      root_surname = Map.get(root_data || %{}, :surname_first, [])

      locale_given != root_given or locale_surname != root_surname
    else
      _ -> false
    end
  end

  def has_formatting_data?(_), do: false

  defp load_and_parse(locale_id) do
    case Localize.Locale.get(locale_id, [:person_names]) do
      {:ok, locale_data} when is_map(locale_data) ->
        {:ok, parse_locale_data(locale_data)}

      {:ok, nil} ->
        {:error, "No person name data found for #{inspect(locale_id)}"}

      {:error, _} = error ->
        error
    end
  end

  defp parse_locale_data(locale_data) do
    initial = Substitution.parse(Map.get(locale_data, :initial, "{0}."))
    initial_sequence = Substitution.parse(Map.get(locale_data, :initial_sequence, "{0} {1}"))

    length = atomize_string(Map.get(locale_data, :length, "medium"))
    formality = atomize_string(Map.get(locale_data, :formality, "informal"))

    foreign_space_replacement = Map.get(locale_data, :foreign_space_replacement, " ")
    native_space_replacement = Map.get(locale_data, :native_space_replacement, " ")

    person_name =
      locale_data
      |> Map.get(:person_name, %{})
      |> parse_person_name_formats()

    given_order =
      locale_data
      |> Map.get(:given_first, [])
      |> Enum.map(fn language -> {to_string(language), :given_first} end)

    surname_order =
      locale_data
      |> Map.get(:surname_first, [])
      |> Enum.map(fn language -> {to_string(language), :surname_first} end)

    locale_order = Map.new(given_order ++ surname_order)

    %{
      initial: initial,
      initial_sequence: initial_sequence,
      length: length,
      formality: formality,
      foreign_space_replacement: foreign_space_replacement,
      native_space_replacement: native_space_replacement,
      person_name: person_name,
      locale_order: locale_order
    }
  end

  # Parse the nested person_name format structure:
  # order -> length -> usage -> formality -> [format_strings]
  defp parse_person_name_formats(person_name) do
    Map.new(person_name, fn {order, lengths} -> {order, parse_lengths(lengths)} end)
  end

  # The format data nests four levels deep — order, length, usage,
  # formality — with the formats themselves at the leaves. One function
  # per level keeps each one readable.
  defp parse_lengths(lengths) do
    Map.new(lengths, fn {length, usages} -> {length, parse_usages(usages)} end)
  end

  defp parse_usages(usages) do
    Map.new(usages, fn {usage, formalities} -> {usage, parse_formalities(formalities)} end)
  end

  defp parse_formalities(formalities) do
    Map.new(formalities, fn {formality_key, format_strings} ->
      {formality_key, parse_formats(format_strings)}
    end)
  end

  defp parse_formats(format_strings) do
    format_strings
    |> Enum.sort()
    |> Enum.map(&parse_format_string/1)
    |> Enum.with_index()
    |> Enum.map(fn {format, index} -> {index, format} end)
  end

  defp parse_format_string(format) when is_binary(format) do
    Regex.split(~r/{.*}/uU, format, trim: true, include_captures: true)
    |> Enum.map(fn
      "{" <> field ->
        field
        |> String.trim_trailing("}")
        |> String.split("-")
        |> Enum.map(&underscore/1)
        |> Enum.map(&String.to_atom/1)

      literal ->
        literal
    end)
  end

  defp atomize_string(value) when is_binary(value), do: String.to_atom(value)
  defp atomize_string(value) when is_atom(value), do: value

  # Convert camelCase to snake_case for field names.
  defp underscore(<<h, t::binary>>) when h >= ?A and h <= ?Z do
    <<h + 32>> <> do_underscore(t, h)
  end

  defp underscore(<<h, t::binary>>) do
    <<h>> <> do_underscore(t, h)
  end

  defp underscore(""), do: ""

  defp do_underscore(<<h, t::binary>>, _prev) when h >= ?A and h <= ?Z do
    <<?_, h + 32>> <> do_underscore(t, h)
  end

  defp do_underscore(<<h, t::binary>>, _prev) do
    <<h>> <> do_underscore(t, h)
  end

  defp do_underscore(<<>>, _prev) do
    <<>>
  end
end
