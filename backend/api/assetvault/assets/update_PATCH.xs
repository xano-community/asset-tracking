// Update an asset's mutable fields
query "assets/{asset_id}" verb=PATCH {
  api_group = "AssetVault"
  auth = "user"

  input {
    int asset_id
    text name? filters=trim
    text description? filters=trim
    text status? filters=trim|lower
    int category_id?
    int location_id?
    decimal purchase_cost?
  }

  stack {
    var $updates {
      value = {updated_at: now}
    }

    conditional {
      if ($input.name != null) {
        var.update $updates {value = $updates|set:"name":$input.name}
      }
    }
    conditional {
      if ($input.description != null) {
        var.update $updates {value = $updates|set:"description":$input.description}
      }
    }
    conditional {
      if ($input.status != null) {
        var.update $updates {value = $updates|set:"status":$input.status}
      }
    }
    conditional {
      if ($input.category_id != null) {
        var.update $updates {value = $updates|set:"category_id":$input.category_id}
      }
    }
    conditional {
      if ($input.location_id != null) {
        var.update $updates {value = $updates|set:"location_id":$input.location_id}
      }
    }
    conditional {
      if ($input.purchase_cost != null) {
        var.update $updates {value = $updates|set:"purchase_cost":$input.purchase_cost}
      }
    }

    db.patch "av_asset" {
      field_name = "id"
      field_value = $input.asset_id
      data = $updates
    } as $asset
  }

  response = $asset
}
