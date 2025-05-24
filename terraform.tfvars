project = "your-project-id"
region  = "us-central1"
cluster_name = "private-gke-cluster"

# Subnet CIDR ranges
subnetwork_range = "10.0.0.0/24"

# Secondary IP ranges for GKE
cluster_secondary_name = "gke-pods"
cluster_secondary_range = "10.1.0.0/16"
cluster_service_name   = "gke-services"
cluster_service_range   = "10.2.0.0/16"

# VPC Service Controls (optional)
enable_vpc_sc = false
access_policy_name = ""  # Only required if enable_vpc_sc is true 