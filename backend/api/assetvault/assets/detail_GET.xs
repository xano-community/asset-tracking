// Get an asset with category, location, and current assignee
query "assets/{asset_id}" verb=GET {
  api_group = "AssetVault"
  auth = "user"

  input {
    int asset_id
  }

  stack {
    db.get "av_asset" {
      field_name = "id"
      field_value = $input.asset_id
    } as $asset

    precondition ($asset != null) {
      error_type = "notfound"
      error = "Asset not found"
    }

    db.get "av_category" {
      field_name = "id"
      field_value = $asset.category_id
    } as $category

    db.get "av_location" {
      field_name = "id"
      field_value = $asset.location_id
    } as $location

    db.get "user" {
      field_name = "id"
      field_value = $asset.assigned_to
      output = ["id", "name", "email"]
    } as $assignee

    var $result {
      value = $asset|set:"category":$category|set:"location":$location|set:"assignee":$assignee
    }
  }

  response = $result
}
