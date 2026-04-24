// List assets with filtering and pagination
query "assets" verb=GET {
  api_group = "Assets"
  auth = "user"

  input {
    text status? filters=trim|lower
    int category_id?
    int location_id?
    int assigned_to?
    text q? filters=trim
    int page?=1 filters=min:1
    int per_page?=20 filters=min:1|max:100
  }

  stack {
    db.query "asset" {
      where = $db.asset.status ==? $input.status && $db.asset.category_id ==? $input.category_id && $db.asset.location_id ==? $input.location_id && $db.asset.assigned_to ==? $input.assigned_to && $db.asset.name includes? $input.q
      sort = {created_at: "desc"}
      return = {
        type: "list",
        paging: {page: $input.page, per_page: $input.per_page, totals: true}
      }
    } as $assets
  }

  response = $assets
}
