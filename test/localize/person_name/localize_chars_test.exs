defmodule Localize.PersonName.LocalizeCharsTest do
  use ExUnit.Case, async: true

  describe "Localize.Chars implementation for Localize.PersonName" do
    test "to_string/1 formats a person name with default options" do
      {:ok, jose} =
        Localize.PersonName.new(
          given_name: "José",
          surname: "Valim",
          locale: "pt"
        )

      assert {:ok, name} = Localize.Chars.to_string(jose)
      assert is_binary(name)
      assert String.contains?(name, "José")
    end

    test "to_string/2 accepts formatting options" do
      {:ok, jose} =
        Localize.PersonName.new(
          title: "Mr.",
          given_name: "José",
          surname: "Valim",
          credentials: "Ph.D.",
          locale: "pt"
        )

      assert {:ok, name} =
               Localize.Chars.to_string(jose,
                 format: :long,
                 formality: :formal,
                 usage: :referring,
                 locale: :en
               )

      assert String.contains?(name, "José")
      assert String.contains?(name, "Valim")
    end

    test "Localize.to_string delegates through Localize.Chars" do
      {:ok, jose} =
        Localize.PersonName.new(given_name: "José", surname: "Valim", locale: "pt")

      assert Localize.to_string(jose) == Localize.Chars.to_string(jose)
    end

    test "Localize.to_string! returns a raw string" do
      {:ok, jose} =
        Localize.PersonName.new(given_name: "José", surname: "Valim", locale: "pt")

      assert is_binary(Localize.to_string!(jose))
    end
  end
end
