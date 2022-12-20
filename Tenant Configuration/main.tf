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
  name_alias             = "CyberInsight_vrf"
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
        name_alias                  = "Security_Tools"
        bridge_domain_type          = "regular"
        unicast_route               = "no"
        unk_mac_ucast_act           = "flood"
        unk_mcast_act               = "flood"
        v6unk_mcast_act             = "flood"
        vmac                        = "not-applicable"
        relation_fv_rs_ctx = aci_vrf.CyberInsight_vrf.id
}

#Create subnet and link to bridge domain
resource "aci_subnet" "Security" {
        parent_dn        = aci_bridge_domain.Security_Tools_bridge_domain.id
        description      = "subnet"
        ip               = "192.168.1.1/24"
        annotation       = "tag_subnet"
        ctrl             = ["querier", "nd"]
        name_alias       = "Security_subnet"
        preferred        = "no"
        scope            = ["private", "shared"]
        virtual          = "yes"
}

#Create contract, which allows for communication between different EGPs and filters based off ports/IP's
resource "aci_contract" "Security_to_Linux" {
        tenant_dn   =  aci_tenant.CyberInsight.id
        description = "From Terraform"
        name        = "Security_to_Linux"
        annotation  = "tag_contract"
        name_alias  = "Security_to_Linux"
        prio        = "level1"
        scope       = "tenant"
        target_dscp = "unspecified"
}

#Create contract subject, collection of filters
resource "aci_contract_subject" "Security_to_Linux_subject" {
        contract_dn   = aci_contract.Security_to_Linux.id
        description   = "from terraform"
        name          = "Security_to_Linux_subject"
        annotation    = "tag_subject"
        cons_match_t  = "AtleastOne"
        name_alias    = "Security_to_Linux"
        prio          = "level1"
        prov_match_t  = "AtleastOne"
        rev_flt_ports = "yes" # This changes the destination to the source port for return traffic.
        target_dscp   = "CS0"
}

#Create filter and entry
resource "aci_filter" "RDP" {
        tenant_dn   = aci_tenant.CyberInsight.id
        description = "From Terraform"
        name        = "RDP"
        annotation  = "tag_filter"
        name_alias  = "RDP"
}

resource "aci_filter_entry" "RDP_entry" {
        filter_dn     = aci_filter.RDP.id
        description   = "From Terraform"
        name          = "RDP"
        annotation    = "tag_entry"
        apply_to_frag = "no"
        arp_opc       = "unspecified"
        d_from_port   = "3389"
        d_to_port     = "3389"
        ether_t       = "ipv4"
        icmpv4_t      = "unspecified"
        icmpv6_t      = "unspecified"
        match_dscp    = "CS0"
        name_alias    = "alias_entry"
        prot          = "tcp"
        s_from_port   = "0"
        s_to_port     = "0"
        stateful      = "yes"
        tcp_rules     = ["ack","rst"]
}

#Configured to connect contract subject with filter
resource "aci_contract_subject_filter" "Security_RDP" {
  contract_subject_dn  = aci_contract_subject.Security_to_Linux_subject.id
  filter_dn  = aci_filter.RDP.id
  action = "permit"
  directives = ["none"]
  priority_override = "default"
}