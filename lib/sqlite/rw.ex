defmodule SQLite.RW do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def query(pid, sql, args) do
  end
end
