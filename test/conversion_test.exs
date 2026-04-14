defmodule Localize.PersonName.ConversionTest do
  use ExUnit.Case, async: true

  alias Localize.PersonName.Test.{BehaviourStruct, ProtocolStruct}

  setup do
    {:ok, tag} = Localize.validate_locale("en-AU")
    {:ok, locale: tag}
  end

  @format_opts [format: :long, usage: :referring, formality: :formal]

  describe "Convertible protocol" do
    test "formats a struct via the protocol implementation", %{locale: locale} do
      struct = %ProtocolStruct{first: "Alice", last: "Smith", locale: locale}
      assert {:ok, "Alice Smith"} = Localize.PersonName.to_string(struct, @format_opts)
    end

    test "identity impl for Localize.PersonName", %{locale: locale} do
      {:ok, name} =
        Localize.PersonName.new(given_name: "Carol", surname: "Lee", locale: locale)

      assert ^name = Localize.PersonName.Convertible.to_person_name(name)
    end
  end

  describe "Behaviour fallback" do
    test "formats a struct via the behaviour callbacks", %{locale: locale} do
      struct = %BehaviourStruct{given: "Bob", family: "Jones", lang: locale}
      assert {:ok, "Bob Jones"} = Localize.PersonName.to_string(struct, @format_opts)
    end
  end
end
