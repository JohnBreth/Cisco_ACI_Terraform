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

#Configure AAEP
resource "aci_attachable_access_entity_profile" "CyberInsight_Security_Tools" {
  description = "AAEP for CyberInsight Security Tools"
  name        = "CyberInsight_Security_Tools"
  annotation  = "tag_entity"
  name_alias  = "Security_Tools"
}

#Configure AAEP to attach domain
resource "aci_aaep_to_domain" "CyberInsight_Security_Tools_aaep_to_CyberInsight_Security_Devices_phy_domain" {
  attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.CyberInsight_Security_Tools.id
  domain_dn                           = aci_physical_domain.CyberInsight_Security_Devices.id
}

#Create Interface Policy Group
resource "aci_leaf_access_port_policy_group" "CyberInsight_Security_Device_access_port_policy_group" {
    description = "From Terraform"
    name        = "CyberInsight_Security_Device_access_port"
    annotation  = "tag_ports"
    name_alias  = "Security_Device_access_port"
    relation_infra_rs_l2_port_security_pol = (aci_port_security_policy.restrict_max1_security_policy.id)
    relation_infra_rs_lldp_if_pol = (aci_lldp_interface_policy.Disable_LLDP.id)
}

#Configure port security with violation protect and maximum of 1
resource "aci_port_security_policy" "restrict_max1_security_policy" {
        description = "From Terraform"
        name        = "restrict_max1_port_pol"
        annotation  = "trestrict_max1_port_pol"
        maximum     = "12"
        name_alias  = "restrict_max1_port_pol"
        timeout     = "60"
        violation   = "protect"
    }

#Disable LLDP on interface
resource "aci_lldp_interface_policy" "Disable_LLDP" {
  description = "Disables LLDP on interface"
  name        = "disable_lldp_pol"
  admin_rx_st = "disabled"
  admin_tx_st = "disabled"
  annotation  = "tag_lldp"
  name_alias  = "disable_lldp"
}

#Create interface profile
resource "aci_leaf_interface_profile" "Int_1-30_interface_profile" {
    description = "From Terraform"
    name        =  "Int_1-30_interface_profile"
    annotation  = "tag_leaf"
    name_alias  = "Int_1-30"
}

#Create port selector
resource "aci_access_port_selector" "Int_1-30_port_selector" {
    leaf_interface_profile_dn = aci_leaf_interface_profile.Int_1-30_interface_profile.id
    description               = "from terraform"
    name                      = "Int_1-30_port_selector"
    access_port_selector_type = "ALL"
    annotation                = "tag_port_selector"
    name_alias                = "Int_1-30_port_selector"
}

#Link port selector to specific interface/block
resource "aci_access_port_block" "Int_1-30_access_port_block" {
  access_port_selector_dn = aci_access_port_selector.Int_1-30_port_selector.id
  description             = "from terraform"
  name                    = "Int_1-30_port_block"
  annotation              = "tag_port_block"
  from_port               = "30"
  name_alias              = "Int_1-30_port_block"
  to_port                 = "30"
}

#Configure leaf switch profile
resource "aci_leaf_profile" "CyberInsight_Leaf1-2" {
  name        = "CyberInsight_Leaf1-2"
  lifecycle {
  ignore_changes = [
       relation_infra_rs_acc_port_p,
       ]
     }
  description  = "From Terraform"
  annotation  = "example"
  name_alias  = "CyberInsight_Leaf1-2"
  leaf_selector {
    name                    = "one"
    switch_association_type = "range"
    node_block {
      name  = "blk1"
      from_ = "101"
      to_   = "102"
    }
  }
}

#Bug in APIC doesn't allow for linking of interface selector in switch profile, need to use this rest command instead
resource "aci_rest" "leaf_profile_to_int_profile_association" {
  path  = "api/mo/${aci_leaf_profile.CyberInsight_Leaf1-2.id}/rsaccPortP-[${aci_leaf_interface_profile.Int_1-30_interface_profile.id}].json"
  class_name = "infraRsAccPortP"
  content = {
    "annotation" : "orchestrator:terraform",
    "tDn" : aci_leaf_interface_profile.Int_1-30_interface_profile.id
  }
}


