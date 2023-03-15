output "dsf_agentless_gw_group" {
  value = {
    for idx, val in module.agentless_gw_group : "gw-${idx}" => {
      primary = {
        private_ip   = try(module.agentless_gw_group[idx].private_ip, null)
        private_dns  = try(module.agentless_gw_group[idx].private_dns, null)
        jsonar_uid   = try(module.agentless_gw_group[idx].jsonar_uid, null)
        display_name = try(module.agentless_gw_group[idx].display_name, null)
        role_arn     = try(module.agentless_gw_group[idx].iam_role, null)
        ssh_command  = try("ssh -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -i ${nonsensitive(module.key_pair_hub.key_pair_private_pem.filename)} -W %h:%p ${module.hub_primary.ssh_user}@${module.hub_primary.private_ip}' -i ${nonsensitive(module.key_pair_gw.key_pair_private_pem.filename)} ${module.agentless_gw_group[idx].ssh_user}@${module.agentless_gw_group[idx].private_ip}", null)
      }
    }
  }
}

output "dsf_hubs" {
  value = {
    primary = {
      private_ip   = try(module.hub_primary.private_ip, null)
      jsonar_uid   = try(module.hub_primary.jsonar_uid, null)
      display_name = try(module.hub_primary.display_name, null)
      role_arn     = try(module.hub_primary.iam_role, null)
      ssh_command  = try("ssh -i ${nonsensitive(module.key_pair_hub.key_pair_private_pem.filename)} ${module.hub_primary.ssh_user}@${module.hub_primary.private_ip}", null)
    }
    secondary = {
      private_ip   = try(module.hub_secondary.private_ip, null)
      jsonar_uid   = try(module.hub_secondary.jsonar_uid, null)
      display_name = try(module.hub_secondary.display_name, null)
      role_arn     = try(module.hub_secondary.iam_role, null)
      ssh_command  = try("ssh -i ${nonsensitive(module.key_pair_hub.key_pair_private_pem.filename)} ${module.hub_secondary.ssh_user}@${module.hub_secondary.private_ip}", null)
    }
  }
}

output "dsf_hub_web_console" {
  value = {
    private_url    = try(join("", ["https://", module.hub_primary.private_ip, ":8443/"]), null)
    admin_password = nonsensitive(local.web_console_admin_password)
  }
}

output "deployment_name" {
  value = local.deployment_name_salted
}

output "dsf_hub_ssh_key" {
  sensitive = true
  value     = module.key_pair_hub.key_pair_private_pem
}

output "dsf_gws_ssh_key" {
  sensitive = true
  value     = module.key_pair_gw.key_pair_private_pem
}