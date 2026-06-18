workspace templates {
  acceptance = {ai_terms: false}
  preferences = {
    internal_docs    : false
    track_performance: true
    sql_names        : false
    sql_columns      : true
  }
}
---
table "asset_assignment" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int asset_id {
      table = "asset"
    }
    int user_id {
      table = "user"
    }
    timestamp assigned_at?=now
    timestamp returned_at?
    text notes?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "asset_id"}]}
    {type: "btree", field: [{name: "user_id"}]}
    {type: "btree", field: [{name: "assigned_at", op: "desc"}]}
  ]
}
---
table "asset_category" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    text name filters=trim
    text description?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "name"}]}
  ]
}
---
table "asset" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    timestamp updated_at?
    text asset_tag filters=trim
    text name filters=trim
    text description?
    text manufacturer?
    text model?
    text serial_number?
    enum status?="available" {
      values = ["available", "assigned", "in_repair", "retired", "lost"]
    }
    int category_id? {
      table = "asset_category"
    }
    int location_id? {
      table = "location"
    }
    int assigned_to? {
      table = "user"
    }
    date purchase_date?
    decimal purchase_cost?=0
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "asset_tag"}]}
    {type: "btree", field: [{name: "status"}]}
    {type: "btree", field: [{name: "category_id"}]}
    {type: "btree", field: [{name: "location_id"}]}
    {type: "btree", field: [{name: "assigned_to"}]}
  ]
}
---
table "location" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    text name filters=trim
    text address?
    text city?
    text country?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree|unique", field: [{name: "name"}]}
  ]
}
---
table "maintenance_log" {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int asset_id {
      table = "asset"
    }
    int performed_by? {
      table = "user"
    }
    text description filters=trim
    decimal cost?=0
    timestamp performed_at?=now
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "asset_id"}]}
    {type: "btree", field: [{name: "performed_at", op: "desc"}]}
  ]
}
---
table user {
  auth = true

  schema {
    int id
    timestamp created_at?=now {
      visibility = "private"
    }
  
    text name filters=trim
    email? email filters=trim|lower
    password? password filters=min:8|minAlpha:1|minDigit:1 {
      visibility = "internal"
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
    {type: "btree|unique", field: [{name: "email", op: "asc"}]}
  ]

}
---
api_group Assets {
  canonical = "asset-tracking"
  description = "Asset Tracking - Enterprise IT asset management"
  tags = ["assets", "inventory", "it"]
}
---
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
---
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
---
// Create a new asset
query "assets" verb=POST {
  api_group = "Assets"
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
    text purchase_date? filters=trim
    decimal purchase_cost?
  }

  stack {
    db.query "asset" {
      where = $db.asset.asset_tag == $input.asset_tag
      return = {type: "exists"}
    } as $exists

    precondition (!$exists) {
      error_type = "inputerror"
      error = "Asset tag already in use"
    }

    db.add "asset" {
      data = {
        asset_tag     : $input.asset_tag,
        name          : $input.name,
        description   : $input.description,
        manufacturer  : $input.manufacturer,
        model         : $input.model,
        serial_number : $input.serial_number,
        category_id   : $input.category_id,
        location_id   : $input.location_id,
        purchase_cost : $input.purchase_cost,
        status        : "available"
      }
    } as $asset

    // purchase_date is set in a follow-up patch: referencing an omitted
    // optional date input faults at runtime, so it must not appear in db.add.
    conditional {
      if (($input.purchase_date|strlen) > 0) {
        db.patch "asset" {
          field_name = "id"
          field_value = $asset.id
          data = {purchase_date: $input.purchase_date}
        } as $asset
      }
    }
  }

  response = $asset
}
---
// Get an asset with category, location, and current assignee
query "assets/{asset_id}" verb=GET {
  api_group = "Assets"
  auth = "user"

  input {
    int asset_id
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

    db.get "asset_category" {
      field_name = "id"
      field_value = $asset.category_id
    } as $category

    db.get "location" {
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
---
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
---
// Get maintenance history for an asset
query "assets/{asset_id}/maintenance" verb=GET {
  api_group = "Assets"
  auth = "user"

  input {
    int asset_id
  }

  stack {
    db.query "maintenance_log" {
      where = $db.maintenance_log.asset_id == $input.asset_id
      sort = {performed_at: "desc"}
    } as $logs
  }

  response = $logs
}
---
// Log maintenance on an asset
query "assets/{asset_id}/maintenance" verb=POST {
  api_group = "Assets"
  auth = "user"

  input {
    int asset_id
    text description filters=trim
    decimal cost?
  }

  stack {
    db.add "maintenance_log" {
      data = {
        asset_id     : $input.asset_id,
        performed_by : $auth.id,
        description  : $input.description,
        cost         : $input.cost,
        performed_at : now
      }
    } as $log
  }

  response = $log
}
---
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
      where = $db.asset_assignment.asset_id == $input.asset_id && ($db.asset_assignment.returned_at == null || $db.asset_assignment.returned_at == 0)
      sort = {assigned_at: "desc"}
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
        assigned_to: 0,
        updated_at : now
      }
    } as $updated_asset
  }

  response = $updated_asset
}
---
// Update an asset's mutable fields
query "assets/{asset_id}" verb=PATCH {
  api_group = "Assets"
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

    db.patch "asset" {
      field_name = "id"
      field_value = $input.asset_id
      data = $updates
    } as $asset
  }

  response = $asset
}
---
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
---
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
---
// Seed Asset Tracking with realistic demo data. Idempotent.
query "seed" verb=POST {
  api_group = "Assets"

  input {}

  stack {
    db.query "asset" {
      return = {type: "count"}
    } as $existing_assets

    precondition ($existing_assets == 0) {
      error_type = "inputerror"
      error = "Asset Tracking data already seeded."
    }

    var $seed_users {
      value = [
        {name: "Alice Johnson",   email: "alice.johnson@acme.enterprise"},
        {name: "Bob Martinez",    email: "bob.martinez@acme.enterprise"},
        {name: "Carol Nguyen",    email: "carol.nguyen@acme.enterprise"},
        {name: "David Okonkwo",   email: "david.okonkwo@acme.enterprise"},
        {name: "Emma Patel",      email: "emma.patel@acme.enterprise"},
        {name: "Frank Rivera",    email: "frank.rivera@acme.enterprise"},
        {name: "Grace Sullivan",  email: "grace.sullivan@acme.enterprise"},
        {name: "Henry Tanaka",    email: "henry.tanaka@acme.enterprise"}
      ]
    }

    foreach ($seed_users) {
      each as $u {
        db.get "user" {
          field_name = "email"
          field_value = $u.email
        } as $existing

        conditional {
          if ($existing == null) {
            db.add "user" {
              data = {name: $u.name, email: $u.email, password: "DemoPass1"}
            }
          }
        }
      }
    }

    var $categories {
      value = [
        {name: "Laptop",       description: "Employee laptops"},
        {name: "Monitor",      description: "External displays"},
        {name: "Phone",        description: "Mobile phones"},
        {name: "Desktop",      description: "Desktop workstations"},
        {name: "Peripheral",   description: "Keyboards, mice, docking stations"},
        {name: "Server",       description: "Data center equipment"},
        {name: "Network Gear", description: "Switches, routers, access points"}
      ]
    }

    foreach ($categories) {
      each as $c {
        db.get "asset_category" {
          field_name = "name"
          field_value = $c.name
        } as $existing

        conditional {
          if ($existing == null) {
            db.add "asset_category" {
              data = {name: $c.name, description: $c.description}
            }
          }
        }
      }
    }

    var $locations {
      value = [
        {name: "HQ - San Francisco", address: "555 Market St",   city: "San Francisco", country: "USA"},
        {name: "NYC Office",         address: "200 5th Ave",     city: "New York",      country: "USA"},
        {name: "London Office",      address: "10 Bishopsgate",  city: "London",        country: "UK"},
        {name: "Remote",             address: "-",               city: "-",             country: "-"},
        {name: "Data Center East",   address: "1 Server Way",    city: "Ashburn",       country: "USA"}
      ]
    }

    foreach ($locations) {
      each as $l {
        db.get "location" {
          field_name = "name"
          field_value = $l.name
        } as $existing

        conditional {
          if ($existing == null) {
            db.add "location" {
              data = {name: $l.name, address: $l.address, city: $l.city, country: $l.country}
            }
          }
        }
      }
    }

    var $asset_seeds {
      value = [
        {tag: "LT-001", name: "MacBook Pro 16\" M3",       manufacturer: "Apple",   model: "MBP16-M3",     cat: "Laptop",       loc: "HQ - San Francisco", status: "assigned",  owner_email: "alice.johnson@acme.enterprise",  cost: 3499.0},
        {tag: "LT-002", name: "MacBook Air 13\" M2",       manufacturer: "Apple",   model: "MBA13-M2",     cat: "Laptop",       loc: "Remote",             status: "assigned",  owner_email: "bob.martinez@acme.enterprise",   cost: 1299.0},
        {tag: "LT-003", name: "Dell XPS 15",                manufacturer: "Dell",    model: "XPS-15-9530",  cat: "Laptop",       loc: "NYC Office",         status: "assigned",  owner_email: "carol.nguyen@acme.enterprise",   cost: 1899.0},
        {tag: "LT-004", name: "ThinkPad X1 Carbon Gen 11", manufacturer: "Lenovo",  model: "X1C-G11",      cat: "Laptop",       loc: "London Office",      status: "available", owner_email: "",                                cost: 2149.0},
        {tag: "LT-005", name: "MacBook Pro 14\" M3 Max",   manufacturer: "Apple",   model: "MBP14-M3MAX",  cat: "Laptop",       loc: "HQ - San Francisco", status: "in_repair", owner_email: "",                                cost: 3999.0},
        {tag: "MN-001", name: "LG UltraFine 27\" 5K",      manufacturer: "LG",      model: "27UN850",      cat: "Monitor",      loc: "HQ - San Francisco", status: "assigned",  owner_email: "alice.johnson@acme.enterprise",  cost: 1299.0},
        {tag: "MN-002", name: "Dell UltraSharp 32\" 4K",   manufacturer: "Dell",    model: "U3223QE",      cat: "Monitor",      loc: "NYC Office",         status: "assigned",  owner_email: "david.okonkwo@acme.enterprise",  cost: 1099.0},
        {tag: "MN-003", name: "Samsung 49\" Odyssey",      manufacturer: "Samsung", model: "G95NC",        cat: "Monitor",      loc: "Remote",             status: "available", owner_email: "",                                cost: 1499.0},
        {tag: "PH-001", name: "iPhone 15 Pro",             manufacturer: "Apple",   model: "A2848",        cat: "Phone",        loc: "HQ - San Francisco", status: "assigned",  owner_email: "emma.patel@acme.enterprise",     cost: 1099.0},
        {tag: "PH-002", name: "iPhone 15",                 manufacturer: "Apple",   model: "A2846",        cat: "Phone",        loc: "NYC Office",         status: "assigned",  owner_email: "frank.rivera@acme.enterprise",   cost: 899.0},
        {tag: "PH-003", name: "Samsung Galaxy S24",        manufacturer: "Samsung", model: "SM-S921B",     cat: "Phone",        loc: "London Office",      status: "available", owner_email: "",                                cost: 799.0},
        {tag: "DK-001", name: "iMac 27\" Retina",          manufacturer: "Apple",   model: "iMac-27",      cat: "Desktop",      loc: "HQ - San Francisco", status: "retired",   owner_email: "",                                cost: 2499.0},
        {tag: "DK-002", name: "Mac Studio M2 Max",         manufacturer: "Apple",   model: "MS-M2MAX",     cat: "Desktop",      loc: "NYC Office",         status: "assigned",  owner_email: "grace.sullivan@acme.enterprise", cost: 2999.0},
        {tag: "PR-001", name: "Magic Keyboard",            manufacturer: "Apple",   model: "MK293LL",      cat: "Peripheral",   loc: "HQ - San Francisco", status: "available", owner_email: "",                                cost: 129.0},
        {tag: "PR-002", name: "MX Master 3S",              manufacturer: "Logitech",model: "MX-Master-3S", cat: "Peripheral",   loc: "HQ - San Francisco", status: "available", owner_email: "",                                cost: 99.0},
        {tag: "PR-003", name: "CalDigit TS4 Dock",         manufacturer: "CalDigit",model: "TS4",          cat: "Peripheral",   loc: "NYC Office",         status: "assigned",  owner_email: "henry.tanaka@acme.enterprise",   cost: 399.0},
        {tag: "SV-001", name: "Dell PowerEdge R760",       manufacturer: "Dell",    model: "R760",         cat: "Server",       loc: "Data Center East",   status: "assigned",  owner_email: "",                                cost: 12999.0},
        {tag: "SV-002", name: "HPE ProLiant DL380 Gen11",  manufacturer: "HPE",     model: "DL380-G11",    cat: "Server",       loc: "Data Center East",   status: "assigned",  owner_email: "",                                cost: 11499.0},
        {tag: "NW-001", name: "Cisco Catalyst 9300",       manufacturer: "Cisco",   model: "C9300-24T",    cat: "Network Gear", loc: "Data Center East",   status: "assigned",  owner_email: "",                                cost: 4599.0},
        {tag: "NW-002", name: "Ubiquiti UniFi U6 Pro",     manufacturer: "Ubiquiti",model: "U6-Pro",       cat: "Network Gear", loc: "HQ - San Francisco", status: "available", owner_email: "",                                cost: 199.0}
      ]
    }

    var $count { value = 0 }

    foreach ($asset_seeds) {
      each as $a {
        db.get "asset_category" {
          field_name = "name"
          field_value = $a.cat
        } as $category

        db.get "location" {
          field_name = "name"
          field_value = $a.loc
        } as $location

        var $owner_id { value = null }

        conditional {
          if ($a.owner_email != "") {
            db.get "user" {
              field_name = "email"
              field_value = $a.owner_email
            } as $owner_user

            var.update $owner_id {
              value = $owner_user.id
            }
          }
        }

        db.add "asset" {
          data = {
            asset_tag    : $a.tag,
            name         : $a.name,
            manufacturer : $a.manufacturer,
            model        : $a.model,
            description  : ($a.manufacturer ~ " " ~ $a.model),
            category_id  : $category.id,
            location_id  : $location.id,
            status       : $a.status,
            assigned_to  : $owner_id,
            purchase_cost: $a.cost
          }
        } as $asset

        conditional {
          if ($a.status == "assigned" && $owner_id != null) {
            db.add "asset_assignment" {
              data = {
                asset_id   : $asset.id,
                user_id    : $owner_id,
                assigned_at: now,
                notes      : "Initial deployment"
              }
            }
          }
        }

        var.update $count {
          value = $count + 1
        }
      }
    }
  }

  response = {success: true, assets_seeded: $count}
}
---
// Asset dashboard stats
query "stats/dashboard" verb=GET {
  api_group = "Assets"
  auth = "user"

  input {}

  stack {
    db.query "asset" {
      return = {type: "count"}
    } as $total

    db.query "asset" {
      where = $db.asset.status == "available"
      return = {type: "count"}
    } as $available

    db.query "asset" {
      where = $db.asset.status == "assigned"
      return = {type: "count"}
    } as $assigned

    db.query "asset" {
      where = $db.asset.status == "in_repair"
      return = {type: "count"}
    } as $in_repair

    db.query "asset" {
      where = $db.asset.status == "retired"
      return = {type: "count"}
    } as $retired
  }

  response = {
    total: $total,
    available: $available,
    assigned: $assigned,
    in_repair: $in_repair,
    retired: $retired
  }
}
---
api_group EnterpriseAuth {
  canonical = "enterprise-auth"
  description = "Shared authentication for HelpDesk Pro, Asset Tracking, and ProcureFlow"
  tags = ["auth", "shared"]
}
---
// Login and retrieve an authentication token
query "login" verb=POST {
  api_group = "EnterpriseAuth"

  input {
    email email filters=trim|lower
    text password
  }

  stack {
    db.get "user" {
      field_name = "email"
      field_value = $input.email
      output = ["id", "created_at", "name", "email", "password"]
    } as $user

    precondition ($user != null) {
      error_type = "accessdenied"
      error = "Invalid credentials"
    }

    security.check_password {
      text_password = $input.password
      hash_password = $user.password
    } as $pass_result

    precondition ($pass_result) {
      error_type = "accessdenied"
      error = "Invalid credentials"
    }

    security.create_auth_token {
      table = "user"
      extras = {}
      expiration = 86400
      id = $user.id
    } as $authToken
  }

  response = {
    authToken: $authToken,
    user: {id: $user.id, name: $user.name, email: $user.email}
  }
}
---
// Get the currently authenticated user
query "me" verb=GET {
  api_group = "EnterpriseAuth"
  auth = "user"

  input {}

  stack {
    db.get "user" {
      field_name = "id"
      field_value = $auth.id
      output = ["id", "created_at", "name", "email"]
    } as $user
  }

  response = $user
}
---
// Create a new account and retrieve an authentication token
query "signup" verb=POST {
  api_group = "EnterpriseAuth"

  input {
    text name filters=trim
    email email filters=trim|lower
    text password
  }

  stack {
    db.get "user" {
      field_name = "email"
      field_value = $input.email
    } as $existing

    precondition ($existing == null) {
      error_type = "inputerror"
      error = "Email already registered"
    }

    db.add "user" {
      data = {
        name    : $input.name,
        email   : $input.email,
        password: $input.password
      }
    } as $user

    security.create_auth_token {
      table = "user"
      extras = {}
      expiration = 86400
      id = $user.id
    } as $authToken
  }

  response = {
    authToken: $authToken,
    user: {id: $user.id, name: $user.name, email: $user.email}
  }
}
---
// List users (for selector dropdowns across apps)
query "users" verb=GET {
  api_group = "EnterpriseAuth"
  auth = "user"

  input {}

  stack {
    db.query "user" {
      sort = {name: "asc"}
      return = {type: "list"}
    } as $users

    var $sanitized { value = [] }

    foreach ($users) {
      each as $u {
        var.update $sanitized {
          value = $sanitized|push:{id: $u.id, name: $u.name, email: $u.email}
        }
      }
    }
  }

  response = $sanitized
}
