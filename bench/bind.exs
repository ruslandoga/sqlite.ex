queries = [
  {"select ?", [1]},
  {"select ?", ["1"]},
  {"select ?", [1.0]},
  {"select ?, ?, ?", [1, "two", 3.0]},
  {"select ?, ?, ?, ?, ?, ?", [1, "2", 3.0, "four", 5.5, 6]},
  {"select * from sqlite_master where tbl_name = ?", ["sqlite_master"]}
]

Benchee.run(
  %{
    "SQLite.bind" =>
      {fn {db, stmt, args} -> :ok = SQLite.bind(db, stmt, args) end,
       before_scenario: fn {sql, args} ->
         {:ok, db} = SQLite.open(~c":memory:", 0x1)
         {:ok, stmt} = SQLite.prepare(db, sql)
         {db, stmt, args}
       end,
       after_scenario: fn {db, _stmt, _input} -> :ok = SQLite.close(db) end},
    "Exqlite.Sqlite3.bind" =>
      {fn {db, stmt, args} -> :ok = Exqlite.Sqlite3.bind(db, stmt, args) end,
       before_scenario: fn {sql, args} ->
         {:ok, db} = Exqlite.Sqlite3.open(":memory:")
         {:ok, stmt} = Exqlite.Sqlite3.prepare(db, sql)
         {db, stmt, args}
       end,
       after_scenario: fn {db, _stmt, _args} -> :ok = Exqlite.Sqlite3.close(db) end}
  },
  inputs: Map.new(queries, fn {sql, args} = q -> {sql <> " " <> inspect(args), q} end)
)
