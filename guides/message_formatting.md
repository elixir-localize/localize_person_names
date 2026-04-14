# Using Localize.PersonName with Localize.Message

This guide shows how to integrate person name formatting into [Localize.Message](https://hexdocs.pm/localize) (ICU MessageFormat 2 / MF2) templates. Names carry formality, ordering, and locale-specific rules that the message formatter doesn't know about on its own, so the integration is done by registering a small MF2 function that delegates to `Localize.PersonName.to_string/2`.

To bring existing domain structs (e.g., `%User{}` or `%Customer{}`) into the formatter so they can be passed directly to message templates, see the [integrating existing name structs guide](integrating_existing_structs.md).

## Setting up the MF2 person name function

MF2 formatters are registered either per-call or application-wide. The implementation is a single module that implements `Localize.Message.Function`:

```elixir
defmodule MyApp.MF2.PersonNameFunction do
  @moduledoc """
  MF2 function that formats a `Localize.PersonName` (or any value
  with a `Localize.PersonName.Convertible` implementation, or any
  struct whose module implements the `Localize.PersonName`
  behaviour) using the supplied options.
  """

  @behaviour Localize.Message.Function

  @impl true
  def format(value, func_opts, options) do
    locale = Keyword.get(options, :locale)

    person_opts =
      []
      |> put_atom(:format, func_opts["format"])
      |> put_atom(:usage, func_opts["usage"])
      |> put_atom(:formality, func_opts["formality"])
      |> put_atom(:order, func_opts["order"])
      |> Keyword.put(:locale, locale)

    Localize.PersonName.to_string(value, person_opts)
  end

  defp put_atom(opts, _key, nil), do: opts
  defp put_atom(opts, key, value) when is_binary(value) do
    Keyword.put(opts, key, String.to_existing_atom(value))
  end
end
```

Register it globally in `config/config.exs`:

```elixir
config :localize, :mf2_functions, %{
  "personName" => MyApp.MF2.PersonNameFunction
}
```

From this point on, any MF2 template can use `{$someName :personName ...}` and the bound `someName` value will be formatted as a person name.

## Example 1 — Formal tax letter

This example shows a formal letter addressed to a taxpayer and signed by the Tax Commissioner. Both names are formatted as `long`, `formal` — the full names with titles — with different `usage` values to distinguish the salutation from the signature.

```elixir
{:ok, taxpayer} =
  Localize.PersonName.new(
    title: "Dr.",
    given_name: "Josephine",
    surname: "Nguyen",
    locale: "en-AU"
  )

{:ok, commissioner} =
  Localize.PersonName.new(
    title: "Mr.",
    given_name: "Christopher",
    surname: "Jordan",
    credentials: "AO",
    locale: "en-AU"
  )

message = """
  {{
  Dear {$taxpayer :personName format=long usage=addressing formality=formal},

  Our records show that you have an outstanding amount of
  {$amount :currency currency=AUD} owing to the
  Australian Taxation Office. Please arrange payment within 21 days
  to avoid further action.

  Yours sincerely,

  {$commissioner :personName format=long usage=referring formality=formal}
  Commissioner of Taxation
  }}
  """

{:ok, letter} =
  Localize.Message.format(
    message,
    %{
      "taxpayer" => taxpayer,
      "commissioner" => commissioner,
      "amount" => Decimal.new("1547.85")
    },
    locale: "en-AU",
    trim: true
  )

IO.puts(letter)
```

Output:

```
Dear Dr. Nguyen,

Our records show that you have an outstanding amount of
A$1,547.85 owing to the
Australian Taxation Office. Please arrange payment within 21 days
to avoid further action.

Yours sincerely,

Mr. Christopher Jordan AO
Commissioner of Taxation
```

Notice how the two `:personName` invocations produce different forms of the name depending on `usage`: `addressing` uses the short "Dr. Nguyen" form appropriate for a salutation, while `referring` uses the full "Mr. Christopher Jordan AO" form for the signature block.

## Example 2 — Informal birthday email

This example sends a casual happy-birthday email signed with a nickname. The date is formatted as day-and-month only (no year) using the `:date` function's `fields` option.

```elixir
{:ok, recipient} =
  Localize.PersonName.new(
    given_name: "Jonathan",
    informal_given_name: "Jono",
    surname: "Martinez",
    locale: "en-AU"
  )

{:ok, sender} =
  Localize.PersonName.new(
    given_name: "Alexandra",
    informal_given_name: "Alex",
    surname: "Kim",
    locale: "en-AU"
  )

message = """
  {{
  Hey {$recipient :personName format=short usage=addressing formality=informal},

  Happy birthday! Hope you have a brilliant day on
  {$birthday :date fields=MMMMd}.

  Cheers,
  {$sender :personName format=short usage=addressing formality=informal}
  }}
  """

{:ok, email} =
  Localize.Message.format(
    message,
    %{
      "recipient" => recipient,
      "sender" => sender,
      "birthday" => ~D[2026-06-14]
    },
    locale: "en-AU",
    trim: true
  )

IO.puts(email)
```

Output:

```
Hey Jono,

Happy birthday! Hope you have a brilliant day on
14 June.

Cheers,
Alex
```

The `informal_given_name` field of each person name is used because `formality=informal` was requested. The `:date` function's `fields=MMMMd` skeleton produces day + full month name with no year, in the locale's preferred order (day-then-month for en-AU; month-then-day for en-US).

## Passing domain structs directly

The MF2 function accepts anything `Localize.PersonName.to_string/2` accepts. That includes domain structs with a `Localize.PersonName.Convertible` implementation or the `Localize.PersonName` behaviour. No change to the function, configuration, or template is required — the binding just has to resolve to a convertible value:

```elixir
# customer is a %MyApp.Customer{} with a Convertible impl, see
# integrating_existing_structs.md
Localize.Message.format(
  "{{Welcome {$customer :personName formality=informal usage=addressing}}}",
  %{"customer" => customer},
  locale: "en-AU"
)
#=> {:ok, "Welcome Josephine"}
```
