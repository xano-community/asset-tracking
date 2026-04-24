// Asset dashboard stats
query "stats/dashboard" verb=GET {
  api_group = "Assets"
  auth = "user"

  input {}

  stack {
    db.query "asset" {
      return = {type: "count"}
    } as $total

    db.query "asset" {
      where = $db.asset.status == "available"
      return = {type: "count"}
    } as $available

    db.query "asset" {
      where = $db.asset.status == "assigned"
      return = {type: "count"}
    } as $assigned

    db.query "asset" {
      where = $db.asset.status == "in_repair"
      return = {type: "count"}
    } as $in_repair

    db.query "asset" {
      where = $db.asset.status == "retired"
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
