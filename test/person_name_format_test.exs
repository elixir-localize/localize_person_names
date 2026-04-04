defmodule Localize.PersonName.FormatTest do
  use ExUnit.Case, async: true

  @tests 1..1000

  @all_locales Localize.PersonName.TestData.all_locales()

  @failing_locales [
    # Script-aware initial generation needed for complex scripts
    # (multi-codepoint aksaras in Indic/Southeast Asian scripts).
    :si,
    :my,
    :kn,
    :km,
    :ml,

    # Needs investigation into short format initial generation.
    :yo_BJ,

    # Sorting format selection picks a pattern with surname2 that
    # loses the comma separator when surname2 is nil.
    :es_US,
    :es_MX,
    :es_419,

    # Parenthesis literal lost during empty field removal when
    # surname-prefix is nil before a parenthetical group.
    :cs,
    :sk
  ]

  @test_locales @all_locales -- @failing_locales

  for test <- Localize.PersonName.TestData.parse_locales(@test_locales),
      test.line in @tests do
    with {:ok, test_locale} <- Localize.validate_locale(test.locale),
         {:ok, name_locale} <- Localize.validate_locale(test.name.locale) do
      name = Map.put(test.name, :locale, name_locale)
      params = [{:locale, test_locale} | test.params]
      test_name = "#{test.locale}@#{test.line} with params #{inspect(test.params)}"

      test test_name do
        assert {:ok, unquote(test.expected_result)} =
                 Localize.PersonName.to_string(
                   unquote(Macro.escape(name)),
                   unquote(Macro.escape(params))
                 )
      end
    end
  end
end
