defmodule SQLite do
  @moduledoc """
  Basic wrapper for SQLite.
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

  @spec step(db, stmt) :: {:row, [term]} | :done | {:error, Error.t()}
  def step(db, stmt), do: wrap_error(Nif.step(db, stmt))

  @spec finalize(stmt) :: :ok | {:error, Error.t()}
  def finalize(stmt), do: wrap_error(Nif.finalize(stmt))

  @spec multi_step(db, stmt, pos_integer) ::
          {:rows, [[term]]} | {:done, [[term]]} | {:error, Error.t()}
  def multi_step(db, stmt, max_rows) do
    case Nif.multi_step(db, stmt, max_rows) do
      {:rows, rows} -> {:rows, :lists.reverse(rows)}
      {:done, rows} -> {:done, :lists.reverse(rows)}
      {:error, _reason} = error -> error
    end
  end

  @spec multi_bind_step(db, stmt, [[term]]) :: :ok | {:error, Error.t()}
  def multi_bind_step(db, stmt, args), do: wrap_error(Nif.multi_bind_step(db, stmt, args))


  @spec set_update_hook(db, pid) :: :ok
  def set_update_hook(db, pid), do: wrap_error(Nif.set_update_hook(db, pid))

  @spec set_commit_hook(db, pid) :: :ok
  def set_commit_hook(_db, _pid), do: raise "todo"

  defp wrap_error({:error = e, rc}), do: {e, Error.exception(code: rc)}
  defp wrap_error({:error = e, rc, msg}), do: {e, Error.exception(code: rc, message: msg)}
  defp wrap_error(success), do: success

  @spec fetch_all(db, stmt, pos_integer) :: {:ok, [[term]]} | {:error, Error.t()}
  def fetch_all(db, stmt, max_rows) when is_reference(stmt) do
    {:ok, try_fetch_all(db, stmt, max_rows)}
  catch
    :throw, {:error, _reason} = error -> error
  end

  @spec fetch_all(db, iodata, [term], pos_integer) :: {:ok, [[term]]} | {:error, Error.t()}
  def fetch_all(db, sql, args, max_rows) do
    with {:ok, stmt} <- prepare(db, sql) do
      try do
        with :ok <- bind(db, stmt, args) do
          fetch_all(db, stmt, max_rows)
        end
      after
        :ok = finalize(stmt)
      end
    end
  end

  defp try_fetch_all(db, stmt, max_rows) do
    case multi_step(db, stmt, max_rows) do
      {:done, rows} -> rows
      {:rows, rows} -> rows ++ try_fetch_all(db, stmt, max_rows)
      {:error, _reason} = error -> throw(error)
    end
  end

  @spec insert_all(db, stmt | iodata, [[term]]) :: :ok | {:error, Error.t()}
  def insert_all(db, stmt, rows) when is_reference(stmt) do
    :ok = execute(db, "savepoint __insert_all")

    with :ok <- multi_bind_step(db, stmt, rows),
         :ok = ok <- execute(db, "commit") do
      ok
    else
      {:error, _reason} = error ->
        :ok = execute(db, "rollback")
        error
    end
  end

  def insert_all(db, sql, rows) do
    with {:ok, stmt} <- prepare(db, sql) do
      try do
        insert_all(db, stmt, rows)
      after
        :ok = finalize(stmt)
      end
    end
  end

  def transact(db, f) when is_function(f, 0) do
    :ok = execute(db, "begin")

    try do
      result = f.()
      :ok = execute(db, "commit")
      result
    rescue
      e ->
        :ok = execute(db, "rollback")
        raise e
    end
  end
end
