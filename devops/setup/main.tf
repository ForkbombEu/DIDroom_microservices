resource "local_file" "docker_daemon" {
  content = jsonencode(
    {
      metrics-addr = "0.0.0.0:9323"
    }
  )
  filename = "/etc/docker/daemon.json"

  provisioner "local-exec" {
    command = "sudo systemctl restart docker"
  }
}
