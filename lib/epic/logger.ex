defmodule Epic.Logger do
  require Logger

  @logger_enabled true

  import Epic.Position, only: [line_col: 1]
  if @logger_enabled do
    @doc """
    log(parser)
    """
    def log_ctx(prefix, %{position: position, input: input}) do
      log_msg("#{prefix}: #{String.pad_trailing(line_col(position),4)} rest:\"#{input}\"")
    end

    def log_ctx(%{position: position, input: input}) do
      log_msg("#{String.pad_trailing(line_col(position),4)} rest:\"#{input}\"")
    end

    def log_msg(msg) do
      Logger.debug("\t#{msg}")
    end
  else
    def log_ctx(_msg, _ctx), do: nil
    def log_ctx(_ctx), do: nil
    def log_msg(_msg), do: nil
  end

end
