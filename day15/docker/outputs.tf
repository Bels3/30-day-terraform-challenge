output "container_name" {
  description = "Name of the running Docker container"
  value       = docker_container.nginx.name
}

output "container_ip" {
  description = "IP address of the container"
  value       = docker_container.nginx.network_data[0].ip_address
}
