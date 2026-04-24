// Seed AssetVault with realistic demo data. Idempotent.
query "seed" verb=POST {
  api_group = "AssetVault"

  input {}

  stack {
    db.query "av_asset" {
      return = {type: "count"}
    } as $existing_assets

    precondition ($existing_assets == 0) {
      error_type = "inputerror"
      error = "AssetVault data already seeded."
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
        db.get "av_category" {
          field_name = "name"
          field_value = $c.name
        } as $existing

        conditional {
          if ($existing == null) {
            db.add "av_category" {
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
        db.get "av_location" {
          field_name = "name"
          field_value = $l.name
        } as $existing

        conditional {
          if ($existing == null) {
            db.add "av_location" {
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
        db.get "av_category" {
          field_name = "name"
          field_value = $a.cat
        } as $category

        db.get "av_location" {
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

        db.add "av_asset" {
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
            db.add "av_assignment" {
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
