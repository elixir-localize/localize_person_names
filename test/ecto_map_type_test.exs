defmodule Localize.PersonName.Ecto.Map.TypeTest do
  use ExUnit.Case, async: true

  alias Localize.PersonName
  alias Localize.PersonName.Ecto.Map.Type

  doctest Localize.PersonName.Ecto.Map.Type

  defp name do
    %PersonName{
      title: "Dr.",
      given_name: "Herbert",
      other_given_names: "Fritz",
      surname_prefix: "von",
      surname: "Müller"
    }
  end

  describe "type/0" do
    test "stores as a map, which is jsonb on PostgreSQL" do
      assert Type.type() == :map
    end
  end

  describe "cast/1" do
    test "passes a person name struct through" do
      assert Type.cast(name()) == {:ok, name()}
    end

    test "casts a string-keyed map, as a form supplies" do
      assert {:ok, cast} = Type.cast(%{"given_name" => "Herbert", "surname" => "Müller"})
      assert cast.given_name == "Herbert"
      assert cast.surname == "Müller"
    end

    test "casts an atom-keyed map" do
      assert {:ok, cast} = Type.cast(%{given_name: "Zeynep", surname: "Yılmaz"})
      assert cast.given_name == "Zeynep"
    end

    test "ignores keys that are not name parts" do
      assert {:ok, cast} = Type.cast(%{"surname" => "Müller", "_csrf_token" => "xyz"})
      assert cast.surname == "Müller"
    end

    test "casts nil" do
      assert Type.cast(nil) == {:ok, nil}
    end

    test "refuses a value that is not a map" do
      assert Type.cast("Herbert Müller") == :error
    end
  end

  describe "the locale part" do
    test "dumps as its canonical language tag" do
      {:ok, locale} = Localize.validate_locale("de-DE")
      {:ok, dumped} = Type.dump(%PersonName{surname: "Müller", locale: locale})

      assert dumped["locale"] == "de-DE"
    end

    test "loads back into a resolved language tag" do
      assert {:ok, loaded} = Type.load(%{"surname" => "Müller", "locale" => "de-DE"})
      assert %Localize.LanguageTag{} = loaded.locale
      assert Localize.LanguageTag.to_string(loaded.locale) == "de-DE"
    end

    test "casts a locale given as a string" do
      assert {:ok, cast} = Type.cast(%{"surname" => "Müller", "locale" => "de-DE"})
      assert %Localize.LanguageTag{} = cast.locale
    end

    test "an invalid locale is an error" do
      assert {:error, message: message} = Type.cast(%{"locale" => "this-is-not-a-locale"})
      assert message =~ "invalid locale"

      assert Type.load(%{"locale" => "this-is-not-a-locale"}) == :error
    end
  end

  describe "the preferred_order part" do
    test "dumps as a string and loads back to the atom" do
      {:ok, dumped} = Type.dump(%PersonName{surname: "Müller", preferred_order: :surname_first})
      assert dumped["preferred_order"] == "surname_first"

      assert {:ok, loaded} = Type.load(dumped)
      assert loaded.preferred_order == :surname_first
    end

    test "accepts each valid order" do
      for order <- [:given_first, :surname_first, :sorting] do
        assert {:ok, cast} = Type.cast(%{"preferred_order" => Atom.to_string(order)})
        assert cast.preferred_order == order
      end
    end

    test "an unknown order is an error rather than a new atom" do
      assert {:error, message: message} = Type.cast(%{"preferred_order" => "sideways"})
      assert message =~ "invalid name order"
    end
  end

  describe "dump/1" do
    test "dumps the parts as strings" do
      assert {:ok, dumped} = Type.dump(name())

      assert dumped["given_name"] == "Herbert"
      assert dumped["surname_prefix"] == "von"
      assert dumped["surname"] == "Müller"
    end

    # A name uses few of the eleven parts, so storing explicit nulls
    # would make the stored object larger than the name.
    test "omits parts that are nil" do
      {:ok, dumped} = Type.dump(name())

      refute Map.has_key?(dumped, "credentials")
      refute Map.has_key?(dumped, "generation")
      refute Map.has_key?(dumped, "locale")
      assert map_size(dumped) == 5
    end

    test "dumps nil" do
      assert Type.dump(nil) == {:ok, nil}
    end

    test "refuses a value that is not a person name" do
      assert Type.dump(%{surname: "Müller"}) == :error
    end
  end

  describe "load/1" do
    test "parts absent from the stored object load as nil" do
      {:ok, loaded} = Type.load(%{"surname" => "Müller"})

      assert loaded.given_name == nil
      assert loaded.credentials == nil
    end

    # A part removed from the struct in a later version must not break
    # rows written by an earlier one.
    test "ignores stored keys that are no longer parts" do
      assert {:ok, loaded} = Type.load(%{"surname" => "Müller", "retired_part" => "x"})
      assert loaded.surname == "Müller"
    end

    test "loads nil and refuses a non-map" do
      assert Type.load(nil) == {:ok, nil}
      assert Type.load("Müller") == :error
    end
  end

  describe "round trips" do
    test "dump and load preserve every populated part" do
      {:ok, dumped} = Type.dump(name())
      {:ok, loaded} = Type.load(dumped)

      assert loaded == name()
    end

    test "a name with a locale and order round trips" do
      {:ok, locale} = Localize.validate_locale("de-DE")
      original = %PersonName{name() | locale: locale, preferred_order: :surname_first}

      {:ok, dumped} = Type.dump(original)
      {:ok, loaded} = Type.load(dumped)

      assert loaded == original
    end

    test "a loaded name still formats" do
      {:ok, dumped} = Type.dump(name())
      {:ok, loaded} = Type.load(dumped)

      assert {:ok, formatted} = PersonName.to_string(loaded, locale: :en)
      assert formatted =~ "Herbert"
    end
  end

  describe "embed_as/1 and equal?/2" do
    test "embeds the dumped form" do
      assert Type.embed_as(:json) == :dump
    end

    test "identical names are equal" do
      assert Type.equal?(name(), name())
      refute Type.equal?(name(), %PersonName{name() | surname: "Schmidt"})
    end
  end
end
