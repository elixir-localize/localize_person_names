defmodule Localize.PersonName.BadInputTest do
  use ExUnit.Case, async: true

  alias Localize.PersonName
  alias Localize.PersonName.Test.GarbageConversionStruct
  alias Localize.PersonName.Test.UnconvertibleStruct

  @bad_values [
    nil,
    "",
    :"",
    "José",
    42,
    %{given_name: "José"},
    [given_name: "José"],
    %UnconvertibleStruct{value: 1},
    %GarbageConversionStruct{value: 1},
    %PersonName{given_name: nil},
    %PersonName{given_name: 42},
    %PersonName{given_name: "José", locale: "zz-!!"},
    %PersonName{given_name: "José", locale: :""}
  ]

  setup_all do
    {:ok, name} = PersonName.new(given_name: "José", surname: "Valim", locale: "pt")
    %{name: name}
  end

  describe "to_string/2 and to_iodata/2 with a value that is not a formattable name" do
    for value <- @bad_values do
      @value Macro.escape(value)

      test "return an error for #{inspect(value)}" do
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
    for options <- [
          [format: :bogus],
          [usage: :nope],
          [formality: nil],
          [order: :sideways],
          [locale: "zz-!!"],
          [locale: :""],
          [locale: 42],
          [locale_switching: :maybe],
          %{format: :long},
          [:not_a_keyword]
        ] do
      @options Macro.escape(options)

      test "return an error for #{inspect(options)}", %{name: name} do
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
