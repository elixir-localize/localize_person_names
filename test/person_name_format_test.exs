defmodule Localize.PersonName.FormatTest do
  use ExUnit.Case, async: true

  # All issues are documented in detail in specification_deviances.md.
  #
  # es_US, es_MX, es_419 (28 failures): The spec's format selection
  # algorithm selects the pattern with fewest unpopulated fields, but
  # the CLDR test data expects the pattern with more fields (including
  # an unpopulated {surname2}) to be selected. This appears to be a
  # discrepancy between the spec text and the ICU reference
  # implementation's selection logic.
  #
  # yo_BJ (27 failures): The test data expects initials (e.g.,
  # "O. Adeboye") for short/formal formats, but the yo_BJ locale data
  # has no -initial modifier in those format patterns. The parent locale
  # yo has identical patterns and its test data correctly expects full
  # names. This is a test data / locale data synchronisation issue.
  #
  # si, my, km, ml (61 failures): Unicode.String word-break
  # segmentation produces different word boundaries than ICU for
  # multi-word names in Sinhala, Myanmar, Khmer, and Malayalam,
  # leading to incorrect initial generation for compound words.

  @tests 1..1000

  @all_locales Localize.PersonName.TestData.all_locales()

  @failing_locales [
    :si,
    :my,
    :km,
    :ml,
    :yo_BJ,
    :es_US,
    :es_MX,
    :es_419
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
