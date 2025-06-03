resource "google_compute_vpn_tunnel" "tunnel" {
  name          = var.vpn_tunnel_name
  peer_ip       = var.peer_ip
  shared_secret = var.shared_secret

  target_vpn_gateway = google_compute_vpn_gateway.target_gateway.id
  local_traffic_selector = var.local_traffic_selector
  remote_traffic_selector = var.remote_traffic_selector
  ike_version = var.ike_version
  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

resource "google_compute_vpn_gateway" "target_gateway" {
  name    = var.vpn_gateway_name
  network = var.vpc_id
}

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "${var.vpn_gateway_name}-fr-esp"
  ip_protocol = "ESP"
  ip_address  = var.static_ip
  target      = google_compute_vpn_gateway.target_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "${var.vpn_gateway_name}-fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = var.static_ip
  target      = google_compute_vpn_gateway.target_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "${var.vpn_gateway_name}-fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = var.static_ip
  target      = google_compute_vpn_gateway.target_gateway.id
}

resource "google_compute_route" "route" {
  name                = var.route_name
  network             = var.vpc_name
  dest_range          = var.dest_range
  priority            = var.route_priority
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel.id
}
