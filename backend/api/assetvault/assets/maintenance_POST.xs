// Log maintenance on an asset
query "assets/{asset_id}/maintenance" verb=POST {
  api_group = "AssetVault"
  auth = "user"

  input {
    int asset_id
    text description filters=trim
    decimal cost?
  }

  stack {
    db.add "av_maintenance_log" {
      data = {
        asset_id     : $input.asset_id,
        performed_by : $auth.id,
        description  : $input.description,
        cost         : $input.cost,
        performed_at : now
      }
    } as $log
  }

  response = $log
}
