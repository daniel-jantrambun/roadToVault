terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.53.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
  backend "gcs" {
    prefix = "state"
  }

  required_version = ">= 0.14"
}

resource "random_id" "id" {
  byte_length = 4
}

provider "google" {
  credentials = file(var.terraform_credentials_path)

  project = var.project_id
  region  = var.region
  zone    = var.zone
}


# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

resource "random_id" "cluster" {
  byte_length = 4
}

resource "random_id" "services" {
  byte_length = 4
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.project_id}-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc.name
  ip_cidr_range            = "192.168.1.0/24"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${var.cluster_secondary_range_name}-${random_id.cluster.hex}"
    ip_cidr_range = "10.56.0.0/14"
  }

  secondary_ip_range {
    range_name    = "${var.services_secondary_range_name}-${random_id.services.hex}"
    ip_cidr_range = "10.60.0.0/20"
  }
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name         = var.cluster_name
  location     = var.zone
  release_channel {
    channel = "UNSPECIFIED"
  }
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER"]
  }

  network    = "projects/${var.project_id}/global/networks/${var.project_id}-vpc"
  subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.project_id}-subnet"

  default_max_pods_per_node = 110
  node_locations = []

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "192.168.0.0/28"
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.subnet.secondary_ip_range[1].range_name
  }
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  initial_node_count       = 1
  remove_default_node_pool = true
}

# Separately Managed Node Pool
resource "google_container_node_pool" "prod-pool" {
  name     = "prod-pool-a-${random_id.id.hex}"
  location = var.zone
  cluster  = google_container_cluster.primary.name
  initial_node_count = var.gke_prod_pool_initial_nodes

  # Autoscaling config.
  autoscaling {
    min_node_count = var.gke_min_prod_pool_nodes
    max_node_count = var.gke_max_prod_pool_nodes
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  # Management Config
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible = false

    disk_type    = var.gke_node_disk_type
    disk_size_gb = var.gke_node_disk_size
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = var.project_id
    }

    machine_type = var.gke_node_machine_type
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "pre-emptible-pool" {
  name               = "pre-emptible-pool-${random_id.id.hex}"
  version            = var.cluster_kubernetes_version
  location           = var.zone
  cluster            = google_container_cluster.primary.name
  initial_node_count = var.gke_pre_emptible_pool_initial_nodes

  # Autoscaling config.
  autoscaling {
    min_node_count = var.gke_min_pre_emptible_pool_nodes
    max_node_count = var.gke_max_pre_emptible_pool_nodes
  }

  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }

  # Management Config
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
  node_config {
    preemptible = true

    disk_type    = var.gke_node_disk_type
    disk_size_gb = var.gke_node_disk_size
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = var.project_id
    }

    machine_type = var.gke_node_machine_type
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
