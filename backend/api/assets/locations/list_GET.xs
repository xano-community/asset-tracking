// List locations
query "locations" verb=GET {
  api_group = "Assets"

  input {}

  stack {
    db.query "location" {
      sort = {name: "asc"}
    } as $locations
  }

  response = $locations
}
