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

#Configured VLAN Pool
resource "aci_vlan_pool" "CyberInsight100" {
  name  = "CyberInsight100"
  description = "From Terraform"
  alloc_mode  = "static"
  annotation  = "CyberInsight100"
  name_alias  = "CyberInsight100"
}

#Configure VLAN Range
resource "aci_ranges" "range_1" {
  vlan_pool_dn  = aci_vlan_pool.CyberInsight100.id
  description   = "From Terraform"
  from          = "vlan-100"
  to            = "vlan-100"
  alloc_mode    = "inherit"
  annotation    = "CyberInsight100"
  name_alias    = "CyberInsight100"
  role          = "external"
}
#Configure physical domain (physical endpoint connection)
resource "aci_physical_domain" "CyberInsight_Security_Devices" {
  name        = "CyberInsight_Security_Devices"
  annotation  = "Security_Device_Domain"
  name_alias  = "Security_Device_Domain"
  relation_infra_rs_vlan_ns = aci_vlan_pool.CyberInsight100.id
}

#Configure L3 domain(connecting to external network/router/firewall/etc)
resource "aci_l3_domain_profile" "CyberInsight_Firewall" {
  name       = "CyberInsight_Firewall"
  annotation = "External_connection_to_internet"
  name_alias = "CyberInsight_Firewall"
}