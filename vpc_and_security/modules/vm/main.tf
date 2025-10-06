
resource "google_compute_instance" "mynet_vm_1" {
  name         = "mynet-vm-1"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network = var.networks["mynetwork"]
  }
}

resource "google_compute_instance" "mynet_vm_2" {
  name         = "mynet-vm-2"
  machine_type = "e2-micro"
  zone         = "europe-west1-d"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network = var.networks["mynetwork"]
  }
}

resource "google_compute_instance" "managementnet_vm_1" {
  name         = "managementnet-vm-1"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnets["managementsubnet_1"]
  }
}

resource "google_compute_instance" "privatenet_vm_1" {
  name         = "privatenet-vm-1"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnets["privatesubnet_1"]
  }
}
