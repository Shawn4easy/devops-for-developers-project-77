data "yandex_compute_image" "ubuntu" {
  family = var.vm_image_family
}

resource "yandex_compute_instance" "web" {
  for_each = yandex_vpc_subnet.app

  name        = "${var.project_name}-${substr(each.key, -1, 1)}"
  hostname    = "${var.project_name}-${substr(each.key, -1, 1)}"
  zone        = each.key
  platform_id = "standard-v3"

  resources {
    cores         = var.vm_cores
    core_fraction = var.vm_core_fraction
    memory        = var.vm_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = var.vm_disk_size
    }
  }

  network_interface {
    subnet_id          = each.value.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.app.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
      ssh_key = var.admin_ssh_key
    })
  }

  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image_id]
  }
}
