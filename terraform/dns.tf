resource "yandex_dns_zone" "app" {
  name   = "${var.project_name}-zone"
  zone   = "${var.domain}."
  public = true
}

resource "yandex_dns_recordset" "app" {
  for_each = toset([var.domain, "www.${var.domain}"])

  zone_id = yandex_dns_zone.app.id
  name    = "${each.key}."
  type    = "A"
  ttl     = 300
  data    = [yandex_alb_load_balancer.app.listener[0].endpoint[0].address[0].external_ipv4_address[0].address]
}
