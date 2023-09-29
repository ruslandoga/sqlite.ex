defmodule SQLite do
  @moduledoc """
  Documentation for `SQLite`.
  """

  alias SQLite.{Nif, Error}

  @type db :: reference
  @type stmt :: reference

  @spec open(String.t(), pos_integer) :: {:ok, db} | {:error, Error.t()}
  def open(path, flags), do: wrap_error(Nif.open(path, flags))

  @spec close(db) :: :ok | {:error, Error.t()}
  def close(db), do: wrap_error(Nif.close(db))

  @spec execute(db, iodata) :: :ok | {:error, Error.t()}
  def execute(db, sql), do: wrap_error(Nif.execute(db, sql))

  @spec prepare(db, iodata) :: {:ok, stmt} | {:error, Error.t()}
  def prepare(db, sql), do: wrap_error(Nif.prepare(db, sql))

  @spec bind(db, stmt, [term]) :: :ok | {:error, Error.t()}
  def bind(db, stmt, args), do: wrap_error(Nif.bind(db, stmt, args))

  @spec finalize(stmt) :: :ok | {:error, Error.t()}
  def finalize(stmt), do: wrap_error(Nif.finalize(stmt))

  defp wrap_error({:error = e, rc}), do: {e, Error.exception(code: rc)}
  defp wrap_error({:error = e, rc, msg}), do: {e, Error.exception(code: rc, message: msg)}
  defp wrap_error(success), do: success
end
