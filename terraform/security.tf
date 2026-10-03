resource "yandex_vpc_security_group" "alb" {
  name       = "${var.project_name}-sg-alb"
  network_id = yandex_vpc_network.app.id

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description       = "Проверки состояния узлов балансировщика"
    protocol          = "TCP"
    port              = 30080
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    description    = "Исходящий трафик узлов балансировщика"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "app" {
  name       = "${var.project_name}-sg-app"
  network_id = yandex_vpc_network.app.id

  ingress {
    description    = "SSH для Ansible"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description       = "Приложение, только от балансировщика"
    protocol          = "TCP"
    port              = var.app_port
    security_group_id = yandex_vpc_security_group.alb.id
  }

  ingress {
    description       = "Проверки состояния от балансировщика"
    protocol          = "TCP"
    port              = var.app_port
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    description    = "Исходящий трафик: пакеты, образы, база"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "db" {
  name       = "${var.project_name}-sg-db"
  network_id = yandex_vpc_network.app.id

  ingress {
    description       = "PostgreSQL через Odyssey, только от веб-серверов"
    protocol          = "TCP"
    port              = 6432
    security_group_id = yandex_vpc_security_group.app.id
  }
}
