defmodule SQLiteTest do
  use ExUnit.Case
  # import Bitwise

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
    test "select 1, '2', 3.0" do
      {:ok, db} = SQLite.open(~c":memory:", _readonly = 0x1)
      on_exit(fn -> :ok = SQLite.close(db) end)
      {:ok, stmt} = SQLite.prepare(db, "select 1, '2', 3.0")
      on_exit(fn -> :ok = SQLite.finalize(stmt) end)
      assert {:row, [1, "2", 3.0]} = SQLite.step(db, stmt)
      assert :done = SQLite.step(db, stmt)
    end
  end

  describe "multi_bind_step" do
    test "it works" do
      {:ok, db} = SQLite.open(~c":memory:", 0x00000002)
      on_exit(fn -> :ok = SQLite.close(db) end)
      :ok = SQLite.execute(db, "create table users(name text, age integer) strict")
      {:ok, stmt} = SQLite.prepare(db, "insert into users(name, age) values (?, ?)")
      on_exit(fn -> :ok = SQLite.finalize(stmt) end)
      :ok = SQLite.execute(db, "begin")
      :ok = SQLite.multi_bind_step(db, stmt, [["john", 10], ["benedict", 12], ["abc", 99]])
      :ok = SQLite.execute(db, "commit")

      {:ok, rows} = SQLite.fetch_all(db, "select * from users", [], 10)
      assert rows == [["john", 10], ["benedict", 12], ["abc", 99]]
    end
  end

  test "set_update_hook" do
    {:ok, db} = SQLite.open(~c":memory:", _readwrite = 0x2)
    on_exit(fn -> :ok = SQLite.close(db) end)
    :ok = SQLite.set_update_hook(db, self())
    :ok = SQLite.execute(db, "create table users(name text, age integer) strict")
    :ok = SQLite.execute(db, "insert into users(name, age) values ('john', 23), ('jane', 32)")
    assert_receive {:insert, "main", "users", 1}
    assert_receive {:insert, "main", "users", 2}
    :ok = SQLite.execute(db, "update users set age = age + 1 where name = 'john'")
    assert_receive {:update, "main", "users", 1}
    :ok = SQLite.execute(db, "delete from users where age > 23")
    assert_receive {:delete, "main", "users", 1}
    assert_receive {:delete, "main", "users", 2}
    {:ok, []} = SQLite.fetch_all(db, "select * from users", [], 10)
    refute_receive _anything
  end

  test "get_autocommit" do
    {:ok, db} = SQLite.open(~c":memory:", _readwrite = 0x2)
    assert SQLite.get_autocommit(db) == 1
    :ok = SQLite.execute(db, "begin")
    assert SQLite.get_autocommit(db) == 0
    :ok = SQLite.execute(db, "rollback")
    assert SQLite.get_autocommit(db) == 1
  end
end
