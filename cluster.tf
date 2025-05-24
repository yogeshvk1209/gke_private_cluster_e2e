############### GKE Cluster Start #####################

data "google_container_engine_versions" "gkeversion" {
  location = var.cluster_zone
  project = var.project
}

resource "google_container_cluster" "cluster" {
  provider = google-beta
  name     = var.cluster_name
  location = var.cluster_zone
  project  = var.project

  # We'll manage the node pool separately
  remove_default_node_pool = true
  initial_node_count       = var.initial_node_count

  # Use release channel for automatic upgrades
  release_channel {
    channel = "REGULAR"
  }

  network    = google_compute_network.vpc_net.self_link
  subnetwork = google_compute_subnetwork.vpc_subnet.self_link

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes   = true
    master_ipv4_cidr_block = var.master_cidr
    master_global_access_config {
      enabled = false
    }
  }

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_name
    services_secondary_range_name = var.cluster_service_name
  }

  # Security configurations
  security_posture_config {
    mode = "BASIC"
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Enable network policy for pod security
  network_policy {
    enabled = true
    provider = "CALICO"
  }

  # Master authorized networks
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Maintenance window
  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T05:00:00Z"  # 5 AM UTC
      end_time   = "2024-01-01T09:00:00Z"  # 9 AM UTC
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  # Monitoring and logging
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    managed_prometheus {
      enabled = true
    }
  }
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  # Additional security settings
  dynamic "authenticator_groups_config" {
    for_each = var.domain != "" ? [1] : []
    content {
      security_group = "gke-security-groups@${var.domain}"
    }
  }

  resource_labels = {
    environment = var.environment
    managed-by  = "terraform"
  }

  # Disable basic authentication and client certificate
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

# IAM for Workload Identity
resource "google_service_account" "gke_sa" {
  account_id   = "gke-workload-identity-sa"
  display_name = "GKE Workload Identity Service Account"
  project      = var.project
}

resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/monitoring.viewer",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
    "roles/stackdriver.resourceMetadata.writer"
  ])
  
  project = var.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

############### GKE Cluster End #####################
############### GKE Pool Start #####################

resource "google_container_node_pool" "nodepool0" {
  cluster      = google_container_cluster.cluster.name
  location     = var.cluster_zone
  project      = var.project
  version      = data.google_container_engine_versions.gkeversion.latest_node_version
  name         = "dev-pool"
  node_count   = var.node_count

  autoscaling {
    min_node_count = var.autoscaling_min_node_count
    max_node_count = var.autoscaling_max_node_count
  }
  
  node_config {
    preemptible  = true
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    machine_type = var.machine_type
    service_account = var.service_account_email

    # Enable Shielded Nodes
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
 
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