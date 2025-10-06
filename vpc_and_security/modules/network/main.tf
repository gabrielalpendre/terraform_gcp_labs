
resource "google_compute_network" "mynetwork" {
  name                    = "mynetwork"
  auto_create_subnetworks = false
}

resource "google_compute_network" "managementnet" {
  name                    = "managementnet"
  auto_create_subnetworks = false
}

resource "google_compute_network" "privatenet" {
  name                    = "privatenet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "managementsubnet_1" {
  name          = "managementsubnet-1"
  ip_cidr_range = "10.240.0.0/20"
  region        = "us-central1"
  network       = google_compute_network.managementnet.id
}

resource "google_compute_subnetwork" "privatesubnet_1" {
  name          = "privatesubnet-1"
  ip_cidr_range = "172.16.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.privatenet.id
}

resource "google_compute_subnetwork" "privatesubnet_2" {
  name          = "privatesubnet-2"
  ip_cidr_range = "172.20.0.0/20"
  region        = "europe-west1"
  network       = google_compute_network.privatenet.id
}

resource "google_compute_firewall" "managementnet_firewall" {
  name    = "managementnet-allow-icmp-ssh-rdp"
  network = google_compute_network.managementnet.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22","3389"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "privatenet_firewall" {
  name    = "privatenet-allow-icmp-ssh-rdp"
  network = google_compute_network.privatenet.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22","3389"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}

output "networks" {
  value = {
    mynetwork      = google_compute_network.mynetwork.id
    managementnet  = google_compute_network.managementnet.id
    privatenet     = google_compute_network.privatenet.id
  }
}

output "subnets" {
  value = {
    managementsubnet_1 = google_compute_subnetwork.managementsubnet_1.id
    privatesubnet_1   = google_compute_subnetwork.privatesubnet_1.id
    privatesubnet_2   = google_compute_subnetwork.privatesubnet_2.id
  }
}
