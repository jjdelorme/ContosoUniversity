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
  db_name              = "tf-sandbox-db"
  db_region            = "australia-southeast1"
  db_root_pw           = "P@55w0rd!"
  database_version  = "SQLSERVER_2017_EXPRESS"  
  tier              = "db-custom-2-3840"
  source = ["0.0.0.0"]
}

resource "random_id" "db_randomchar" {
  byte_length = 2
}

resource "google_sql_database_instance" "db_instance" {
  name             = "${local.db_name}-${random_id.db_randomchar.hex}"
  database_version = local.database_version
  region           = local.db_region
  root_password    = local.db_root_pw

  settings {
    tier = local.tier

    ip_configuration {
      ipv4_enabled = true

      dynamic "authorized_networks" {
        for_each = local.source
        iterator = source

        content {
          name  = "allowed-${source.key}"
          value = source.value
        }
      }
    }
  }

  deletion_protection = false

}