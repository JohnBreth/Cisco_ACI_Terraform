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

#Create Application Profile, which links polices, services and relationship between EPGs, can contain more than on EPG
resource "aci_application_profile" "CyberInsight_ap" {
  tenant_dn  = aci_tenant.CyberInsight.id
  name       = "CyberInsight_ap"
  description = "from terraform"
  name_alias = "CyberInsight_ap"
}

#Create Application EPG, group of endpoints that require common policies, need contract to communicate between EPG's
resource "aci_application_epg" "CyberInsight_Security_application_epg" {
    application_profile_dn  = aci_application_profile.CyberInsight_ap.id
    name                              = "CyberInsight_Security_application_epg"
    description                   = "from terraform"
    annotation                    = "tag_epg"
    exception_tag                 = "0"
    flood_on_encap            = "disabled"
    fwd_ctrl                      = "none"
    has_mcast_source             = "no"
    is_attr_based_epg         = "no"
    match_t                          = "AtleastOne"
    name_alias                  = "CyberInsight_Security_epg"
    pc_enf_pref                  = "unenforced"
    pref_gr_memb                  = "exclude"
    prio                              = "unspecified"
    shutdown                      = "no"
    relation_fv_rs_bd       = aci_bridge_domain.Security_Tools_bridge_domain.id
}

#Create second EPG
resource "aci_application_epg" "CyberInsight_Linux_application_epg" {
    application_profile_dn  = aci_application_profile.CyberInsight_ap.id
    name                              = "CyberInsight_Linux_application_epg"
    description                   = "from terraform"
    annotation                    = "tag_epg"
    exception_tag                 = "0"
    flood_on_encap            = "disabled"
    fwd_ctrl                      = "none"
    has_mcast_source             = "no"
    is_attr_based_epg         = "no"
    match_t                          = "AtleastOne"
    name_alias                  = "CyberInsight_Linux_epg"
    pc_enf_pref                  = "unenforced"
    pref_gr_memb                  = "exclude"
    prio                              = "unspecified"
    shutdown                      = "no"
}

#Create Bridge Domain, broadcast domain associated with one or more subnets
resource "aci_bridge_domain" "Security_Tools_bridge_domain" {
        tenant_dn                   = aci_tenant.CyberInsight.id
        description                 = "from terraform"
        name                        = "Security_Tools_bd"
        optimize_wan_bandwidth      = "no"
        annotation                  = "tag_bd"
        arp_flood                   = "no"
        ep_clear                    = "no"
        ep_move_detect_mode         = "garp"
        host_based_routing          = "no"
        intersite_bum_traffic_allow = "yes"
        intersite_l2_stretch        = "yes"
        ip_learning                 = "yes"
        ipv6_mcast_allow            = "no"
        limit_ip_learn_to_subnets   = "yes"
        ll_addr                     = "::"
        mac                         = "00:22:BD:F8:19:FF"
        mcast_allow                 = "yes"
        multi_dst_pkt_act           = "bd-flood"
        name_alias                  = "alias_bd"
        bridge_domain_type          = "regular"
        unicast_route               = "no"
        unk_mac_ucast_act           = "flood"
        unk_mcast_act               = "flood"
        v6unk_mcast_act             = "flood"
        vmac                        = "not-applicable"
    }
