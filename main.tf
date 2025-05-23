############### Provider Start ######################
provider "google" {
 region = var.region
 project = var.project
}

provider "google-beta" {
 region = var.region
 project = var.project
}
############### Provider End ######################
############### Backend Start ######################
terraform {
 required_version = ">= 1.12"
 required_providers {
   google = {
     source  = "hashicorp/google"
     version = "~> 6.30.0"
   }
   google-beta = {
     source  = "hashicorp/google-beta"
     version = "~> 6.30.0"
   }
 }
 backend "gcs" {
   bucket = "" # TODO: specify your state bucket
   prefix = "gke/state"
 }
}

data "google_project" "project" {
 project_id = var.project
}
############### Backend End ######################