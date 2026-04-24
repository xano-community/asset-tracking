// Create a new asset
query "assets" verb=POST {
  api_group = "AssetVault"
  auth = "user"

  input {
    text asset_tag filters=trim
    text name filters=trim
    text description? filters=trim
    text manufacturer? filters=trim
    text model? filters=trim
    text serial_number? filters=trim
    int category_id?
    int location_id?
    date purchase_date?
    decimal purchase_cost?
  }

  stack {
    db.query "av_asset" {
      where = $db.av_asset.asset_tag == $input.asset_tag
      return = {type: "exists"}
    } as $exists

    precondition (!$exists) {
      error_type = "inputerror"
      error = "Asset tag already in use"
    }

    db.add "av_asset" {
      data = {
        asset_tag     : $input.asset_tag,
        name          : $input.name,
        description   : $input.description,
        manufacturer  : $input.manufacturer,
        model         : $input.model,
        serial_number : $input.serial_number,
        category_id   : $input.category_id,
        location_id   : $input.location_id,
        purchase_date : $input.purchase_date,
        purchase_cost : $input.purchase_cost,
        status        : "available"
      }
    } as $asset
  }

  response = $asset
}
