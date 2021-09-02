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

variable "project_id" {
  description = "Name of the project ID [REQUIRED]"
}

variable "region" {
  description = "Name of the region"
  default     = "australia-southeast1"
}

variable "network" {
  description = "Name of the VPC network"
  default     = "contosovpc"
}

variable "network_vpc_subnet1" {
  description = "Name of the VPC subnetwork 1"
  default     = "subnet1"
}

variable "network_vpc_subnet1_ip_range" {
  description = "RFC1918 IP range for VPC in CIDR format eg. 192.168.0.0/16"
  default     = "192.168.0.0/16"
}

variable "name" {
  description = "Name of the resource"
  default     = "contosouni"
}

variable "fw_name" {
  description = "Name of the firewall resource"
  default     = "allow-win-rdp-all"
}

variable "fw_source_range" {
  description = "allowed source IP address for firewall in CIDR format including [] eg. [1.2.3.4/32]"
  default     = "0.0.0.0/0"
}
