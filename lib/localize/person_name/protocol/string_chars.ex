defimpl String.Chars, for: Localize.PersonName do
  # String.Chars has no error channel, and raising here would crash any
  # interpolation of a malformed name, so a name that cannot be formatted
  # renders as an empty string. Use Localize.PersonName.to_string/2 to see
  # the reason.
  def to_string(name) do
    case Localize.PersonName.to_string(name, locale: Localize.get_locale()) do
      {:ok, formatted_name} -> formatted_name
      {:error, _reason} -> ""
    end
  end
end
