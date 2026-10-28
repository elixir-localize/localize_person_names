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

      assert {:format_error, {:formatter_failed, message}} =
               Localize.Message.Interpreter.format_list(
                 parsed,
                 %{"name" => "not a struct"},
                 functions: @functions
               )

      assert message =~ "requires a PersonName struct"
    end
  end
end

defmodule Localize.PersonName.MF2DirectTest do
  use ExUnit.Case, async: true

  alias Localize.PersonName.MF2

  setup_all do
    {:ok, name} =
      Localize.PersonName.new(
        title: "Dr.",
        given_name: "Josephine",
        other_given_names: "Margaret",
        surname: "Nguyen",
        credentials: "PhD",
        locale: "en-AU"
      )

    %{name: name}
  end

  describe "format/3 option mapping" do
    test "formats with no locale option at all", %{name: name} do
      assert {:ok, formatted} = MF2.format(name, %{}, [])
      assert is_binary(formatted)
    end

    test "reads function options keyed by atom as well as by string", %{name: name} do
      assert {:ok, by_atom} = MF2.format(name, %{format: "long"}, locale: :en)
      assert {:ok, by_string} = MF2.format(name, %{"format" => "long"}, locale: :en)
      assert by_atom == by_string
    end

    for {option, values} <- [
          {"format", ~w(short medium long)},
          {"formality", ~w(formal informal)},
          {"usage", ~w(addressing referring monogram)},
          {"order", ~w(givenFirst surnameFirst sorting)}
        ],
        value <- values do
      # A sorting order exists only for referring usage in CLDR data.
      test "accepts #{option}=#{value}", %{name: name} do
        function_options = Map.put_new(%{unquote(option) => unquote(value)}, "usage", "referring")
        assert {:ok, formatted} = MF2.format(name, function_options, locale: :en)

        assert is_binary(formatted)
      end
    end

    for option <- ~w(format formality usage order) do
      test "rejects an unknown #{option} value without creating an atom", %{name: name} do
        value = "neverAnAtom" <> unquote(option)
        assert {:error, _reason} = MF2.format(name, %{unquote(option) => value}, locale: :en)
        assert_raise ArgumentError, fn -> String.to_existing_atom(value) end
      end
    end

    test "rejects a value that is not a struct" do
      assert {:error, reason} = MF2.format("Josephine", %{}, locale: :en)
      assert reason =~ "requires a PersonName struct"
    end
  end
end
