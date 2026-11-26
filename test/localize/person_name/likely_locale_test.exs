defmodule Localize.PersonName.LikelyLocaleTest do
  # A name with no locale takes the likely locale of its script, by TR35's
  # Add Likely Subtags on `und-<script>`. It was read from Localize's internal
  # likely-subtags table by string keys, which localize 1.6.1 replaced with
  # tuples, so every such name failed with "No locale resolved for script".
  use ExUnit.Case, async: true

  alias Localize.PersonName
  alias Localize.PersonName.Formatter

  @names [
    {"Ada", "Lovelace", :en},
    {"Иван", "Петров", :ru},
    {"Νίκος", "Παπαδόπουλος", :el},
    {"太郎", "山田", :zh}
  ]

  setup_all do
    {:ok, english} = Localize.validate_locale(:en)
    %{english: english}
  end

  describe "a name without a locale" do
    for {given_name, surname, expected} <- @names do
      @given_name given_name
      @surname surname
      @expected expected

      test "#{@given_name} #{@surname} takes the likely locale of its script", %{english: english} do
        {:ok, name} = PersonName.new(given_name: @given_name, surname: @surname)

        assert {:ok, %Localize.LanguageTag{cldr_locale_id: @expected}} =
                 Formatter.derive_name_locale(name, english)
      end
    end

    test "formats in a formatting locale of another script" do
      {:ok, latin} = PersonName.new(given_name: "Ada", surname: "Lovelace")
      {:ok, cyrillic} = PersonName.new(given_name: "Иван", surname: "Петров")

      assert PersonName.to_string(latin, locale: :en) == {:ok, "Ada"}
      assert PersonName.to_string(cyrillic, locale: :en) == {:ok, "Иван"}
    end
  end
end
