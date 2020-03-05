# Terraform GKE Private cluster with end-to-end setup of all components

Complete e2e setup for GKE private cluster with jumphost and all other components setup

## The Setup

  - CLUSTER: 
      Create GKE cluster with 2 modules google_container_cluster and google_container_node_pool. 
      Adding lifecycle parameter enable changing node_count, node_config and autoscalling parameters witout triggering cluster destroy-recreate. 
      Adding private_cluster_config and related fields to make this a private cluster (enable_private_endpoint = true -> to make end-point also private)
  - NETWORK: 
      Create custom VPC with subnet and secondary ranges (for Pods and service). 
      Firewall with SSH rule (with tag = ssh)
      Adding Cloud NAT and cloud_router for nodes to connect to internet to download images
  - COMPUTE: 
      Create jump host with ready-to-ssh from terrafom ran host
      Kubectl binaries installed
      gcloud service account enabled and configured
      k8s cluster config enable for accessing cluster from jumphost
      Passing sample k8s app setup files (pods.yaml and service.yaml) into the jump-host using file provisioner

## The Architecture

![The Architecture Flow](https://github.com/yogeshvk1209/gke_private_cluster_e2e/gke.png)

NOTE: Works with terraform version > 12.00 and google-provider version > 3.10
