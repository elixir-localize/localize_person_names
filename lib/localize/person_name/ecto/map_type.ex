if Code.ensure_loaded?(Ecto.Type) do
  defmodule Localize.PersonName.Ecto.Map.Type do
    @moduledoc """
    An `Ecto.Type` storing a `t:Localize.PersonName.t/0` as `jsonb`.

    A person name is stored as a single JSON object rather than as a
    column per part. CLDR models a name as eleven optional parts — a
    surname prefix, other given names, a generation, credentials — and
    any given name uses few of them, so a wide table of mostly empty
    columns is the wrong shape. Parts that are `nil` are omitted from the
    stored object entirely.

    Storing the parts rather than a formatted string is what keeps the
    name formattable: the same record renders as "Dr. Herbert Fritz von
    Müller" or "Müller, Herbert" or "H. F. von Müller" depending on the
    locale, format and order asked for at display time.

    ### Schema

    `jsonb` is a built-in type, so nothing but the column is needed:

        # in a migration
        add :name, :map

        # in a schema
        field :name, Localize.PersonName.Ecto.Map.Type

    ### Stored form

    The name parts are stored as strings under their field names. Two
    fields are not strings and are converted:

    * `:preferred_order` is stored as its string form (`"given_first"`,
      `"surname_first"` or `"sorting"`) and loaded back to the atom.

    * `:locale` is stored as its canonical language tag (`"de-DE"`) and
      loaded back to a resolved `t:Localize.LanguageTag.t/0` through
      `Localize.validate_locale/1`, so the name carries the locale that
      governs its formatting.

    ### Casting

    `cast/1` accepts a person name struct, or a map keyed by either
    strings or atoms — which is what an HTML form supplies. Unknown keys
    are ignored, so a form carrying extra parameters does not fail.

    """

    use Ecto.Type

    alias Localize.LanguageTag
    alias Localize.PersonName

    @name_orders [:given_first, :surname_first, :sorting]

    @name_order_strings Map.new(@name_orders, fn order -> {Atom.to_string(order), order} end)

    @fields PersonName.__struct__() |> Map.from_struct() |> Map.keys()

    @field_strings Map.new(@fields, fn field -> {Atom.to_string(field), field} end)

    @impl true
    def type do
      :map
    end

    @impl true
    def cast(nil) do
      {:ok, nil}
    end

    def cast(%PersonName{} = name) do
      {:ok, name}
    end

    def cast(%{} = fields) do
      build(fields)
    end

    def cast(_other) do
      :error
    end

    @impl true
    def load(nil) do
      {:ok, nil}
    end

    def load(%{} = fields) do
      case build(fields) do
        {:ok, name} -> {:ok, name}
        {:error, _message} -> :error
      end
    end

    def load(_other) do
      :error
    end

    # Only the populated parts are stored. A name uses few of the eleven
    # parts, and a stored object of explicit nulls would be larger than
    # the name itself.
    @impl true
    def dump(nil) do
      {:ok, nil}
    end

    def dump(%PersonName{} = name) do
      dumped =
        name
        |> Map.from_struct()
        |> Enum.reject(fn {_field, value} -> is_nil(value) end)
        |> Map.new(fn {field, value} -> {Atom.to_string(field), dump_value(field, value)} end)

      {:ok, dumped}
    end

    def dump(_other) do
      :error
    end

    @impl true
    def embed_as(_format) do
      :dump
    end

    @impl true
    def equal?(left, right) do
      left == right
    end

    defp dump_value(:locale, %LanguageTag{} = locale) do
      LanguageTag.to_string(locale)
    end

    defp dump_value(:preferred_order, order) when is_atom(order) do
      Atom.to_string(order)
    end

    defp dump_value(_field, value) do
      value
    end

    # Accepts atom-keyed and string-keyed maps, ignoring anything that is
    # not a part of a name.
    defp build(fields) do
      fields
      |> Enum.reduce_while({:ok, %{}}, fn {key, value}, {:ok, acc} ->
        case field_name(key) do
          nil -> {:cont, {:ok, acc}}
          field -> load_field(field, value, acc)
        end
      end)
      |> case do
        {:ok, attributes} -> {:ok, struct(PersonName, attributes)}
        {:error, message} -> {:error, message: message}
      end
    end

    defp load_field(:locale, value, acc) do
      case validate_locale(value) do
        {:ok, locale} -> {:cont, {:ok, Map.put(acc, :locale, locale)}}
        :error -> {:halt, {:error, "invalid locale #{inspect(value)}"}}
      end
    end

    defp load_field(:preferred_order, value, acc) do
      case name_order(value) do
        {:ok, order} -> {:cont, {:ok, Map.put(acc, :preferred_order, order)}}
        :error -> {:halt, {:error, "invalid name order #{inspect(value)}"}}
      end
    end

    defp load_field(field, value, acc) do
      {:cont, {:ok, Map.put(acc, field, value)}}
    end

    defp validate_locale(nil), do: {:ok, nil}
    defp validate_locale(%LanguageTag{} = locale), do: {:ok, locale}

    defp validate_locale(locale) when is_binary(locale) or is_atom(locale) do
      case Localize.validate_locale(locale) do
        {:ok, language_tag} -> {:ok, language_tag}
        {:error, _exception} -> :error
      end
    end

    defp validate_locale(_locale), do: :error

    defp name_order(nil), do: {:ok, nil}
    defp name_order(""), do: {:ok, nil}
    defp name_order(order) when order in @name_orders, do: {:ok, order}

    defp name_order(order) when is_binary(order) do
      case Map.fetch(@name_order_strings, order) do
        {:ok, name_order} -> {:ok, name_order}
        :error -> :error
      end
    end

    defp name_order(_order), do: :error

    defp field_name(key) when is_atom(key) do
      if key in @fields, do: key
    end

    defp field_name(key) when is_binary(key) do
      Map.get(@field_strings, key)
    end

    defp field_name(_key) do
      nil
    end
  end
end
