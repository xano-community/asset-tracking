table "av_asset" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    timestamp updated_at?
    text asset_tag filters=trim
    text name filters=trim
    text description?
    text manufacturer?
    text model?
    text serial_number?
    enum status?="available" {
      values = ["available", "assigned", "in_repair", "retired", "lost"]
    }
    int category_id? {
      table = "av_category"
    }
    int location_id? {
      table = "av_location"
    }
    int assigned_to? {
      table = "user"
    }
    date purchase_date?
    decimal purchase_cost?=0
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "asset_tag"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "category_id"}]}
    {type: "btree", field: [{name: "location_id"}]}
    {type: "btree", field: [{name: "assigned_to"}]}
  ]
}
