// List asset categories
query "categories" verb=GET {
  api_group = "Assets"

  input {}

  stack {
    db.query "asset_category" {
      sort = {name: "asc"}
    } as $categories
  }

  response = $categories
}
