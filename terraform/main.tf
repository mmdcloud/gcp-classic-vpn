# VPC1 
module "vpc1" {
  source                          = "./modules/vpc"
  vpc_name                        = "vpn-vpc1"
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  ip_cidr_ranges                  = var.ip_cidr_range1
  region                          = "us-central1"
  private_ip_google_access        = false
  firewall_data = [
    {
      name          = "vpc1-firewall"
      source_ranges = [module.instance2.network_ip]
      allow_list = [
        {
          protocol = "icmp"
          ports    = []
        }
      ]
    },
    {
      name          = "vpc1-firewall-ssh"
      source_ranges = ["0.0.0.0/0"]
      allow_list = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
  ]
}

# VPC2 
module "vpc2" {
  source                          = "./modules/vpc"
  vpc_name                        = "vpn-vpc2"
  delete_default_routes_on_create = false
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  ip_cidr_ranges                  = var.ip_cidr_range2
  region                          = "us-east1"
  private_ip_google_access        = false
  firewall_data = [
    {
      name          = "vpc2-firewall"
      source_ranges = [module.instance1.network_ip]
      allow_list = [
        {
          protocol = "icmp"
          ports    = []
        }
      ]
    },
    {
      name          = "vpc2-firewall-ssh"
      source_ranges = ["0.0.0.0/0"]
      allow_list = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
  ]
}

# Instance 1
module "instance1" {
  source                    = "./modules/compute"
  name                      = "vpn-instance1"
  machine_type              = "e2-micro"
  zone                      = "us-central1-a"
  metadata_startup_script   = "sudo apt-get update; sudo apt-get install nginx -y"
  deletion_protection       = false
  allow_stopping_for_update = true
  image                     = "ubuntu-os-cloud/ubuntu-2004-focal-v20220712"
  network_interfaces = [
    {
      network        = module.vpc1.vpc_id
      subnetwork     = module.vpc1.subnets[0].id
      access_configs = []
    }
  ]
}

# Instance 2
module "instance2" {
  source                    = "./modules/compute"
  name                      = "vpn-instance2"
  machine_type              = "e2-micro"
  zone                      = "us-east1-b"
  metadata_startup_script   = "sudo apt-get update; sudo apt-get install nginx -y"
  deletion_protection       = false
  allow_stopping_for_update = true
  image                     = "ubuntu-os-cloud/ubuntu-2004-focal-v20220712"
  network_interfaces = [
    {
      network        = module.vpc2.vpc_id
      subnetwork     = module.vpc2.subnets[0].id
      access_configs = []
    }
  ]
}

resource "google_compute_address" "vpn1_static_ip" {
  name = "vpn1-static-ip"
}

module "vpn1" {
  source                  = "./modules/vpn"
  vpc_id                  = module.vpc1.vpc_id
  vpc_name                = module.vpc1.vpc_name
  static_ip               = google_compute_address.vpn1_static_ip.address
  vpn_gateway_name        = "vpn1-gateway"
  vpn_tunnel_name         = "vpn1-tunnel"
  peer_ip                 = google_compute_address.vpn2_static_ip.address
  shared_secret           = "shared-secret"
  route_name              = "route-to-vpc2"
  ike_version             = 2
  dest_range              = module.vpc2.subnets[0].ip_cidr_range
  route_priority          = 1000
  local_traffic_selector  = [module.vpc1.subnets[0].ip_cidr_range]
  remote_traffic_selector = [module.vpc2.subnets[0].ip_cidr_range]
}

resource "google_compute_address" "vpn2_static_ip" {
  name = "vpn2-static-ip"
}

module "vpn2" {
  source                  = "./modules/vpn"
  vpc_id                  = module.vpc2.vpc_id
  vpc_name                = module.vpc2.vpc_name
  static_ip               = google_compute_address.vpn2_static_ip.address
  vpn_gateway_name        = "vpn2-gateway"
  vpn_tunnel_name         = "vpn2-tunnel"
  peer_ip                 = google_compute_address.vpn1_static_ip.address
  shared_secret           = "shared-secret"
  route_name              = "route-to-vpc1"
  ike_version             = 2
  dest_range              = module.vpc1.subnets[0].ip_cidr_range
  route_priority          = 1000
  local_traffic_selector  = [module.vpc2.subnets[0].ip_cidr_range]
  remote_traffic_selector = [module.vpc1.subnets[0].ip_cidr_range]
}
