######## Variables ###########
variable "project" {
  description = "The project ID where the cluster will be created"
  type        = string
  default     = ""
}

variable "service_account_email" {
  description = "The service account email to use for the cluster nodes"
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "SSH user for the instances"
  type        = string
  default     = "centos"
}

variable "ssh_pub_key_file" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_file" {
  description = "Path to the SSH private key file"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "region" {
  description = "The region where the cluster will be created"
  type        = string
  default     = "us-west1"
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = "gke-e2e-demo"
}

variable "cluster_zone" {
  description = "The zone where the cluster will be created"
  type        = string
  default     = "us-west1-a"
}

variable "network" {
  description = "The name of the network"
  type        = string
  default     = "gke-net-1"
}

variable "subnetwork" {
  description = "The name of the subnetwork"
  type        = string
  default     = "gke-subnet-1"
}

variable "subnetwork_range" {
  description = "The IP range for the subnetwork"
  type        = string
  default     = "192.168.0.0/20"
}

variable "cluster_secondary_name" {
  description = "The name for the cluster's secondary range"
  type        = string
  default     = "gke-pods-1"
}

variable "cluster_service_name" {
  description = "The name for the cluster's service range"
  type        = string
  default     = "gke-services-1"
}

variable "cluster_secondary_range" {
  description = "The IP range for the cluster's pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "cluster_service_range" {
  description = "The IP range for the cluster's services"
  type        = string
  default     = "10.0.32.0/20"
}

variable "master_cidr" {
  description = "The IP range for the master network"
  type        = string
  default     = "172.16.32.0/28"
}

#variable "k8s_version" {
#  default = "1.12"
#}

variable "initial_node_count" {
  description = "The initial number of nodes in the cluster"
  type        = number
  default     = 1
}

variable "node_count" {
  description = "The number of nodes in the cluster"
  type        = number
  default     = 2
}

variable "autoscaling_min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 3
}

variable "disk_size_gb" {
  description = "Size of the disk in GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Type of disk to use"
  type        = string
  default     = "pd-standard"
}

variable "machine_type" {
  description = "Machine type for the nodes"
  type        = string
  default     = "n1-standard-2"
}

# New variables for enhanced security features
variable "environment" {
  description = "Environment (e.g. 'prod', 'staging', 'dev')"
  type        = string
  default     = "dev"
}

variable "domain" {
  description = "The domain for the GKE security group"
  type        = string
  default     = ""
}

variable "enable_vpc_sc" {
  description = "Enable VPC Service Controls"
  type        = bool
  default     = false
}

variable "access_policy_name" {
  description = "The name of the access policy for VPC Service Controls"
  type        = string
  default     = ""
}

variable "authorized_networks" {
  description = "List of authorized networks that can access the cluster's master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

######## Outputs ###########
###### Cluster endpoints ######
output "cluster_endpoint" {
  value = google_container_cluster.cluster.endpoint
}

###### Jumphost Compute instance ######
output "instance_ip" {
  value = google_compute_instance.gke-jumphost.network_interface.0.access_config.0.nat_ip
}

output "workload_identity_pool" {
  description = "Workload Identity Pool for the cluster"
  value       = "${var.project}.svc.id.goog"
}