defmodule Localize.PersonName.FormatTest do
  use ExUnit.Case, async: true

  # si, my, ml (11 failures against the CLDR 49 data): Unicode.String
  # word-break segmentation produces different word boundaries than ICU
  # for multi-word names in Sinhala, Myanmar and Malayalam, leading to
  # incorrect initial generation for compound words. Khmer, excluded for
  # the same reason before CLDR 49, now passes.

  @tests 1..1000

  @all_locales Localize.PersonName.TestData.all_locales()

  @failing_locales [
    :si,
    :my,
    :ml
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
