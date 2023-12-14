terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_image" "didroom" {
  name         = "ghcr.io/forkbombeu/didroom_microservices:latest"
  keep_locally = false
}

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = false
}

resource "docker_container" "didroom" {
  image = docker_image.didroom.image_id
  name  = "didroom"
  restart = "always"

  ports {
    internal = 3000
    external = 3000
  }
}

resource "docker_container" "prometheus" {
  image = docker_image.prometheus.image_id
  name  = "prometheus"
  restart = "always"

  mounts {
    target = "/etc/prometheus/prometheus.yml"
    source = abspath("${path.module}/prometheus.yml")
    type   = "bind"
  }
  host {
    host = "host.docker.internal"
    ip = "host-gateway"
  }
  ports {
    internal = 9090
    external = 9090
  }
}

