defmodule SQLite.Nif do
  @moduledoc false

  @compile {:autoload, false}
  @on_load {:load_nif, 0}

  def load_nif do
    path = :filename.join(:code.priv_dir(:sqlite), ~c"sqlite3_nif")
    :erlang.load_nif(path, 0)
  end

  def open(_path, _flags), do: :erlang.nif_error(:not_loaded)
  def close(_db), do: :erlang.nif_error(:not_loaded)
  def execute(_db, _sql), do: :erlang.nif_error(:not_loaded)
  def prepare(_db, _sql), do: :erlang.nif_error(:not_loaded)
  def bind(_db, _stmt, _args), do: :erlang.nif_error(:not_loaded)
  def step(_db, _stmt), do: :erlang.nif_error(:not_loaded)
  def multi_step(_db, _stmt, _count), do: :erlang.nif_error(:not_loaded)
  def fetch_all_yielding(_db, _stmt), do: :erlang.nif_error(:not_loaded)
  def multi_bind_step(_db, _stmt, _args), do: :erlang.nif_error(:not_loaded)
  def finalize(_stmt), do: :erlang.nif_error(:not_loaded)
  def set_update_hook(_db, _pid), do: :erlang.nif_error(:not_loaded)
end
