output "webservers" {
  description = "Публичные адреса веб-серверов для инвентаря Ansible"
  value       = { for k, vm in yandex_compute_instance.web : vm.name => vm.network_interface[0].nat_ip_address }
}

output "alb_address" {
  description = "Внешний адрес балансировщика"
  value       = yandex_alb_load_balancer.app.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "db_host" {
  description = "FQDN хоста PostgreSQL"
  value       = yandex_mdb_postgresql_cluster.app.host[0].fqdn
}

output "app_url" {
  description = "Адрес приложения"
  value       = "https://${var.domain}"
}
