defmodule Localize.PersonName.Test.ProtocolStruct do
  @moduledoc false
  defstruct [:first, :last, :locale]
end

defimpl Localize.PersonName.Convertible, for: Localize.PersonName.Test.ProtocolStruct do
  alias Localize.PersonName.Test.ProtocolStruct

  def to_person_name(%ProtocolStruct{first: first, last: last, locale: locale}) do
    %Localize.PersonName{given_name: first, surname: last, locale: locale}
  end
end

defmodule Localize.PersonName.Test.BehaviourStruct do
  @moduledoc false
  @behaviour Localize.PersonName
  defstruct [:given, :family, :lang]

  @impl true
  def title(_), do: nil

  @impl true
  def given_name(%__MODULE__{given: g}), do: g

  @impl true
  def informal_given_name(_), do: nil

  @impl true
  def other_given_names(_), do: nil

  @impl true
  def surname_prefix(_), do: nil

  @impl true
  def surname(%__MODULE__{family: f}), do: f

  @impl true
  def other_surnames(_), do: nil

  @impl true
  def generation(_), do: nil

  @impl true
  def credentials(_), do: nil

  @impl true
  def locale(%__MODULE__{lang: l}), do: l

  @impl true
  def preferred_order(_), do: nil
end
