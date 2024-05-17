variable "add_secondary_vnics" { # TODO: use this
    type = bool
    default = false
    description = "Create secondary_private subnet and move api-int load balancer there, attach secondary vnics secondary_private subnet to all instances, add those secondary_vnic ips to the load balancers and remove the primary ones." 
}

resource "oci_core_subnet" "private2" {
  cidr_block     = var.private_cidr_2
  display_name   = "private_two"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.private_routes.id

  security_list_ids = [
    oci_core_security_list.private.id,
  ]

  dns_label                  = "private2"
  prohibit_public_ip_on_vnic = true
}