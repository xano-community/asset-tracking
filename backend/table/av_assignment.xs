table "av_assignment" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int asset_id {
      table = "av_asset"
    }
    int user_id {
      table = "user"
    }
    timestamp assigned_at?=now
    timestamp returned_at?
    text notes?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "asset_id"}]}
    {type: "btree", field: [{name: "user_id"}]}
    {type: "btree", field: [{name: "assigned_at", op: "desc"}]}
  ]
}
