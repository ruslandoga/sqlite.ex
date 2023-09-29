Benchee.run(%{
  "select ? (prepare)" => fn -> nil end,
  "select ? (bind)" => fn -> nil end,
  "select ? (execute)" => fn -> nil end,
  "select ? (step)" => fn -> nil end
})
