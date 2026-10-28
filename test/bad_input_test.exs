defmodule Localize.PersonName.BadInputTest do
  use ExUnit.Case, async: true

  alias Localize.PersonName
  alias Localize.PersonName.Test.GarbageConversionStruct
  alias Localize.PersonName.Test.UnconvertibleStruct

  # Each case carries a short label: ExUnit limits a test name to 255
  # characters, and a struct's inspect output is longer than that.
  @bad_values [
    {"nil", nil},
    {"an empty string", ""},
    {"the empty atom", :""},
    {"a string", "José"},
    {"an integer", 42},
    {"a plain map", %{given_name: "José"}},
    {"a keyword list", [given_name: "José"]},
    {"a struct with no conversion", %UnconvertibleStruct{value: 1}},
    {"a struct whose conversion returns garbage", %GarbageConversionStruct{value: 1}},
    {"a PersonName with no given name", %PersonName{given_name: nil}},
    {"a PersonName with an integer given name", %PersonName{given_name: 42}},
    {"a PersonName with a malformed locale string",
     %PersonName{given_name: "José", locale: "zz-!!"}},
    {"a PersonName with the empty atom as locale", %PersonName{given_name: "José", locale: :""}}
  ]

  setup_all do
    {:ok, name} = PersonName.new(given_name: "José", surname: "Valim", locale: "pt")
    %{name: name}
  end

  describe "to_string/2 and to_iodata/2 with a value that is not a formattable name" do
    for {label, value} <- @bad_values do
      @value Macro.escape(value)

      test "return an error for #{label}" do
        assert {:error, _reason} = PersonName.to_string(@value)
        assert {:error, _reason} = PersonName.to_iodata(@value)
      end
    end
  end

  describe "the bang variants" do
    test "raise Localize.PersonNameError rather than an internal error" do
      assert_raise Localize.PersonNameError, fn -> PersonName.to_string!(nil) end

      assert_raise Localize.PersonNameError, fn ->
        PersonName.to_iodata!(%UnconvertibleStruct{})
      end
    end
  end

  describe "to_string/2 with invalid options" do
    for {label, options} <- [
          {"an unknown format", [format: :bogus]},
          {"an unknown usage", [usage: :nope]},
          {"a nil formality", [formality: nil]},
          {"an unknown order", [order: :sideways]},
          {"a malformed locale string", [locale: "zz-!!"]},
          {"the empty atom as locale", [locale: :""]},
          {"an integer locale", [locale: 42]},
          {"a non-boolean locale_switching", [locale_switching: :maybe]},
          {"options given as a map", %{format: :long}},
          {"options that are not a keyword list", [:not_a_keyword]}
        ] do
      @options Macro.escape(options)

      test "return an error for #{label}", %{name: name} do
        assert {:error, _reason} = PersonName.to_string(name, @options)
      end
    end
  end

  describe "new/1" do
    test "returns an error for a value that is neither a keyword list nor a map" do
      assert {:error, _reason} = PersonName.new(nil)
      assert {:error, _reason} = PersonName.new("José")
      assert {:error, _reason} = PersonName.new([:not_a_keyword])
    end

    test "builds a struct from a map" do
      assert {:ok, %PersonName{given_name: "José"}} = PersonName.new(%{given_name: "José"})
    end
  end

  describe "the MF2 function" do
    test "returns an error for a struct with no conversion" do
      assert {:error, _reason} =
               Localize.Message.format(
                 "{{Hi {$name :personName}}}",
                 %{"name" => %UnconvertibleStruct{}},
                 locale: "en",
                 functions: %{"personName" => PersonName.MF2}
               )
    end
  end

  describe "String.Chars and Localize.Chars" do
    test "String.Chars renders an unformattable name as an empty string" do
      assert to_string(%PersonName{given_name: nil}) == ""
    end

    test "Localize.Chars returns an exception struct as its error" do
      assert {:error, %Localize.PersonNameError{}} =
               Localize.Chars.to_string(%PersonName{given_name: nil})
    end
  end
end
