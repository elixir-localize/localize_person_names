defmodule Localize.PersonName.ApiTest do
  use ExUnit.Case, async: true

  alias Localize.PersonName
  alias Localize.PersonName.FormatParser

  setup_all do
    {:ok, name} =
      PersonName.new(
        title: "Dr.",
        given_name: "Josephine",
        other_given_names: "Margaret",
        informal_given_name: "Jo",
        surname_prefix: "van",
        surname: "Nguyen",
        other_surnames: "Tran",
        generation: "Jr.",
        credentials: "PhD",
        preferred_order: :given_first,
        locale: "en-AU"
      )

    %{name: name}
  end

  describe "the behaviour callbacks on the native struct" do
    test "each accessor returns its field", %{name: name} do
      assert PersonName.title(name) == "Dr."
      assert PersonName.given_name(name) == "Josephine"
      assert PersonName.other_given_names(name) == "Margaret"
      assert PersonName.informal_given_name(name) == "Jo"
      assert PersonName.surname_prefix(name) == "van"
      assert PersonName.surname(name) == "Nguyen"
      assert PersonName.other_surnames(name) == "Tran"
      assert PersonName.generation(name) == "Jr."
      assert PersonName.credentials(name) == "PhD"
      assert PersonName.preferred_order(name) == :given_first
      assert %Localize.LanguageTag{} = PersonName.locale(name)
    end

    test "cast_to_person_name/1 round-trips the native struct", %{name: name} do
      assert PersonName.cast_to_person_name(name) == name
    end
  end

  describe "the bang variants" do
    test "return the value on success", %{name: name} do
      assert is_binary(PersonName.to_string!(name, format: :long, usage: :referring))
      assert is_list(PersonName.to_iodata!(name, format: :long, usage: :referring))
    end

    test "raise Localize.PersonNameError for a string reason", %{name: name} do
      assert_raise Localize.PersonNameError, fn -> PersonName.to_string!(name, format: :bogus) end
    end

    test "raise the exception when the reason is one", %{name: name} do
      assert_raise Localize.InvalidLocaleError, fn ->
        PersonName.to_iodata!(name, locale: "zz-!!")
      end
    end
  end

  describe "new/1" do
    test "accepts a native struct and revalidates it", %{name: name} do
      assert {:ok, ^name} = PersonName.new(name)
      assert {:error, _reason} = PersonName.new(%PersonName{given_name: nil})
    end

    test "rejects an unknown attribute and a bad preferred order" do
      assert {:error, reason} = PersonName.new(given_name: "Jo", nickname: "J")
      assert reason =~ "Invalid attribute found"
      assert {:error, _reason} = PersonName.new(given_name: "Jo", preferred_order: :sideways)
    end
  end

  describe "locale switching" do
    test "a Latin-script name in a Japanese locale switches to a Latin locale", %{name: name} do
      assert {:ok, switched} =
               PersonName.to_string(name, locale: :ja, locale_switching: true, format: :long)

      assert {:ok, unswitched} =
               PersonName.to_string(name, locale: :ja, locale_switching: false, format: :long)

      assert switched != unswitched
      refute String.contains?(switched, "・")
    end
  end

  describe "FormatParser" do
    test "formats_for/1 returns an error for a locale without person name data" do
      assert {:error, _reason} = FormatParser.formats_for(:"zz-ZZ-not-a-locale")
    end

    test "has_formatting_data?/1 is false for anything that is not a locale with data" do
      refute FormatParser.has_formatting_data?(nil)
      refute FormatParser.has_formatting_data?(:"zz-ZZ-not-a-locale")
      refute FormatParser.has_formatting_data?("en")
    end

    test "has_formatting_data?/1 reflects whether a locale overrides root's name order" do
      assert FormatParser.has_formatting_data?(:ja)
      refute FormatParser.has_formatting_data?(:und)
    end
  end

  describe "Localize.Chars" do
    test "passes an exception reason through unchanged", %{name: name} do
      assert {:error, %Localize.InvalidLocaleError{}} =
               Localize.Chars.to_string(name, locale: "zz-!!")
    end
  end

  describe "formatter edges the conformance data does not reach" do
    test "valid_name_order/0 lists the three orders" do
      assert Localize.PersonName.Formatter.valid_name_order() == [
               :given_first,
               :surname_first,
               :sorting
             ]
    end

    test "locale switching between two Latin-script locales keeps the formatting locale", %{
      name: name
    } do
      assert {:ok, switched} = PersonName.to_string(name, locale: :fr, locale_switching: true)
      assert {:ok, unswitched} = PersonName.to_string(name, locale: :fr, locale_switching: false)
      assert switched == unswitched
    end

    test "locale switching to a name locale that carries formatting data uses it" do
      {:ok, name} = PersonName.new(given_name: "太郎", surname: "山田", locale: "ja")

      assert {:ok, switched} =
               PersonName.to_string(name, locale: :en, locale_switching: true, format: :long)

      assert {:ok, japanese} = PersonName.to_string(name, locale: :ja, format: :long)
      assert switched == japanese
    end

    test "locale switching from a name locale without data resolves a likely locale" do
      {:ok, name} = PersonName.new(given_name: "Анна", surname: "Иванова", locale: "und-Cyrl")

      assert {:ok, switched} =
               PersonName.to_string(name, locale: :en, locale_switching: true, format: :long)

      assert is_binary(switched)
    end

    test "a Greek monogram strips the accent" do
      {:ok, name} = PersonName.new(given_name: "Άννα", surname: "Παπαδοπούλου", locale: "el")
      assert {:ok, monogram} = PersonName.to_string(name, locale: :el, usage: :monogram)
      refute String.contains?(monogram, "Ά")
      assert String.contains?(monogram, "Α")
    end

    test "a sorting order with addressing usage has no pattern and is an error", %{name: name} do
      assert {:error, reason} = PersonName.to_string(name, order: :sorting, usage: :addressing)
      assert reason =~ "No format found"
    end
  end
end
