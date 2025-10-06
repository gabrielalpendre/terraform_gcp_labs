
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

module "network" {
  source = "./modules/network"

  project_id = var.project_id
}

module "vm" {
  source = "./modules/vm"

  project_id = var.project_id
  region     = var.region
  zone       = var.zone
  networks   = module.network.networks
  subnets    = module.network.subnets
}
