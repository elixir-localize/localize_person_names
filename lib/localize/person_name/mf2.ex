defmodule Localize.PersonName.MF2 do
  @moduledoc """
  MF2 custom function for locale-aware person name formatting.

  Implements `Localize.Message.Function` so that `%Localize.PersonName{}`
  structs can be formatted directly inside MF2 messages:

      {$name :personName}
      {$name :personName format=long formality=formal}

  ## Registration

  ### Application config (recommended for most projects)

      # config/config.exs
      config :localize, :mf2_functions, %{
        "personName" => Localize.PersonName.MF2
      }

  ### Per-call

      Localize.Message.format(
        "{$name :personName format=long}",
        %{"name" => person},
        locale: :en,
        functions: %{"personName" => Localize.PersonName.MF2}
      )

  ## Supported MF2 options

  | MF2 option | Maps to | Values |
  |---|---|---|
  | `format` | `:format` | `short`, `medium`, `long` |
  | `formality` | `:formality` | `formal`, `informal` |
  | `usage` | `:usage` | `addressing`, `referring`, `monogram` |
  | `order` | `:order` | `givenFirst`, `surnameFirst`, `sorting` |

  The `:locale` is inherited from the MF2 message's interpreter
  options and does not need to be specified as an MF2 function
  option.

  """

  @behaviour Localize.Message.Function

  @impl true
  def format(value, function_options, options) when is_struct(value) do
    localize_options = build_options(function_options, options)
    Localize.PersonName.to_string(value, localize_options)
  end

  def format(value, _function_options, _options) do
    {:error,
     "the :personName function requires a PersonName struct, " <>
       "got #{inspect(value)}"}
  end

  defp build_options(function_options, options) do
    locale_options =
      case Keyword.get(options, :locale) do
        nil -> []
        locale -> [locale: locale]
      end

    locale_options
    |> map_option(function_options, "format", :format, &parse_format/1)
    |> map_option(function_options, "formality", :formality, &parse_formality/1)
    |> map_option(function_options, "usage", :usage, &parse_usage/1)
    |> map_option(function_options, "order", :order, &parse_order/1)
  end

  # MF2 option keys may arrive as atoms or as strings. The names are
  # literals of this module, so the atoms already exist.
  defp map_option(options, function_options, mf2_name, option_name, parser) do
    value =
      Map.get(function_options, String.to_existing_atom(mf2_name)) ||
        Map.get(function_options, mf2_name)

    if is_nil(value) do
      options
    else
      [{option_name, parser.(value)} | options]
    end
  end

  # Unrecognised values are passed through unchanged so that
  # Localize.PersonName.to_string/2 rejects them. They are never
  # converted to atoms: option values come from message templates.
  defp parse_format("short") do
    :short
  end

  defp parse_format("medium") do
    :medium
  end

  defp parse_format("long") do
    :long
  end

  defp parse_format(other) do
    other
  end

  defp parse_formality("formal") do
    :formal
  end

  defp parse_formality("informal") do
    :informal
  end

  defp parse_formality(other) do
    other
  end

  defp parse_usage("addressing") do
    :addressing
  end

  defp parse_usage("referring") do
    :referring
  end

  defp parse_usage("monogram") do
    :monogram
  end

  defp parse_usage(other) do
    other
  end

  defp parse_order("givenFirst") do
    :given_first
  end

  defp parse_order("surnameFirst") do
    :surname_first
  end

  defp parse_order("sorting") do
    :sorting
  end

  defp parse_order(other) do
    other
  end
end
