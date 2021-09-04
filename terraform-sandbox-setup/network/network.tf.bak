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


#############
# VPC
#############

resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network
  auto_create_subnetworks = false
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


resource "google_compute_subnetwork" "gke-subnet-pods" {
  name          = var.network_vpc_subnet_gke_pods
  ip_cidr_range = var.network_vpc_subnet_gke_pods_ip_range
  region        = var.region
  network       = google_compute_network.vpc_network.name
}

resource "google_compute_subnetwork" "gke-subnet-services" {
  name          = var.network_vpc_subnet_gke_services
  ip_cidr_range = var.network_vpc_subnet_gke_services_ip_range
  region        = var.region
  network       = google_compute_network.vpc_network.name
}