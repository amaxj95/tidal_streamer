provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "tidal_app" {
  name         = "tidal-app-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "default"

    access_config {
    }
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx python3 python3-pip git
              systemctl start nginx
              systemctl enable nginx
              pip3 install flask requests python-vlc gunicorn
              cd /home
              git clone https://github.com/amaxj95/tidal_streamer.git
              cd tidal-streamer
              gunicorn -b 0.0.0.0:80 app:app &
              EOF

  tags = ["http-server", "https-server"]
}

resource "google_compute_firewall" "default" {
  name    = "default-allow-http-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["http-server", "https-server"]
}

resource "google_compute_address" "static_ip" {
  name = "static-ip"
}

resource "google_compute_global_address" "static_ip" {
  name = "static-ip"
}

resource "google_compute_managed_ssl_certificate" "default" {
  name        = "default-managed-ssl-cert"
  description = "A managed SSL certificate"
}

resource "google_compute_backend_service" "default" {
  name                  = "default-backend-service"
  protocol              = "HTTP"
  health_checks         = [google_compute_http_health_check.default.self_link]
  backend {
    group = google_compute_instance_group.default.self_link
  }
}

resource "google_compute_http_health_check" "default" {
  name                = "default-http-health-check"
  request_path        = "/"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

resource "google_compute_instance_group" "default" {
  name = "default-instance-group"
  zone = var.zone
  instances = [
    google_compute_instance.tidal_app.self_link
  ]
}

resource "google_compute_url_map" "default" {
  name            = "default-url-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_https_proxy" "default" {
  name             = "default-target-https-proxy"
  url_map          = google_compute_url_map.default.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.default.self_link]
}

resource "google_compute_global_forwarding_rule" "default" {
  name          = "default-https-forwarding-rule"
  target        = google_compute_target_https_proxy.default.self_link
  port_range    = "443"
  ip_address    = google_compute_global_address.static_ip.address
  load_balancing_scheme = "EXTERNAL"
}

variable "project_id" {
  description = "The ID of the GCP project to use"
}

variable "region" {
  description = "The GCP region to create resources in"
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to create resources in"
  default     = "us-central1-a"
}

variable "domain_name" {
  description = "The domain name for the managed SSL certificate"
}