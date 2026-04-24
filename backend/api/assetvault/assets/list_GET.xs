// List assets with filtering and pagination
query "assets" verb=GET {
  api_group = "AssetVault"
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
    db.query "av_asset" {
      where = $db.av_asset.status ==? $input.status && $db.av_asset.category_id ==? $input.category_id && $db.av_asset.location_id ==? $input.location_id && $db.av_asset.assigned_to ==? $input.assigned_to && $db.av_asset.name includes? $input.q
      sort = {created_at: "desc"}
      return = {
        type: "list",
        paging: {page: $input.page, per_page: $input.per_page, totals: true}
      }
    } as $assets
  }

  response = $assets
}
