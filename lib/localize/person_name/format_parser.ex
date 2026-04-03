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
    Map.new(person_name, fn {order, lengths} ->
      parsed_lengths =
        Map.new(lengths, fn {length, usages} ->
          parsed_usages =
            Map.new(usages, fn {usage, formalities} ->
              parsed_formalities =
                Map.new(formalities, fn {formality_key, format_strings} ->
                  parsed_formats =
                    format_strings
                    |> Enum.sort()
                    |> Enum.map(&parse_format_string/1)
                    |> Enum.with_index()
                    |> Enum.map(fn {format, index} -> {index, format} end)

                  {formality_key, parsed_formats}
                end)

              {usage, parsed_formalities}
            end)

          {length, parsed_usages}
        end)

      {order, parsed_lengths}
    end)
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
