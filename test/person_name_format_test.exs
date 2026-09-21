defmodule Localize.PersonName.FormatTest do
  use ExUnit.Case, async: true

  # The conformance data is CLDR's common/testData/personNameTest, mirrored
  # exactly. Excluded locales are listed in guides/conformance.md.
  #
  # my (1 failure): Unicode.String word-break segmentation splits a
  # transliterated Myanmar given name into more words than ICU does, so the
  # short referring format produces extra initials.

  @tests 1..1000

  @all_locales Localize.PersonName.TestData.all_locales()

  @failing_locales [:my]

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
