defmodule Localize.PersonNameError do
  @moduledoc """
  Exception raised when person name formatting fails.

  Raised by `Localize.PersonName.to_string!/2` and
  `Localize.PersonName.to_iodata!/2` when the underlying formatting
  operation returns `{:error, reason}`.

  """

  @typedoc "A `Localize.PersonNameError` exception struct."
  @type t :: %__MODULE__{message: String.t() | nil}

  defexception [:message]

  @doc """
  Builds a `Localize.PersonNameError` exception from a string message.

  ### Arguments

  * `message` is a `t:String.t/0` describing the formatting failure.

  ### Returns

  * A `t:Localize.PersonNameError.t/0` struct.

  """
  @impl true
  def exception(message) do
    %__MODULE__{message: message}
  end
end
