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
  name               = "tf-sandbox"
  num_instances      = 1
  machine_type       = "e2-standard-4"
  project_id         = "injae-sandbox"
  zone               = "australia-southeast1-b"
  disk_image         = "injae-sandbox/contosouniversity-lab"
  network            = "default"
  network_tags       = ["allow-win-rdp-all"]
}

resource "random_id" "compute_randomchar" {
  byte_length = 2
}

#############
# Instances
#############

resource "google_compute_instance" "compute_instance" {
  provider = google
  count    = local.num_instances
  name     = "${local.name}-${random_id.compute_randomchar.hex}"
  machine_type = local.machine_type
  project  = local.project_id
  zone     = local.zone
  tags     = local.network_tags

  boot_disk {
    initialize_params {
      image = local.disk_image
    }
  }

  network_interface {
    network            = local.network
    access_config {}
}

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    scopes = ["cloud-platform"]
}

deletion_protection = false

}