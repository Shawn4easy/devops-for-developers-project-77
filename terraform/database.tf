resource "yandex_mdb_postgresql_cluster" "app" {
  name               = "${var.project_name}-db"
  environment        = "PRODUCTION"
  network_id         = yandex_vpc_network.app.id
  security_group_ids = [yandex_vpc_security_group.db.id]

  config {
    version = 16

    resources {
      resource_preset_id = var.db_resource_preset
      disk_type_id       = "network-hdd"
      disk_size          = var.db_disk_size
    }
  }

  host {
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.app[var.yc_zone].id
  }
}

resource "yandex_mdb_postgresql_user" "app" {
  cluster_id = yandex_mdb_postgresql_cluster.app.id
  name       = var.db_user
  password   = var.db_password
}

resource "yandex_mdb_postgresql_database" "app" {
  cluster_id = yandex_mdb_postgresql_cluster.app.id
  name       = var.db_name
  owner      = yandex_mdb_postgresql_user.app.name
}
