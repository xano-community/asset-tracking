// Get maintenance history for an asset
query "assets/{asset_id}/maintenance" verb=GET {
  api_group = "Assets"
  auth = "user"

  input {
    int asset_id
  }

  stack {
    db.query "maintenance_log" {
      where = $db.maintenance_log.asset_id == $input.asset_id
      sort = {performed_at: "desc"}
    } as $logs
  }

  response = $logs
}
