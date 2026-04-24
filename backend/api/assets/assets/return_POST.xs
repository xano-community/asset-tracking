// Return an asset (closes active assignment, updates asset to available)
query "assets/{asset_id}/return" verb=POST {
  api_group = "Assets"
  auth = "user"

  input {
    int asset_id
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

    db.query "asset_assignment" {
      where = $db.asset_assignment.asset_id == $input.asset_id && $db.asset_assignment.returned_at == null
      return = {type: "single"}
    } as $active_assignment

    conditional {
      if ($active_assignment != null) {
        db.edit "asset_assignment" {
          field_name = "id"
          field_value = $active_assignment.id
          data = {
            returned_at: now,
            notes      : $input.notes
          }
        }
      }
    }

    db.edit "asset" {
      field_name = "id"
      field_value = $input.asset_id
      data = {
        status     : "available",
        assigned_to: null,
        updated_at : now
      }
    } as $updated_asset
  }

  response = $updated_asset
}
