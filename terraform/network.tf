resource "yandex_vpc_network" "app" {
  name = "${var.project_name}-network"
}

resource "yandex_vpc_subnet" "app" {
  for_each = var.subnets

  name           = "${var.project_name}-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.app.id
  v4_cidr_blocks = [each.value]
}
