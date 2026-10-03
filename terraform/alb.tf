resource "yandex_alb_target_group" "app" {
  name = "${var.project_name}-tg"

  dynamic "target" {
    for_each = yandex_compute_instance.web

    content {
      subnet_id  = target.value.network_interface[0].subnet_id
      ip_address = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_alb_backend_group" "app" {
  name = "${var.project_name}-bg"

  http_backend {
    name             = "${var.project_name}-backend"
    port             = var.app_port
    target_group_ids = [yandex_alb_target_group.app.id]

    healthcheck {
      timeout             = "5s"
      interval            = "10s"
      healthy_threshold   = 2
      unhealthy_threshold = 3

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "app" {
  name = "${var.project_name}-router"
}

resource "yandex_alb_virtual_host" "app" {
  name           = "${var.project_name}-vh"
  http_router_id = yandex_alb_http_router.app.id

  route {
    name = "${var.project_name}-route"

    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }

      http_route_action {
        backend_group_id = yandex_alb_backend_group.app.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "app" {
  name               = "${var.project_name}-alb"
  network_id         = yandex_vpc_network.app.id
  security_group_ids = [yandex_vpc_security_group.alb.id]

  allocation_policy {
    dynamic "location" {
      for_each = yandex_vpc_subnet.app

      content {
        zone_id   = location.key
        subnet_id = location.value.id
      }
    }
  }

  listener {
    name = "https"

    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [443]
    }

    tls {
      default_handler {
        certificate_ids = [data.yandex_cm_certificate.app.id]

        http_handler {
          http_router_id = yandex_alb_http_router.app.id
        }
      }
    }
  }

  listener {
    name = "http"

    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }

    http {
      redirects {
        http_to_https = true
      }
    }
  }
}
