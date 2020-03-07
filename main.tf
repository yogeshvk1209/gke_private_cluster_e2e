############### Provider Start ######################

provider "google" {
 region = var.region
}

############### Provider End ######################
############### Backend Start ######################

terraform {
 backend "gcs" {
   bucket  = ""
   prefix  = "gke/state"
 }
}

############### Backend End ######################
