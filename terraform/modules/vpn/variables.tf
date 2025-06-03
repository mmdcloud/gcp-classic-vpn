variable "vpn_gateway_name" {
  type        = string  
}

variable "vpn_tunnel_name" {
  type        = string  
}

variable "peer_ip" {
  type        = string  
}

variable "shared_secret" {
  type        = string  
}

variable "static_ip" {
  type        = string  
}

variable "vpc_id" {
  type        = string  
}

variable "vpc_name" {
  type        = string  
}

variable "route_name" {
  type        = string  
}

variable "dest_range" {
  type        = string  
}

variable "route_priority" {
  type        = number  
}

variable "local_traffic_selector" {
  type        = list(string)  
}

variable "remote_traffic_selector" {
  type        = list(string)  
}

variable "ike_version" {
  type        = number  
  default     = 2  
}