
############### GKE Cluster Start #####################

data "google_container_engine_versions" "gkeversion" {
  location           = "us-west1"
  #version_prefix = var.k8s_version
  project            = var.project
}

resource "google_container_cluster" "cluster" {
  name               = var.cluster_name

## Add location for multi AZ worker nodes
#location           = var.region

  location           =var.cluster_zone
  project            = var.project
  min_master_version = data.google_container_engine_versions.gkeversion.latest_master_version
  network            = google_compute_network.vpc_net.self_link
  subnetwork         = google_compute_subnetwork.vpc_subnet.self_link
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"
  remove_default_node_pool = "true"
  initial_node_count       = 1

  ip_allocation_policy{
    cluster_secondary_range_name = var.cluster_secondary_name
    services_secondary_range_name = var.cluster_service_name
  }
  
  maintenance_policy {
    daily_maintenance_window {
      start_time = "05:00"
    }
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes = true
    master_ipv4_cidr_block = var.master_cidr
  }

  master_auth {
     username = ""
     password = ""

     client_certificate_config {
       issue_client_certificate = "false"
     }
  }

  master_authorized_networks_config {}

}

############### GKE Cluster End #####################
############### GKE Pool Start #####################

resource "google_container_node_pool" "nodepool0" {
  cluster      = google_container_cluster.cluster.name

##Add location for multi AZ worker nodes
#location    = var.region

  location     = var.cluster_zone
  project      = var.project
  version      = data.google_container_engine_versions.gkeversion.latest_node_version
  name    = "dev-pool"
  node_count = var.node_count

  autoscaling {
    min_node_count = var.autoscaling_min_node_count
    max_node_count = var.autoscaling_max_node_count
  }
  
  node_config {
    preemptible  = true
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    machine_type = var.machine_type
    service_account    = var.service_account_email
 
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
 
  depends_on = [google_container_cluster.cluster]
}

############### GKE Pool End #####################
