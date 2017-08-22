defmodule Membrane.Mixins.Log do
  @moduledoc """
  Mixin for logging using simple functions such as info/1, debug/1 in other
  modules.
  """

  use Membrane.Helper

  @doc false
  defmacro __using__(args) do
    default_tags = args |> Keyword.get(:tags, []) |> Helper.listify
    quote location: :keep do
      alias Membrane.Log.Router

      @doc false
      defmacro log(level, message, tags) do
        config = Application.get_env(:membrane_core, Membrane.Logger, [])
        router_level = config |> Keyword.get(:level, :debug)
        router_level_val = router_level |> Router.level_to_val

        quote location: :keep do
          level_val = unquote(level) |> Router.level_to_val
          if level_val >= unquote(router_level_val) do
            Router.send_log(unquote(level),  unquote(message), Membrane.Time.monotonic_time, unquote(tags))
          end
        end
      end

      @doc false
      defmacro info(message, tags \\ []) do
        default_tags = unquote default_tags
        quote location: :keep do
          log(:info, unquote(message), unquote(tags) ++ unquote(default_tags))
        end
      end

      @doc false
      defmacro warn(message, tags \\ []) do
        default_tags = unquote default_tags
        quote location: :keep do
          log(:warn, unquote(message), unquote(tags) ++ unquote(default_tags))
        end
      end

      def warn_error(message, reason) do
        warn """
        Encountered an error:
        #{message}
        Reason: #{inspect reason}
        Stacktrace:
        #{Membrane.Helper.stacktrace}
        """
        {:error, reason}
      end

      def or_warn_error({:ok, value}, _msg), do: {:ok, value}
      def or_warn_error({:error, reason}, msg), do: warn_error(msg, reason)


      @doc false
      defmacro debug(message, tags \\ []) do
        default_tags = unquote default_tags
        quote location: :keep do
          log(:debug, unquote(message), unquote(tags) ++ unquote(default_tags))
        end
      end
    end
  end
end
