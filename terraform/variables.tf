variable "terraform_credentials_path" {
  description = "you terraforme json key file name, stored in terraform folder"
}

variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "terraform_bucket_name" {
  description = "terraform bucket name used to store state file"
}

variable "cluster_name" {
  description = "cluster name"
}

variable "cluster_kubernetes_version" {
  description = "cluster kubernetes version"
}

variable "cluster_secondary_range_name" {
  description = "The name of the secondary range within the subnetwork for the cluster to use"
  type        = string
  default     = null
}

variable "services_secondary_range_name" {
  description = "The name of the secondary range within the subnetwork for the services to use"
  type        = string
  default     = null
}

variable "gke_prod_pool_initial_nodes" {
  description = "number of initial nodes for prod pool"
}
variable "gke_min_prod_pool_nodes" {
  description = "Min number of nodes for prod pool"
}

variable "gke_max_prod_pool_nodes" {
  description = "Max number of nodes for prod pool"
}

variable "gke_pre_emptible_pool_initial_nodes" {
  description = "number of initial nodes for pre-emptible pool"
}
variable "gke_min_pre_emptible_pool_nodes" {
  description = "Min number of nodes for pre-emptible pool"
}
variable "gke_max_pre_emptible_pool_nodes" {
  description = "Max number of nodes for pre-emptible  pool"
}

variable "gke_node_machine_type" {
  description = "node machine type"
}

variable "gke_node_disk_type" {
  description = "node disk type"
}

variable "gke_node_disk_size" {
  description = "node disk size"
}
