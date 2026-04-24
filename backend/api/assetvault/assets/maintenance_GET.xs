// Get maintenance history for an asset
query "assets/{asset_id}/maintenance" verb=GET {
  api_group = "AssetVault"
  auth = "user"

  input {
    int asset_id
  }

  stack {
    db.query "av_maintenance_log" {
      where = $db.av_maintenance_log.asset_id == $input.asset_id
      sort = {performed_at: "desc"}
    } as $logs
  }

  response = $logs
}
