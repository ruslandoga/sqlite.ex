rows = fn count ->
  Enum.map(1..count, fn i -> [i, to_string(i), i / 1.0] end)
end

Benchee.run(
  %{
    "SQLite.fetch_all (prepared)" =>
      {fn {db, stmt} -> {:ok, _rows} = SQLite.fetch_all(db, stmt, 100) end,
       before_scenario: fn input ->
         {:ok, db} = SQLite.open(~c":memory:", 0x2)
         :ok = SQLite.execute(db, "create table demo(a integer, b text, c real) strict")
         :ok = SQLite.insert_all(db, "insert into demo(a, b, c) values (?, ?, ?)", input)
         {:ok, stmt} = SQLite.prepare(db, "select * from demo")
         {db, stmt}
       end,
       after_scenario: fn {db, _stmt} -> :ok = SQLite.close(db) end},
    "Exqlite.Sqlite3.fetch_all" =>
      {fn {db, stmt} -> {:ok, _rows} = Exqlite.Sqlite3.fetch_all(db, stmt, 100) end,
       before_scenario: fn input ->
         {:ok, db} = Exqlite.Sqlite3.open(":memory:")
         :ok = Exqlite.Sqlite3.execute(db, "create table demo(a integer, b text, c real) strict")

         sql = [
           "insert into demo(a, b, c) values ",
           "(?, ?, ?)"
           |> List.duplicate(length(input))
           |> Enum.intersperse(?,)
         ]

         {:ok, stmt} = Exqlite.Sqlite3.prepare(db, sql)
         :ok = Exqlite.Sqlite3.bind(db, stmt, List.flatten(input))
         :done = Exqlite.Sqlite3.step(db, stmt)

         {:ok, stmt} = Exqlite.Sqlite3.prepare(db, "select * from demo")

         {db, stmt}
       end,
       after_scenario: fn {db, _stmt} -> :ok = Exqlite.Sqlite3.close(db) end}
  },
  inputs: %{
    "10" => rows.(10),
    "100" => rows.(100),
    "1000" => rows.(1000),
    "10000" => rows.(10000)
  }
  # profile_after: true
)
