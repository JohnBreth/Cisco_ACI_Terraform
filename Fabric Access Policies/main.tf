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
