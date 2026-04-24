// List locations
query "locations" verb=GET {
  api_group = "AssetVault"

  input {}

  stack {
    db.query "av_location" {
      sort = {name: "asc"}
    } as $locations
  }

  response = $locations
}
