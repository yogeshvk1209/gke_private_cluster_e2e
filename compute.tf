data "google_compute_zones" "available" {
  project = var.project
}

### Creating jump-host / bastion-host  ###
resource "google_compute_instance" "gke-jumphost" {
  name         = "gke-jumphost"
  project      = var.project
  machine_type = "n1-standard-1"
  zone         = data.google_compute_zones.available.names[0]
  tags         = ["ssh"]

  service_account {
    email = var.service_account_email
    scopes = ["cloud-platform"]
  }

  boot_disk {
    initialize_params {
      image = "centos-7"
    }
  }

  network_interface {
    network      = google_compute_network.vpc_net.self_link
    subnetwork   = google_compute_subnetwork.vpc_subnet.self_link
    access_config {}
  }

  metadata = {
    ssh-keys        = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"
    startup-script  = file("./startup-script")
    } 

## Copying files for k8s pod and service sample app
  provisioner "file" {
    source = "./sampleapp"
    destination = "/home/centos/"

    connection {
             type = "ssh"
             user = "centos"
             host = google_compute_instance.gke-jumphost.network_interface.0.access_config.0.nat_ip
             private_key = file("~/.ssh/id_rsa")
             timeout = "3m"
             agent = "false"
    }
  }    

  depends_on = [google_container_node_pool.nodepool0]
}