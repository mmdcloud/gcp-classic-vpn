output "network_ip" {
  value = google_compute_instance.instance.network_interface[0].network_ip
}
