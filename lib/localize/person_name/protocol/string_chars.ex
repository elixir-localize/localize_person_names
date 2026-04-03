defimpl String.Chars, for: Localize.PersonName do
  def to_string(name) do
    locale = Localize.get_locale()
    Localize.PersonName.to_string!(name, locale: locale)
  end
end
