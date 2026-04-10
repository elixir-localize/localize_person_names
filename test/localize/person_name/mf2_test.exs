defmodule Localize.PersonName.MF2Test do
  use ExUnit.Case, async: true

  @functions %{"personName" => Localize.PersonName.MF2}

  defp format(message, bindings, options \\ []) do
    options = Keyword.merge([functions: @functions], options)
    Localize.Message.format(message, bindings, options)
  end

  describe ":personName MF2 function — default options" do
    test "formats a person name with default options" do
      {:ok, jose} =
        Localize.PersonName.new(given_name: "José", surname: "Valim", locale: "pt")

      assert {:ok, name} = format("{$name :personName}", %{"name" => jose})
      assert is_binary(name)
      assert String.contains?(name, "José")
    end
  end

  describe ":personName MF2 function — format option" do
    test "format=long includes full name parts" do
      {:ok, jose} =
        Localize.PersonName.new(
          title: "Mr.",
          given_name: "José",
          surname: "Valim",
          credentials: "Ph.D.",
          locale: "pt"
        )

      assert {:ok, name} =
               format(
                 ~S({$name :personName format=long formality=formal usage=referring}),
                 %{"name" => jose},
                 locale: :en
               )

      assert String.contains?(name, "José")
      assert String.contains?(name, "Valim")
    end

    test "format=short produces a shorter form" do
      {:ok, jose} =
        Localize.PersonName.new(given_name: "José", surname: "Valim", locale: "pt")

      assert {:ok, name} =
               format(~S({$name :personName format=short}), %{"name" => jose}, locale: :en)

      assert is_binary(name)
    end
  end

  describe ":personName MF2 function — embedded in a message" do
    test "works inside surrounding text" do
      {:ok, jose} =
        Localize.PersonName.new(given_name: "José", surname: "Valim", locale: "pt")

      assert {:ok, result} =
               format(
                 "Hello, {$name :personName}!",
                 %{"name" => jose},
                 locale: :en
               )

      assert String.starts_with?(result, "Hello, ")
      assert String.ends_with?(result, "!")
      assert String.contains?(result, "José")
    end
  end

  describe ":personName MF2 function — error handling" do
    test "non-struct operand returns an error" do
      {:ok, parsed} = Localize.Message.Parser.parse("{$name :personName}")

      assert {:format_error, reason} =
               Localize.Message.Interpreter.format_list(
                 parsed,
                 %{"name" => "not a struct"},
                 functions: @functions
               )

      assert reason =~ "requires a PersonName struct"
    end
  end
end
