# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "ctfd-vpc"
  auto_create_subnetworks = false
}

# Subnet with Private Google Access
resource "google_compute_subnetwork" "subnet" {
  name                     = "ctfd-subnet"
  ip_cidr_range            = var.main_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

# Serverless VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  provider      = google-beta
  name          = "ctfd-vpc-connector"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.access_connector_cidr
}
