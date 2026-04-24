table "av_location" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    text name filters=trim
    text address?
    text city?
    text country?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "name"}]}
  ]
}
