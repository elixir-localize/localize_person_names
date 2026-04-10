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
  def format(value, func_opts, options) when is_struct(value) do
    localize_opts = build_options(func_opts, options)
    Localize.PersonName.to_string(value, localize_opts)
  end

  def format(value, _func_opts, _options) do
    {:error,
     "the :personName function requires a PersonName struct, " <>
       "got #{inspect(value)}"}
  end

  defp build_options(func_opts, options) do
    opts = []
    opts = if locale = Keyword.get(options, :locale), do: [{:locale, locale} | opts], else: opts
    opts = map_option(opts, func_opts, "format", :format, &parse_format/1)
    opts = map_option(opts, func_opts, "formality", :formality, &parse_formality/1)
    opts = map_option(opts, func_opts, "usage", :usage, &parse_usage/1)
    opts = map_option(opts, func_opts, "order", :order, &parse_order/1)
    opts
  end

  defp map_option(opts, func_opts, mf2_name, opt_name, parser) do
    # MF2 option keys may be atomized (when a matching existing atom
    # is found) or kept as strings. Check both forms.
    value = Map.get(func_opts, String.to_atom(mf2_name)) || Map.get(func_opts, mf2_name)

    case value do
      nil -> opts
      val -> [{opt_name, parser.(val)} | opts]
    end
  end

  defp parse_format("short"), do: :short
  defp parse_format("medium"), do: :medium
  defp parse_format("long"), do: :long
  defp parse_format(other) when is_binary(other), do: String.to_atom(other)
  defp parse_format(other), do: other

  defp parse_formality("formal"), do: :formal
  defp parse_formality("informal"), do: :informal
  defp parse_formality(other) when is_binary(other), do: String.to_atom(other)
  defp parse_formality(other), do: other

  defp parse_usage("addressing"), do: :addressing
  defp parse_usage("referring"), do: :referring
  defp parse_usage("monogram"), do: :monogram
  defp parse_usage(other) when is_binary(other), do: String.to_atom(other)
  defp parse_usage(other), do: other

  defp parse_order("givenFirst"), do: :given_first
  defp parse_order("surnameFirst"), do: :surname_first
  defp parse_order("sorting"), do: :sorting
  defp parse_order(other) when is_binary(other), do: String.to_atom(other)
  defp parse_order(other), do: other
end
