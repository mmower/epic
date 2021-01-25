defmodule Epic.Logger do
  require Logger

  @logger_enabled true

  import Epic.Position

  if @logger_enabled do
    def log(parser, ctx) do
      Logger.debug("#{String.pad_trailing(line_col(ctx.position),4)} #{parser} \"#{ctx.input}\"")
    end

    def log_msg(msg) do
      Logger.debug("\t#{msg}")
    end
  else
    def log(_parser, _ctx), do: nil
    def log_msg(_msg), do: nil
  end

end
