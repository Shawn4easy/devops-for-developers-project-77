resource "yandex_cm_certificate" "app" {
  name    = "${var.project_name}-cert"
  domains = [var.domain, "www.${var.domain}"]

  managed {
    challenge_type  = "DNS_CNAME"
    challenge_count = 2
  }
}

# Оба домена валидируются одной CNAME-записью на сертификат, поэтому
# имя записи для каждого домена своё, а значение одинаковое.
resource "yandex_dns_recordset" "acme" {
  count = 2

  zone_id = yandex_dns_zone.app.id
  name    = yandex_cm_certificate.app.challenges[count.index].dns_name
  type    = yandex_cm_certificate.app.challenges[count.index].dns_type
  ttl     = 300
  data    = [yandex_cm_certificate.app.challenges[count.index].dns_value]
}

# Балансировщик принимает только выпущенный сертификат, поэтому ждём валидации.
data "yandex_cm_certificate" "app" {
  depends_on      = [yandex_dns_recordset.acme]
  certificate_id  = yandex_cm_certificate.app.id
  wait_validation = true
}
