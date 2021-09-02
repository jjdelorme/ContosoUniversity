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
  num_instances_compute = 1
  machine_type_compute  = "e2-standard-4"
  zone                  = "a"
  disk_image_compute    = "injae-sandbox/contosouniversity-lab" 
  disk_size_gb_compute  = 80
}

#############
# Instances
#############

resource "random_id" "compute_randomchar" {
  byte_length = 2
}

resource "google_compute_instance" "compute_instance" {
  provider = google
  count    = local.num_instances_compute
  name     = "${var.name}-${random_id.compute_randomchar.hex}"
  machine_type = local.machine_type_compute
  project  = var.project_id
  zone     = "${var.region}-${local.zone}"
  tags     = [var.fw_name]

  boot_disk {
    initialize_params {
      size  = local.disk_size_gb_compute
      image = local.disk_image_compute
    }
  }

  network_interface {
    network            = var.network
    access_config {}
}

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    scopes = ["cloud-platform"]
}

deletion_protection = false

}