defmodule Localize.PersonName.Test do
  use ExUnit.Case, async: true

  for {name, person_name} <- Localize.PersonName.Names.names() do
    person_name = Macro.escape(person_name)

    test "Localize.PersonName.new/1 for #{name}" do
      attributes = unquote(person_name) |> Map.to_list() |> Keyword.delete(:__struct__)
      assert {:ok, _person_name} = Localize.PersonName.new(attributes)
    end
  end
end
