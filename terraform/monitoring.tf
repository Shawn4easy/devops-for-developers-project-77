# Агент на каждом сервере раз в 15 секунд запрашивает приложение локально
# (http_check) и отправляет результат в http.can_connect. Монитор группируется
# по серверу, поэтому тревога сообщает, на каком именно сервере упало приложение.
resource "datadog_monitor" "blog_http" {
  name    = "${var.project_name}: блог не отвечает на {{host.name}}"
  type    = "service check"
  query   = "\"http.can_connect\".over(\"instance:${var.datadog_check_name}\").by(\"host\").last(3).count_by_status()"
  message = <<-EOT
    Приложение на {{host.name}} не отвечает на HTTP-запросы агента DataDog.
    Проверьте контейнер: docker ps, docker logs blog.
  EOT

  monitor_thresholds {
    critical = 2
    ok       = 1
  }

  notify_no_data    = true
  no_data_timeframe = 5
  renotify_interval = 0
  include_tags      = true

  tags = ["project:${var.project_name}", "service:blog"]
}
