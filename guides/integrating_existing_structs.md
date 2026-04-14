# Integrating existing name structs

The `Localize.PersonName` struct is one way to describe a name, but most applications already have a domain struct — a `%User{}`, `%Customer{}`, `%Employee{}`, etc. — with its own field names. This library offers two ways to make those structs work directly with the formatter, so you don't have to convert them manually at every call site:

1. The `Localize.PersonName.Convertible` **protocol** — a single function per struct that builds a `Localize.PersonName`. Works for any struct, including ones from third-party libraries.

2. The `Localize.PersonName` **behaviour** — eleven callbacks on the struct's module, each returning one field. Best when you own the module and want individual name fields accessible as module functions.

Both are recognised automatically by `Localize.PersonName.to_string/2`, `to_iodata/2`, and any MF2 function that delegates to them. If a struct has a protocol implementation, the formatter uses it; otherwise it falls back to the behaviour.

## The `Convertible` protocol (recommended)

The protocol has a single function, `to_person_name/1`, which returns a `Localize.PersonName` struct. Write the implementation anywhere in your project — it does not have to live in the struct's module.

```elixir
defmodule MyApp.Customer do
  defstruct [:id, :first_name, :last_name, :locale]
end

defimpl Localize.PersonName.Convertible, for: MyApp.Customer do
  def to_person_name(%MyApp.Customer{} = customer) do
    %Localize.PersonName{
      given_name: customer.first_name,
      surname: customer.last_name,
      locale: customer.locale
    }
  end
end
```

With the implementation compiled, the struct can be passed directly to the formatter:

```elixir
{:ok, tag} = Localize.validate_locale("en-AU")
customer = %MyApp.Customer{first_name: "Josephine", last_name: "Nguyen", locale: tag}

Localize.PersonName.to_string(customer,
  format: :long, usage: :referring, formality: :formal)
#=> {:ok, "Josephine Nguyen"}
```

### Why the protocol is usually the right choice

* **Works for third-party structs.** Protocol implementations can live in your application even when the struct is defined in a library you don't control. The behaviour requires callbacks in the struct's own module.

* **Keeps formatting concerns separate.** The conversion lives in its own file alongside other `Localize.PersonName.Convertible` implementations, rather than being scattered across domain modules.

* **Simpler integration.** One function instead of eleven callbacks. Derived fields are expressed naturally as Elixir expressions rather than requiring individual accessor functions.

* **Idiomatic Elixir.** Protocols are the standard mechanism for polymorphism across types.

### Deriving fields

The conversion function is ordinary Elixir code, so field derivation is straightforward:

```elixir
defimpl Localize.PersonName.Convertible, for: MyApp.Customer do
  def to_person_name(%MyApp.Customer{} = customer) do
    %Localize.PersonName{
      given_name: customer.first_name,
      informal_given_name: customer.nickname || customer.first_name,
      surname: customer.last_name,
      credentials: format_credentials(customer),
      locale: customer.locale
    }
  end

  defp format_credentials(%MyApp.Customer{degrees: nil}), do: nil
  defp format_credentials(%MyApp.Customer{degrees: []}), do: nil
  defp format_credentials(%MyApp.Customer{degrees: list}), do: Enum.join(list, ", ")
end
```

### Using Convertible inside MF2 templates

If the MF2 `:personName` function from the [message formatting guide](message_formatting.md) has been registered, any value with a protocol implementation is accepted as a template binding without further plumbing:

```elixir
Localize.Message.format(
  "{{Welcome {$customer :personName formality=informal usage=addressing}}}",
  %{"customer" => customer},
  locale: "en-AU"
)
#=> {:ok, "Welcome Josephine"}
```

## The `Localize.PersonName` behaviour

The behaviour declares eleven callbacks on the struct's module, each receiving the struct and returning one name part. This is the original integration path — keep it for cases where individual name fields need to be exposed as their own module functions (for reasons beyond this library), or when you prefer a one-module-per-struct layout.

```elixir
defmodule MyApp.Employee do
  @behaviour Localize.PersonName

  defstruct [
    :id,
    :honorific,
    :first_name,
    :preferred_name,
    :middle_names,
    :family_name,
    :post_nominals,
    :locale_tag
  ]

  @impl true
  def title(%__MODULE__{honorific: honorific}), do: honorific

  @impl true
  def given_name(%__MODULE__{first_name: first_name}), do: first_name

  @impl true
  def informal_given_name(%__MODULE__{preferred_name: preferred}), do: preferred

  @impl true
  def other_given_names(%__MODULE__{middle_names: middle}), do: middle

  @impl true
  def surname_prefix(%__MODULE__{}), do: nil

  @impl true
  def surname(%__MODULE__{family_name: family}), do: family

  @impl true
  def other_surnames(%__MODULE__{}), do: nil

  @impl true
  def generation(%__MODULE__{}), do: nil

  @impl true
  def credentials(%__MODULE__{post_nominals: post}), do: post

  @impl true
  def locale(%__MODULE__{locale_tag: tag}), do: tag

  @impl true
  def preferred_order(%__MODULE__{}), do: nil
end
```

### Using the struct directly

Structs implementing the behaviour are accepted by the formatter just like struct implementing the protocol — no manual conversion required:

```elixir
{:ok, tag} = Localize.validate_locale("en-AU")

employee = %MyApp.Employee{
  id: 12345,
  honorific: "Dr.",
  first_name: "Josephine",
  preferred_name: "Jo",
  family_name: "Nguyen",
  locale_tag: tag
}

Localize.PersonName.to_string(employee,
  format: :long, usage: :referring, formality: :formal)
#=> {:ok, "Dr. Josephine Nguyen"}

Localize.PersonName.to_string(employee,
  format: :short, usage: :addressing, formality: :informal)
#=> {:ok, "Jo"}
```

### How the dispatch works

When the formatter receives a struct, it resolves the conversion in this order:

1. **Already a `Localize.PersonName`** — used directly.
2. **The struct has a `Localize.PersonName.Convertible` implementation** — the protocol is called to produce a `Localize.PersonName`.
3. **Otherwise** — the struct's module is assumed to implement the `Localize.PersonName` behaviour, and `cast_to_person_name/1` invokes each callback in turn.

A struct with neither a protocol implementation nor the behaviour will raise `UndefinedFunctionError` on the first callback access — pick one of the two integration paths for any struct you intend to format.

## Choosing between the two

| Situation | Use |
|-----------|-----|
| You own the struct's module, and it's fine to add a dozen module functions to it | Either works; protocol is simpler |
| The struct is defined by a third-party library | Protocol |
| You want the conversion code to live in a dedicated file | Protocol |
| You want each name field as a standalone module function (e.g., `MyApp.Employee.given_name/1` used elsewhere in the app) | Behaviour |
| You're integrating many structs and want a consistent pattern | Protocol |

When in doubt, prefer the protocol. It's more flexible and requires less boilerplate.
