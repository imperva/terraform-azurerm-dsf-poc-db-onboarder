variable "gw" {
  type        = string
  nullable    = false
  description = "IP address or FQDN of the agentless gw. Must be accessible by the DSF Hub"
}

variable "hub" {
  type        = string
  nullable    = false
  description = "IP address or FQDN of the DSF hub. Must be accessible using SSH by the Terraform workstation"
}

variable "hub_ssh_key_path" {
  type        = string
  nullable    = false
  description = "Path of local ssh key file for DSF hub"
}

variable "gw_ssh_key_path" {
  type        = string
  description = "Path of local ssh key file for DSF GW"
  nullable    = false
}

variable "installation_source" {
  type        = string
  description = "Changing this variable forces a re-federation process"
}