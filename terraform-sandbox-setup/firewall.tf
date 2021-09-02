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
