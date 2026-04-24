table "av_maintenance_log" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int asset_id {
      table = "av_asset"
    }
    int performed_by? {
      table = "user"
    }
    text description filters=trim
    decimal cost?=0
    timestamp performed_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "asset_id"}]}
    {type: "btree", field: [{name: "performed_at", op: "desc"}]}
  ]
}
