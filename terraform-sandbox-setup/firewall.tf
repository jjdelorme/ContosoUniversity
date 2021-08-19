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
  fw_name           = "allow-win-rdp-all"
  fw_protocol       = "TCP"
  fw_source_range   = ["0.0.0.0/0"]
  fw_ports          = ["3389"]
  fw_network        = "default"
}

resource "google_compute_firewall" "firewall_win_rdp" {
  name              = local.fw_name
  network           = local.fw_network

  allow {
    protocol        = local.fw_protocol
    ports           = local.fw_ports
  }

  source_ranges     = local.fw_source_range

}

