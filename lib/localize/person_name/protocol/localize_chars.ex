defimpl Localize.Chars, for: Localize.PersonName do
  @moduledoc false

  def to_string(value), do: to_string(value, [])

  def to_string(value, options) do
    case Localize.PersonName.to_string(value, options) do
      {:ok, formatted_name} ->
        {:ok, formatted_name}

      {:error, reason} when is_binary(reason) ->
        {:error, Localize.PersonNameError.exception(reason)}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
