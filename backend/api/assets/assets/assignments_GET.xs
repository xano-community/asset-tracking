// Get assignment history for an asset
query "assets/{asset_id}/assignments" verb=GET {
  api_group = "Assets"
  auth = "user"

  input {
    int asset_id
  }

  stack {
    db.query "asset_assignment" {
      where = $db.asset_assignment.asset_id == $input.asset_id
      sort = {assigned_at: "desc"}
    } as $assignments

    var $enriched { value = [] }

    foreach ($assignments) {
      each as $a {
        db.get "user" {
          field_name = "id"
          field_value = $a.user_id
          output = ["id", "name", "email"]
        } as $user

        var.update $enriched {
          value = $enriched|push:($a|set:"user":$user)
        }
      }
    }
  }

  response = $enriched
}
