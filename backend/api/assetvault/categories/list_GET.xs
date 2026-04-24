// List asset categories
query "categories" verb=GET {
  api_group = "AssetVault"

  input {}

  stack {
    db.query "av_category" {
      sort = {name: "asc"}
    } as $categories
  }

  response = $categories
}
