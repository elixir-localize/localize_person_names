defmodule Localize.PersonName do
  @moduledoc """
  Locale-aware person name formatting built on the Unicode CLDR
  person names specification.

  A person name is represented as a `t:Localize.PersonName.t/0`
  struct containing name parts (title, given name, surname, etc.)
  plus optional locale and ordering preferences.

  Formatting is driven by the locale's CLDR person name patterns,
  which vary by length (`:short`, `:medium`, `:long`), usage
  (`:addressing`, `:referring`, `:monogram`), formality (`:formal`,
  `:informal`), and name order (`:given_first`, `:surname_first`,
  `:sorting`).

  ## Primary API

  * `new/1` — creates a validated `Localize.PersonName` struct.

  * `to_string/2` — formats a person name as a string.

  * `to_string!/2` — formats a person name, raising on error.

  * `to_iodata/2` — formats a person name as iodata.

  * `to_iodata!/2` — formats a person name as iodata, raising on error.

  ## Integrating existing structs

  Any struct can participate in person name formatting in two ways:

  * Implement the `Localize.PersonName.Convertible` protocol —
    a single function that returns a `Localize.PersonName` struct.
    Recommended for most cases, including third-party structs.

  * Implement the `Localize.PersonName` behaviour — eleven
    callbacks on the struct's module, each returning one name
    field. Use this when the struct's module is under your control
    and you want individual name fields exposed as module functions.

  When the formatter receives a struct, it first looks for a
  `Convertible` protocol implementation; if none is found, it falls
  back to the behaviour callbacks via `cast_to_person_name/1`.

  """

  import Kernel, except: [to_string: 1]
  alias Localize.PersonName.Formatter

  @typedoc "Valid `:format` option."
  @type format :: :short | :medium | :long

  @typedoc "Valid `:order` option."
  @type name_order :: :given_first | :surname_first | :sorting

  @typedoc "Valid `:usage` option."
  @type usage :: :addressing | :referring | :monogram

  @typedoc "Valid `:formality` option."
  @type formality :: :formal | :informal

  @typedoc "An option to `to_string/2` and `to_iodata/2`."
  @type format_option ::
          {:format, format()}
          | {:order, name_order()}
          | {:usage, usage()}
          | {:formality, formality()}
          | {:locale, Localize.LanguageTag.t() | atom() | String.t()}
          | {:locale_switching, boolean()}

  @typedoc "A keyword list of options for `to_string/2` and `to_iodata/2`."
  @type format_options :: [format_option()]

  @doc "Return the title as a `t:String.t/0` or `nil` for the given struct."
  @callback title(name :: struct()) :: String.t() | nil

  @doc "Return the given name as a `t:String.t/0` or `nil` for the given struct."
  @callback given_name(name :: struct()) :: String.t() | nil

  @doc "Return the informal given name as a `t:String.t/0` or `nil` for the given struct."
  @callback informal_given_name(name :: struct()) :: String.t() | nil

  @doc "Return the other given names as a `t:String.t/0` or `nil` for the given struct."
  @callback other_given_names(name :: struct()) :: String.t() | nil

  @doc "Return the surname prefix as a `t:String.t/0` or `nil` for the given struct."
  @callback surname_prefix(name :: struct()) :: String.t() | nil

  @doc "Return the surname as a `t:String.t/0` or `nil` for the given struct."
  @callback surname(name :: struct()) :: String.t() | nil

  @doc "Return the other surnames as a `t:String.t/0` or `nil` for the given struct."
  @callback other_surnames(name :: struct()) :: String.t() | nil

  @doc "Return the generation as a `t:String.t/0` or `nil` for the given struct."
  @callback generation(name :: struct()) :: String.t() | nil

  @doc "Return the credentials as a `t:String.t/0` or `nil` for the given struct."
  @callback credentials(name :: struct()) :: String.t() | nil

  @doc "Return the locale or nil for the given struct."
  @callback locale(name :: struct()) :: Localize.LanguageTag.t() | nil

  @doc "Return the preferred name order for the given struct."
  @callback preferred_order(name :: struct()) :: name_order()

  @person_name [
    title: nil,
    given_name: nil,
    other_given_names: nil,
    informal_given_name: nil,
    surname_prefix: nil,
    surname: nil,
    other_surnames: nil,
    generation: nil,
    credentials: nil,
    preferred_order: nil,
    locale: nil
  ]

  # A name needs only a given name to be minimally viable.
  @non_string_attributes [:locale, :preferred_order]
  @string_attributes Keyword.keys(@person_name) -- @non_string_attributes
  @all_attributes @string_attributes ++ @non_string_attributes
  @valid_name_order Formatter.valid_name_order()

  defstruct @person_name

  @typedoc """
  A PersonName struct containing the fields supported
  for person name formatting.

  """
  @type t :: %__MODULE__{
          title: String.t() | nil,
          given_name: String.t() | nil,
          other_given_names: String.t() | nil,
          informal_given_name: String.t() | nil,
          surname_prefix: String.t() | nil,
          surname: String.t() | nil,
          other_surnames: String.t() | nil,
          generation: String.t() | nil,
          credentials: String.t() | nil,
          preferred_order: name_order() | nil,
          locale: Localize.LanguageTag.t() | nil
        }

  @typedoc "Standard error response."
  @type error_message() :: String.t() | Exception.t() | {module(), String.t()}

  @doc """
  Returns a `t:Localize.PersonName.t/0` struct crafted
  from a keyword list of attributes.

  ### Arguments

  * `attributes` is a keyword list or map of person name
    attributes that is used to construct a `t:Localize.PersonName.t/0`.
    Any other value returns an error.

  ### Options

  * `:given_name` is a person's given name. This is a required
    attribute. The value is any `t:String.t/0`.

  * `:title` is a person's title such as "Mr." or "Dr.".

  * `:other_given_names` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:informal_given_name` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:surname_prefix` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:surname` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:other_surnames` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:generation` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:credentials` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:locale` is a locale identifier or `t:Localize.LanguageTag.t/0`
    or `nil`. The default is `nil`.

  * `:preferred_order` is one of `:given_first`, `:surname_first`
    or `:sorting`. The default is `nil`, meaning that the name order
    is derived from the name's locale and the formatting locale.

  ### Returns

  * `{:ok, person_name_struct}` or

  * `{:error, reason}`.

  ### Examples

      iex> Localize.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
      {:ok,
       %Localize.PersonName{
         title: "Mr.",
         given_name: "José",
         other_given_names: nil,
         informal_given_name: nil,
         surname_prefix: nil,
         surname: "Valim",
         other_surnames: nil,
         generation: nil,
         credentials: "Ph.D.",
         preferred_order: nil,
         locale: %Localize.LanguageTag{
           language: :pt,
           language_subtags: [],
           script: :Latn,
           territory: :BR,
           language_variants: [],
           locale: %{},
           transform: %{},
           extensions: %{},
           private_use: [],
           requested_locale_id: "pt",
           canonical_locale_id: "pt",
           cldr_locale_id: :pt
         }
       }}

      iex> Localize.PersonName.new(surname: "Valim")
      {:error, "Person Name requires at least a :given_name"}

  """
  @spec new(attributes :: Keyword.t() | map()) :: {:ok, t()} | {:error, error_message()}
  def new(attributes \\ [])

  def new(attributes) when is_list(attributes) do
    validate_name(attributes)
  end

  def new(%{} = attributes) do
    attributes
    |> Map.delete(:__struct__)
    |> Map.to_list()
    |> validate_name()
  end

  def new(other) do
    {:error, "Person name attributes must be a keyword list or a map. Found #{inspect(other)}"}
  end

  @doc """
  Returns a formatted person name as a string.

  ### Arguments

  * `person_name` is a `t:Localize.PersonName.t/0` struct, or any
    struct with a `Localize.PersonName.Convertible` implementation
    or whose module implements the `Localize.PersonName` behaviour.
    Any other value returns an error.

  * `options` is a keyword list of options.

  ### Options

  * `:format` is the relative length of a formatted name.
    The valid values are `:short`, `:medium` and `:long`.
    The default is derived from the formatting locale's
    preferences.

  * `:usage` indicates how the formatted name is used.
    The valid values are `:addressing`, `:referring` or
    `:monogram`. The default is `:addressing`.

  * `:formality` indicates the formality of usage.
    The valid values are `:formal` and `:informal`.
    The default is derived from the formatting locale's
    preferences.

  * `:order` expresses preference for name part order.
    The valid values are `:given_first`, `:surname_first`
    and `:sorting`. The default is based on the person
    name struct and the formatting locale.

  * `:locale` is a locale identifier or
    `t:Localize.LanguageTag.t/0`. The default is
    `Localize.get_locale()`.

  * `:locale_switching` when `true`, switches the formatting
    locale to match the name's script when they differ. For
    example, a Latin-script name formatted in a Japanese locale
    will use Latin-based formatting patterns. The default is
    `false` for compatibility with the CLDR test data. See
    `TODO.md` for details.

  ### Returns

  * `{:ok, formatted_name}` or

  * `{:error, reason}`.

  ### Examples

      iex> {:ok, jose} = Localize.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
      iex> Localize.PersonName.to_string(jose)
      {:ok, "José"}

      iex> {:ok, jose} = Localize.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
      iex> Localize.PersonName.to_string(jose, format: :long, formality: :formal, usage: :referring)
      {:ok, "Mr. José Valim Ph.D."}

  """
  @spec to_string(name :: term(), options :: format_options()) ::
          {:ok, String.t()} | {:error, error_message()}
  def to_string(name, options \\ []) do
    with {:ok, iodata} <- to_iodata(name, options) do
      {:ok, :erlang.iolist_to_binary(iodata)}
    end
  end

  @doc """
  Same as `to_string/2` but raises on error.

  ### Examples

      iex> {:ok, jose} = Localize.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
      iex> Localize.PersonName.to_string!(jose)
      "José"

      iex> {:ok, jose} = Localize.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
      iex> Localize.PersonName.to_string!(jose, format: :long, formality: :formal, usage: :referring)
      "Mr. José Valim Ph.D."

  """
  @spec to_string!(name :: term(), options :: format_options()) ::
          String.t() | no_return()
  def to_string!(name, options \\ []) do
    case to_string(name, options) do
      {:ok, formatted_name} -> formatted_name
      {:error, reason} -> raise_error(reason)
    end
  end

  @doc """
  Returns a formatted person name as iodata.

  Accepts the same arguments and options as `to_string/2`.

  ### Returns

  * `{:ok, iodata}` or

  * `{:error, reason}`.

  ### Examples

      iex> {:ok, jose} = Localize.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
      iex> Localize.PersonName.to_iodata(jose)
      {:ok, ["José"]}

      iex> {:ok, jose} = Localize.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
      iex> Localize.PersonName.to_iodata(jose, format: :long, formality: :formal)
      {:ok, ["Mr.", " ", "Valim"]}

  """
  @spec to_iodata(person_name :: term(), options :: format_options()) ::
          {:ok, :erlang.iodata()} | {:error, error_message()}
  def to_iodata(person_name, options \\ []) do
    with :ok <- validate_options_list(options),
         {:ok, person_name} <- maybe_cast_name(person_name),
         locale = Keyword.get(options, :locale, Localize.get_locale()),
         {:ok, formatting_locale} <- Localize.validate_locale(locale) do
      Formatter.to_iodata(person_name, formatting_locale, options)
    end
  end

  @doc """
  Same as `to_iodata/2` but raises on error.

  """
  @spec to_iodata!(person_name :: term(), options :: format_options()) ::
          :erlang.iodata() | no_return()
  def to_iodata!(person_name, options \\ []) do
    case to_iodata(person_name, options) do
      {:ok, iodata} -> iodata
      {:error, reason} -> raise_error(reason)
    end
  end

  @doc """
  Casts any struct that implements the `Localize.PersonName`
  behaviour into a `t:Localize.PersonName.t/0` struct.

  ### Arguments

  * `struct` is any struct that implements the
    `Localize.PersonName` behaviour.

  ### Returns

  * A `t:Localize.PersonName.t/0` struct.

  """
  @spec cast_to_person_name(struct()) :: t()
  def cast_to_person_name(%module{} = name) do
    %__MODULE__{
      title: module.title(name),
      given_name: module.given_name(name),
      other_given_names: module.other_given_names(name),
      informal_given_name: module.informal_given_name(name),
      surname_prefix: module.surname_prefix(name),
      surname: module.surname(name),
      other_surnames: module.other_surnames(name),
      generation: module.generation(name),
      credentials: module.credentials(name),
      preferred_order: module.preferred_order(name),
      locale: module.locale(name)
    }
  end

  @behaviour __MODULE__

  @impl Localize.PersonName
  @doc false
  def title(%__MODULE__{title: title}) do
    title
  end

  @impl Localize.PersonName
  @doc false
  def given_name(%__MODULE__{given_name: given_name}) do
    given_name
  end

  @impl Localize.PersonName
  @doc false
  def other_given_names(%__MODULE__{other_given_names: other_given_names}) do
    other_given_names
  end

  @impl Localize.PersonName
  @doc false
  def informal_given_name(%__MODULE__{informal_given_name: informal_given_name}) do
    informal_given_name
  end

  @impl Localize.PersonName
  @doc false
  def surname_prefix(%__MODULE__{surname_prefix: surname_prefix}) do
    surname_prefix
  end

  @impl Localize.PersonName
  @doc false
  def surname(%__MODULE__{surname: surname}) do
    surname
  end

  @impl Localize.PersonName
  @doc false
  def other_surnames(%__MODULE__{other_surnames: other_surnames}) do
    other_surnames
  end

  @impl Localize.PersonName
  @doc false
  def generation(%__MODULE__{generation: generation}) do
    generation
  end

  @impl Localize.PersonName
  @doc false
  def credentials(%__MODULE__{credentials: credentials}) do
    credentials
  end

  @impl Localize.PersonName
  @doc false
  def locale(%__MODULE__{locale: locale}) do
    locale
  end

  @impl Localize.PersonName
  @doc false
  def preferred_order(%__MODULE__{preferred_order: preferred_order}) do
    preferred_order
  end

  # Resolves any accepted input to a validated person name struct. The
  # Convertible protocol is consulted before the behaviour, as the
  # moduledoc describes. Every result is validated like `new/1` input,
  # because structs can be built directly or returned by user code.
  defp maybe_cast_name(%__MODULE__{} = name) do
    validate_person_name(name)
  end

  defp maybe_cast_name(%module{} = name) do
    cond do
      # apply/3 keeps the type checker from treating user implementations as
      # unreachable: at compile time the consolidated protocol knows only the
      # Localize.PersonName implementation.
      implementation = Localize.PersonName.Convertible.impl_for(name) ->
        # credo:disable-for-next-line Credo.Check.Refactor.Apply
        converted_name = apply(implementation, :to_person_name, [name])
        validate_converted_name(converted_name, module)

      function_exported?(module, :given_name, 1) ->
        name
        |> cast_to_person_name()
        |> validate_person_name()

      true ->
        {:error,
         "#{inspect(module)} has no Localize.PersonName.Convertible implementation " <>
           "and does not implement the Localize.PersonName behaviour"}
    end
  end

  defp maybe_cast_name(other) do
    {:error,
     "Expected a Localize.PersonName struct or a struct that can be converted to one. " <>
       "Found #{inspect(other)}"}
  end

  defp validate_converted_name(%__MODULE__{} = name, _module) do
    validate_person_name(name)
  end

  defp validate_converted_name(other, module) do
    {:error,
     "The Localize.PersonName.Convertible implementation for #{inspect(module)} " <>
       "must return a Localize.PersonName struct. Found #{inspect(other)}"}
  end

  defp validate_person_name(%__MODULE__{} = name) do
    name
    |> Map.from_struct()
    |> Map.to_list()
    |> validate_name()
  end

  defp validate_options_list(options) do
    if Keyword.keyword?(options) do
      :ok
    else
      {:error, "Options must be a keyword list. Found #{inspect(options)}"}
    end
  end

  defp validate_name(attributes) when is_list(attributes) do
    validated =
      Enum.reduce_while(attributes, %__MODULE__{}, fn
        {attribute, value}, acc when attribute in @string_attributes and is_binary(value) ->
          {:cont, Map.put(acc, attribute, value)}

        {attribute, nil}, acc when attribute in @all_attributes ->
          {:cont, Map.put(acc, attribute, nil)}

        {:locale, %Localize.LanguageTag{} = locale}, acc ->
          {:cont, Map.put(acc, :locale, locale)}

        {:locale, _locale_reference}, acc ->
          case validate_locale(attributes) do
            {:ok, locale} -> {:cont, Map.put(acc, :locale, locale)}
            other -> {:halt, other}
          end

        {:preferred_order, preferred_order}, acc when preferred_order in @valid_name_order ->
          {:cont, Map.put(acc, :preferred_order, preferred_order)}

        {attribute, _value}, _acc when attribute not in @all_attributes ->
          {:halt,
           {:error,
            "Invalid attribute found: #{inspect(attribute)}. Valid attributes are #{inspect(@all_attributes)}"}}

        {attribute, value}, _acc ->
          {:halt,
           {:error,
            "Invalid attribute value found for #{inspect(attribute)}. Found #{inspect(value)}"}}

        other, _acc ->
          {:halt, {:error, "Invalid attribute found: #{inspect(other)}"}}
      end)

    case validated do
      {:error, reason} ->
        {:error, reason}

      %__MODULE__{} = person_name ->
        validate_given_name_presence(person_name)
    end
  end

  defp validate_locale(options) do
    locale = Keyword.get(options, :locale, Localize.get_locale())
    Localize.validate_locale(locale)
  end

  defp validate_given_name_presence(%{} = person_name) do
    if person_name.given_name do
      {:ok, person_name}
    else
      {:error, "Person Name requires at least a :given_name"}
    end
  end

  @spec raise_error(error_message()) :: no_return()
  defp raise_error(reason) when is_binary(reason) do
    raise Localize.PersonNameError, reason
  end

  defp raise_error(%{__exception__: true} = exception) do
    raise exception
  end

  defp raise_error({exception, message}) do
    raise exception, message
  end
end
