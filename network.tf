############### Network Start #####################
resource "google_compute_network" "vpc_net" {
  name                    = "${var.cluster_name}-network"
  auto_create_subnetworks = false
  project                = var.project
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  project       = var.project
  network       = google_compute_network.vpc_net.self_link

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.cluster_secondary_name
    ip_cidr_range = var.cluster_secondary_cidr
  }

  secondary_ip_range {
    range_name    = var.cluster_service_name
    ip_cidr_range = var.cluster_service_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata           = "INCLUDE_ALL_METADATA"
  }
}

# Cloud NAT configuration
resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.vpc_net.self_link
  project = var.project

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                            = google_compute_router.router.name
  region                            = var.region
  project                           = var.project
  nat_ip_allocate_option           = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  
  subnetwork {
    name                    = google_compute_subnetwork.vpc_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.cluster_name}-allow-internal"
  network = google_compute_network.vpc_net.name
  project = var.project

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = [
    var.subnet_cidr,
    var.cluster_secondary_cidr,
    var.cluster_service_cidr
  ]
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.cluster_name}-allow-ssh-iap"
  network = google_compute_network.vpc_net.name
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Allow SSH only through Identity-Aware Proxy
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["ssh"]
}

# VPC Service Controls (optional)
resource "google_access_context_manager_service_perimeter" "gke_service_perimeter" {
  count = var.enable_vpc_sc ? 1 : 0
  
  parent = "accessPolicies/${var.access_policy_name}"
  name   = "accessPolicies/${var.access_policy_name}/servicePerimeters/${var.cluster_name}"
  title  = "${var.cluster_name}-perimeter"
  
  status {
    restricted_services = [
      "container.googleapis.com",
      "compute.googleapis.com",
    ]
    
    vpc_accessible_services {
      enable_restriction = true
      allowed_services  = ["container.googleapis.com"]
    }

    ingress_policies {
      ingress_from {
        sources {
          access_level = google_access_context_manager_access_level.basic_access.name
        }
        identity_type = "ANY_IDENTITY"
      }
      ingress_to {
        resources = ["*"]
        operations {
          service_name = "container.googleapis.com"
          method_selectors {
            method = "*"
          }
        }
      }
    }
  }
}