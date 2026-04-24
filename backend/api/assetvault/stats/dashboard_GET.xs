// Asset dashboard stats
query "stats/dashboard" verb=GET {
  api_group = "AssetVault"
  auth = "user"

  input {}

  stack {
    db.query "av_asset" {
      return = {type: "count"}
    } as $total

    db.query "av_asset" {
      where = $db.av_asset.status == "available"
      return = {type: "count"}
    } as $available

    db.query "av_asset" {
      where = $db.av_asset.status == "assigned"
      return = {type: "count"}
    } as $assigned

    db.query "av_asset" {
      where = $db.av_asset.status == "in_repair"
      return = {type: "count"}
    } as $in_repair

    db.query "av_asset" {
      where = $db.av_asset.status == "retired"
      return = {type: "count"}
    } as $retired
  }

  response = {
    total: $total,
    available: $available,
    assigned: $assigned,
    in_repair: $in_repair,
    retired: $retired
  }
}
