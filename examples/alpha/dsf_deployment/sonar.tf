locals {
  database_cidr      = var.database_cidr != null ? var.database_cidr : local.workstation_cidr_24
  tarball_location   = module.globals.tarball_location
  agentless_gw_count = var.enable_dsf_hub ? var.agentless_gw_count : 0
}

module "hub" {
  source  = "imperva/dsf-hub/aws"
  version = "1.4.5" # latest release tag
  count  = var.enable_dsf_hub ? 1 : 0

  friendly_name               = join("-", [local.deployment_name_salted, "hub"])
  subnet_id                   = local.hub_subnet_id
  binaries_location           = local.tarball_location
  web_console_admin_password  = local.password
  ebs                         = var.hub_ebs_details
  attach_persistent_public_ip = true
  use_public_ip               = true
  generate_access_tokens      = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.hub_secondary.cidr_block]
  allowed_agentless_gw_cidrs        = [data.aws_subnet.agentless_gw.cidr_block, data.aws_subnet.agentless_gw_secondary.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr
  mx_details = var.enable_dsf_dam ? [{
    name     = module.mx[0].display_name
    address  = module.mx[0].private_ip
    username = module.mx[0].web_console_user
    password = local.password
  }] : []
  tags = local.tags
  depends_on = [
    module.vpc
  ]
}

module "hub_secondary" {
  source  = "imperva/dsf-hub/aws"
  version = "1.4.5" # latest release tag
  count  = var.enable_dsf_hub && var.hub_hadr ? 1 : 0

  friendly_name               = join("-", [local.deployment_name_salted, "hub", "secondary"])
  subnet_id                   = local.hub_secondary_subnet_id
  binaries_location           = local.tarball_location
  web_console_admin_password  = local.password
  ebs                         = var.hub_ebs_details
  attach_persistent_public_ip = true
  use_public_ip               = true
  hadr_secondary_node         = true
  sonarw_public_key           = module.hub[0].sonarw_public_key
  sonarw_private_key          = module.hub[0].sonarw_private_key
  generate_access_tokens      = true
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_web_console_and_api_cidrs = var.web_console_cidr
  allowed_hub_cidrs                 = [data.aws_subnet.hub.cidr_block]
  allowed_agentless_gw_cidrs        = [data.aws_subnet.agentless_gw.cidr_block, data.aws_subnet.agentless_gw_secondary.cidr_block]
  allowed_all_cidrs                 = local.workstation_cidr
  tags                              = local.tags
  depends_on = [
    module.vpc
  ]
}

module "hub_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.4.5" # latest release tag

  count = length(module.hub_secondary) > 0 ? 1 : 0

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.hub[0].public_ip
  dsf_primary_private_ip   = module.hub[0].private_ip
  dsf_secondary_ip         = module.hub_secondary[0].public_ip
  dsf_secondary_private_ip = module.hub_secondary[0].private_ip
  ssh_key_path             = module.key_pair.private_key_file_path
  ssh_user                 = module.hub[0].ssh_user
  depends_on = [
    module.hub,
    module.hub_secondary
  ]
}

module "agentless_gw_group" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.4.5" # latest release tag
  count  = local.agentless_gw_count

  friendly_name              = join("-", [local.deployment_name_salted, "agentless", "gw", count.index])
  subnet_id                  = local.agentless_gw_subnet_id
  ebs                        = var.gw_group_ebs_details
  binaries_location          = local.tarball_location
  web_console_admin_password = local.password
  hub_sonarw_public_key      = module.hub[0].sonarw_public_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.agentless_gw_secondary.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.hub.cidr_block, data.aws_subnet.hub_secondary.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc,
  ]
}

module "agentless_gw_group_secondary" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "1.4.5" # latest release tag
  count  = var.agentless_gw_hadr ? local.agentless_gw_count : 0

  friendly_name              = join("-", [local.deployment_name_salted, "agentless", "gw", "secondary", count.index])
  subnet_id                  = local.agentless_gw_secondary_subnet_id
  ebs                        = var.gw_group_ebs_details
  binaries_location          = local.tarball_location
  web_console_admin_password = local.password
  hub_sonarw_public_key      = module.hub[0].sonarw_public_key
  hadr_secondary_node        = true
  sonarw_public_key          = module.agentless_gw_group[count.index].sonarw_public_key
  sonarw_private_key         = module.agentless_gw_group[count.index].sonarw_private_key
  ssh_key_pair = {
    ssh_private_key_file_path = module.key_pair.private_key_file_path
    ssh_public_key_name       = module.key_pair.key_pair.key_pair_name
  }
  allowed_agentless_gw_cidrs = [data.aws_subnet.agentless_gw.cidr_block]
  allowed_hub_cidrs          = [data.aws_subnet.hub.cidr_block, data.aws_subnet.hub_secondary.cidr_block]
  allowed_all_cidrs          = local.workstation_cidr
  ingress_communication_via_proxy = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  tags = local.tags
  depends_on = [
    module.vpc,
  ]
}

module "agentless_gw_group_hadr" {
  source  = "imperva/dsf-hadr/null"
  version = "1.4.5" # latest release tag
  count   = length(module.agentless_gw_group_secondary)

  sonar_version            = module.globals.tarball_location.version
  dsf_primary_ip           = module.agentless_gw_group[count.index].private_ip
  dsf_primary_private_ip   = module.agentless_gw_group[count.index].private_ip
  dsf_secondary_ip         = module.agentless_gw_group_secondary[count.index].private_ip
  dsf_secondary_private_ip = module.agentless_gw_group_secondary[count.index].private_ip
  ssh_key_path             = module.key_pair.private_key_file_path
  ssh_user                 = module.agentless_gw_group[count.index].ssh_user
  proxy_info = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  depends_on = [
    module.agentless_gw_group,
    module.agentless_gw_group_secondary
  ]
}

locals {
  hubs = concat(
    [for idx, val in module.hub : val],
    [for idx, val in module.hub_secondary : val]
  )
  agentless_gws = concat(
    [for idx, val in module.agentless_gw_group : val],
    [for idx, val in module.agentless_gw_group_secondary : val]
  )
  hub_gw_combinations = setproduct(local.hubs, local.agentless_gws)
}

module "federation" {
  source  = "imperva/dsf-federation/null"
  version = "1.4.5" # latest release tag
  count   = length(local.hub_gw_combinations)

  gw_info = {
    gw_ip_address           = local.hub_gw_combinations[count.index][1].private_ip
    gw_private_ssh_key_path = module.key_pair.private_key_file_path
    gw_ssh_user             = local.hub_gw_combinations[count.index][1].ssh_user
  }
  hub_info = {
    hub_ip_address           = local.hub_gw_combinations[count.index][0].public_ip
    hub_private_ssh_key_path = module.key_pair.private_key_file_path
    hub_ssh_user             = local.hub_gw_combinations[count.index][0].ssh_user
  }
  gw_proxy_info = {
    proxy_address              = module.hub[0].public_ip
    proxy_private_ssh_key_path = module.key_pair.private_key_file_path
    proxy_ssh_user             = module.hub[0].ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_group_hadr
  ]
}