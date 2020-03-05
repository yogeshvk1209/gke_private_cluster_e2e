###### Creating custom VPC network ######
resource "google_compute_network" "vpc_net" {
  name          = var.network
  project       = var.project
  auto_create_subnetworks = false
}

###### Creating custom subnet ######
resource "google_compute_subnetwork" "vpc_subnet" {
  name          = var.subnetwork
  project       = var.project
  ip_cidr_range = var.subnetwork_range
  region        = var.region
  network       = google_compute_network.vpc_net.self_link

  secondary_ip_range = [
    {
      range_name    = var.cluster_secondary_name
      ip_cidr_range = var.cluster_secondary_range
    },
    {
      range_name    = var.cluster_service_name
      ip_cidr_range = var.cluster_service_range
    }
  ]
}

###### Creating firewall for Jump-host / bastion-host ######
resource "google_compute_firewall" "allow-bastion" {
  name    = "fw-allow-ssh-bastion"
  project = var.project
  network = google_compute_network.vpc_net.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["ssh"]
}

###### External NAT IP (to be used by cloud-router for nodes-to-internet communication ######
resource "google_compute_address" "nat" {
  name    = format("%s-nat-ip", var.cluster_name)
  project = var.project
  region  = var.region
}

###### Create a cloud router (to be use by the Cloud NAT) ######
resource "google_compute_router" "router" {
  name    = format("%s-cloud-router", var.cluster_name)
  project = var.project
  region  = var.region
  network = google_compute_network.vpc_net.self_link
}

###### Create a cloud NAT (Using cloud-router and NAT IP) ######
resource "google_compute_router_nat" "nat" {
  name    = format("%s-cloud-nat", var.cluster_name)
  project = var.project
  router  = google_compute_router.router.name
  region  = var.region
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips = [google_compute_address.nat.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.vpc_subnet.self_link

    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]

    secondary_ip_range_names = [
      google_compute_subnetwork.vpc_subnet.secondary_ip_range.0.range_name,
      google_compute_subnetwork.vpc_subnet.secondary_ip_range.1.range_name,
    ]
  }
}
