defmodule Localize.PersonName.DocTest do
  use ExUnit.Case, async: true

  doctest Localize.PersonName
  doctest Localize.PersonName.Convertible
  doctest Localize.PersonNameError
end
