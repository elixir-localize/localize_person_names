defmodule Localize.PersonName.StringCharsTest do
  use ExUnit.Case, async: true

  test "String.Chars protocol works for PersonName" do
    {:ok, name} = Localize.PersonName.new(given_name: "José", surname: "Valim")
    assert is_binary(Kernel.to_string(name))
  end

  for {fixture_name, person_name} <- Localize.PersonName.Names.names() do
    person_name = Macro.escape(person_name)

    test "String.Chars for #{fixture_name}" do
      attributes = unquote(person_name) |> Map.to_list() |> Keyword.delete(:__struct__)

      case Localize.PersonName.new(attributes) do
        {:ok, name} ->
          assert is_binary(Kernel.to_string(name))

        {:error, _reason} ->
          :skip
      end
    end
  end
end
