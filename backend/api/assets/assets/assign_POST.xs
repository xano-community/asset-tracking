// Assign an asset to a user (creates assignment record, updates asset)
query "assets/{asset_id}/assign" verb=POST {
  api_group = "Assets"
  auth = "user"

  input {
    int asset_id
    int user_id
    text notes? filters=trim
  }

  stack {
    db.get "asset" {
      field_name = "id"
      field_value = $input.asset_id
    } as $asset

    precondition ($asset != null) {
      error_type = "notfound"
      error = "Asset not found"
    }

    precondition ($asset.status == "available") {
      error_type = "inputerror"
      error = "Asset is not available for assignment"
    }

    db.add "asset_assignment" {
      data = {
        asset_id   : $input.asset_id,
        user_id    : $input.user_id,
        notes      : $input.notes,
        assigned_at: now
      }
    } as $assignment

    db.edit "asset" {
      field_name = "id"
      field_value = $input.asset_id
      data = {
        status     : "assigned",
        assigned_to: $input.user_id,
        updated_at : now
      }
    } as $updated_asset
  }

  response = {assignment: $assignment, asset: $updated_asset}
}
