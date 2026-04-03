defmodule Localize.PersonNameError do
  @moduledoc """
  Exception raised when person name formatting fails.

  """

  defexception [:message]

  @impl true
  def exception(message) do
    %__MODULE__{message: message}
  end
end
