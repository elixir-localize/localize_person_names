defprotocol Localize.PersonName.Convertible do
  @moduledoc """
  Protocol for converting an arbitrary value to a
  `Localize.PersonName` struct.

  This protocol is an alternative to implementing the
  `Localize.PersonName` behaviour. Any value — typically a struct —
  can gain person name formatting support by providing a protocol
  implementation that returns a `t:Localize.PersonName.t/0`:

      defimpl Localize.PersonName.Convertible, for: MyApp.Customer do
        def to_person_name(customer) do
          %Localize.PersonName{
            given_name: customer.first_name,
            surname: customer.last_name,
            locale: customer.locale
          }
        end
      end

  With the implementation in place, formatter functions such as
  `Localize.PersonName.to_string/2` and
  `Localize.PersonName.to_iodata/2` accept the value directly:

      Localize.PersonName.to_string(customer, format: :long)

  The formatter first looks for a protocol implementation. If none is
  found, it falls back to the `Localize.PersonName` behaviour.

  ### When to choose the protocol over the behaviour

  The protocol is preferred when:

  * The struct's module is owned by a third party — protocol
    implementations can live in the consuming application without
    modifying the struct's module.

  * You want to keep formatting concerns in a dedicated file,
    separate from the struct definition.

  * The conversion is best expressed as a single function that
    builds a `Localize.PersonName` struct, rather than a handful of
    per-field accessor callbacks.

  The behaviour is preferred when the struct's module is under your
  control and you want each name field to be accessible as its own
  module function (for use cases beyond this library).

  """

  @doc """
  Converts `value` to a `t:Localize.PersonName.t/0` struct.
  """
  @spec to_person_name(t()) :: Localize.PersonName.t()
  def to_person_name(value)
end

defimpl Localize.PersonName.Convertible, for: Localize.PersonName do
  def to_person_name(person_name), do: person_name
end
