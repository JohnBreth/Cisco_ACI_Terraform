terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

# Configure the provider with your Cisco APIC credentials.
provider "aci" {
  # APIC Username
  username = var.user.username
  # APIC Password
  password = var.user.password
  # APIC URL
  url      = var.user.url
  insecure = true
}

#Create Tenant
resource "aci_tenant" "CyberInsight" {
  name        = "CyberInsight"
  description = "from terraform"
  annotation  = "tag"
  name_alias  = "CyberInsight"
}

#Create VRF
resource "aci_vrf" "CyberInsight_vrf" {
  tenant_dn              = aci_tenant.CyberInsight.id
  name                   = "CyberInsight_vrf"
  description            = "from terraform"
  bd_enforced_enable     = "no"
  ip_data_plane_learning = "enabled"
  knw_mcast_act          = "permit"
  name_alias             = "alias_vrf"
  pc_enf_dir             = "egress"
  pc_enf_pref            = "unenforced"
}
