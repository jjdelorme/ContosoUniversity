/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

 locals {
  fw_protocol       = "TCP"
  fw_ports          = ["3389"]
  num_instances         = 1
  machine_type          = "e2-standard-4"
  zone1                 = "a"
  zone2                 = "b"
  disk_image_compute    = "injae-sandbox/contosouniversity-lab" 
  disk_size_gb_compute  = 80
  disk_size_gb_containers  = 40
  disk_type_containers  = "pd-standard"
  db_root_pw        = "P@55w0rd!"
  database_version  = "SQLSERVER_2017_EXPRESS"  
  tier              = "db-custom-2-3840"
}

################## HELPER RESOURCES ##################

resource "random_id" "randomchar" {
  byte_length = 2
}

################## HELPER RESOURCES ##################

################## NETWORK RESOURCES ##################

#############
# VPC
#############

resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "firewall_win_rdp" {
  name              = var.fw_name
  network           = var.network

  allow {
    protocol        = local.fw_protocol
    ports           = local.fw_ports
  }

  source_ranges     = [var.fw_source_range]
}

resource "google_compute_firewall" "firewall_win_rdp" {
  name              = var.fw_name
  network           = var.network

  allow {
    protocol        = local.fw_protocol
    ports           = local.fw_ports
  }

  source_ranges     = [var.fw_source_range]
}

#############
# Subnets
#############

resource "google_compute_subnetwork" "subnet1" {
  name          = var.network_vpc_subnet1
  ip_cidr_range = var.network_vpc_subnet1_ip_range
  region        = var.region
  network       = google_compute_network.vpc_network.name
}


resource "google_compute_subnetwork" "gke_subnet_pods" {
  name          = var.network_vpc_subnet_gke_pods
  ip_cidr_range = var.network_vpc_subnet_gke_pods_ip_range
  region        = var.region
  network       = google_compute_network.vpc_network.name
}

resource "google_compute_subnetwork" "gke_subnet_services" {
  name          = var.network_vpc_subnet_gke_services
  ip_cidr_range = var.network_vpc_subnet_gke_services_ip_range
  region        = var.region
  network       = google_compute_network.vpc_network.name
}

################## NETWORK RESOURCES ##################

################## COMPUTE RESOURCES ##################

#############
# GCE Sandbox
#############


resource "google_compute_instance" "compute_instance" {
  provider = google
  count    = local.num_instances
  name     = "${var.name}-${random_id.randomchar.hex}"
  machine_type = local.machine_type
  project  = var.project_id
  zone     = "${var.region}-${local.zone1}"
  tags     = [var.fw_name]

  boot_disk {
    initialize_params {
      size  = local.disk_size_gb_compute
      image = local.disk_image_compute
    }
  }

  network_interface {
    network            = google_compute_network.vpc_network.name
    access_config {}
}

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    scopes = ["cloud-platform"]
}

deletion_protection = false

}

#####################
# Kubernetes cluster
#####################

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  name                       = "${var.name}-${random_id.randomchar.hex}"
  region                     = var.region
  zones                      = ["${var.region}-${local.zone1}","${var.region}-${local.zone2}"]
  network                    = google_compute_network.vpc_network.name
  subnetwork                 = google_compute_subnetwork.subnet1.name
  ip_range_pods              = google_compute_subnetwork.gke_subnet_pods.name
  ip_range_services          = google_compute_subnetwork.gke_subnet_services.name
  http_load_balancing        = false
  horizontal_pod_autoscaling = false
  network_policy             = false

  node_pools = [
    {
      name                      = "${var.name}-default-node-pool"
      machine_type              = local.machine_type
      node_locations            = "${var.region}-${local.zone1},${var.region}-${local.zone2}"
      min_count                 = local.num_instances
      max_count                 = local.num_instances
      local_ssd_count           = 0
      disk_size_gb              = local.disk_size_gb_containers
      disk_type                 = local.disk_type_containers
      image_type                = "COS"
      auto_repair               = true
      auto_upgrade              = true
      preemptible               = false
    },
    {
      name                      = "${var.name}-windows-node-pool"
      machine_type              = local.machine_type
      node_locations            = "${var.region}-${local.zone1},${var.region}-${local.zone2}"
      min_count                 = local.num_instances
      max_count                 = local.num_instances
      local_ssd_count           = 0
      disk_size_gb              = local.disk_size_gb_containers
      disk_type                 = local.disk_type_containers
      image_type                = "WINDOWS_LTSC",
      release_channel           = "regular"
      auto_repair               = true
      auto_upgrade              = false
      preemptible               = false
    },
  ]

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }
}

################## COMPUTE RESOURCES ##################

################## DATABASE RESOURCES ##################

#############
# DB Instances
#############

resource "google_sql_database_instance" "db_instance" {
  name             = "${var.name}-${random_id.randomchar.hex}"
  database_version = local.database_version
  region           = var.region
  root_password    = local.db_root_pw

  settings {
    tier = local.tier

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "allowed-${var.fw_source_range}"
        value = var.fw_source_range
      }
    }
  }

  deletion_protection = false

}

################## DATABASE RESOURCES ##################