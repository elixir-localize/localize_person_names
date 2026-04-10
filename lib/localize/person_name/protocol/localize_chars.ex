defimpl Localize.Chars, for: Localize.PersonName do
  @moduledoc false

  def to_string(value), do: Localize.PersonName.to_string(value, [])
  def to_string(value, options), do: Localize.PersonName.to_string(value, options)
end
