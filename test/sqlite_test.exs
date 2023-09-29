defmodule SQLiteTest do
  use ExUnit.Case

  describe "open" do
    test ":memory:" do
      assert {:ok, db} = SQLite.open(~c":memory:", _readonly = 0x1)
      on_exit(fn -> :ok = SQLite.close(db) end)
    end

    test "invalid flag" do
      assert {:error, %SQLite.Error{code: 21}} = SQLite.open(~c":memory:", _invalid = 0)
    end
  end

  describe "prepare" do
    setup do
      {:ok, db} = SQLite.open(~c":memory:", _readwrite = 0x2)
      on_exit(fn -> :ok = SQLite.close(db) end)
      {:ok, db: db}
    end

    test "select 1", %{db: db} do
      assert {:ok, stmt} = SQLite.prepare(db, "select 1")
      on_exit(fn -> :ok = SQLite.finalize(stmt) end)
    end

    test "selec 1", %{db: db} do
      assert {:error, reason} = SQLite.prepare(db, "selec 1")
      assert reason.code == 1
      assert reason.message == "near \"selec\": syntax error"
    end
  end

  describe "bind" do
    setup do
      {:ok, db} = SQLite.open(~c":memory:", _readonly = 0x1)
      on_exit(fn -> :ok = SQLite.close(db) end)
      {:ok, stmt} = SQLite.prepare(db, "select ?, ?, ?")
      on_exit(fn -> :ok = SQLite.finalize(stmt) end)
      {:ok, db: db, stmt: stmt}
    end

    test "int, text, double", %{db: db, stmt: stmt} do
      assert :ok = SQLite.bind(db, stmt, [1, "hey", 2.0])
    end

    @tag :skip
    test "too few args", %{db: db, stmt: stmt} do
      assert {:error, nil} = SQLite.bind(db, stmt, [])
      assert {:error, nil} = SQLite.bind(db, stmt, [1])
      assert {:error, nil} = SQLite.bind(db, stmt, [1, 1])
    end
  end

  describe "step" do
  end

  describe "multi_step" do
  end
end
