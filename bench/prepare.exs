queries = [
  "select 1",
  "select ?",
  "select 1, '2', 3.0",
  "select ?, ?, ?",
  "select * from sqlite_master where tbl_name = 'some table' order by 1"
]

Benchee.run(
  %{
    "SQLite.prepare" =>
      {fn {db, query} -> {:ok, _stmt} = SQLite.prepare(db, query) end,
       before_scenario: fn input ->
         {:ok, db} = SQLite.open(~c":memory:", 0x1)
         {db, input}
       end,
       after_scenario: fn {db, _input} -> :ok = SQLite.close(db) end},
    "Exqlite.Sqlite3.prepare" =>
      {fn {db, query} -> {:ok, _stmt} = Exqlite.Sqlite3.prepare(db, query) end,
       before_scenario: fn input ->
         {:ok, db} = Exqlite.Sqlite3.open(":memory:")
         {db, input}
       end,
       after_scenario: fn {db, _input} -> :ok = Exqlite.Sqlite3.close(db) end}
  },
  inputs: Map.new(queries, fn q -> {q, q} end)
)
