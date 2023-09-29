rows = fn count ->
  Enum.map(1..count, fn i -> [i, to_string(i), i / 1.0] end)
end

Benchee.run(
  %{
    "SQLite.multi_bind_step" =>
      {fn {db, input} ->
         :ok = SQLite.execute(db, "begin")
         {:ok, stmt} = SQLite.prepare(db, "insert into demo(a, b, c) values (?, ?, ?)")
         :ok = SQLite.multi_bind_step(db, stmt, input)
         :ok = SQLite.execute(db, "commit")
       end,
       before_scenario: fn input ->
         {:ok, db} = SQLite.open(~c":memory:", 0x2)
         :ok = SQLite.execute(db, "create table demo(a integer, b text, c real) strict")
         {db, input}
       end,
       after_scenario: fn {db, _input} -> :ok = SQLite.close(db) end},
    "Exqlite.Sqlite3 single insert" =>
      {fn {db, input} ->
         sql = [
           "insert into demo(a, b, c) values ",
           "(?, ?, ?)"
           |> List.duplicate(length(input))
           |> Enum.intersperse(?,)
         ]

         {:ok, stmt} = Exqlite.Sqlite3.prepare(db, sql)
         :ok = Exqlite.Sqlite3.bind(db, stmt, List.flatten(input))
         :done = Exqlite.Sqlite3.step(db, stmt)
       end,
       before_scenario: fn input ->
         {:ok, db} = Exqlite.Sqlite3.open(":memory:")
         :ok = Exqlite.Sqlite3.execute(db, "create table demo(a integer, b text, c real) strict")
         {db, input}
       end,
       after_scenario: fn {db, _input} -> :ok = Exqlite.Sqlite3.close(db) end}
  },
  inputs: %{
    "10" => rows.(10),
    "100" => rows.(100),
    "1000" => rows.(1000),
    "10000" => rows.(10000)
  }
)
