## Registry VM Setup
variable "registry_shape" {
  type    = string
  default = "VM.Standard.E4.Flex" # You can choose an appropriate shape
}

variable "registry_ocpu" {
  default = 2
  type    = number
}

variable "registry_memory" {
  default = 8
  type    = number
}

variable "ssh_public_key" {
  description = "Public SSH key for connecting to instances"
  type        = string
  default     = "public key"
}

variable "create_registry_vm" {
  default     = true
  type        = bool
  description = "Flag to create Registry VM"
}

resource "oci_core_network_security_group" "registry_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "registry-nsg"
}

resource "oci_core_network_security_group_security_rule" "registry_nsg_rule_1" {
  network_security_group_id = oci_core_network_security_group.registry_nsg.id
  direction                 = "EGRESS"
  destination               = local.anywhere
  protocol                  = local.all_protocols
}

resource "oci_core_network_security_group_security_rule" "registry_nsg_rule_2" {
  network_security_group_id = oci_core_network_security_group.registry_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = var.vcn_cidr
  tcp_options {
    destination_port_range {
      min = 5000 # Port where the oc-mirror registry will run
      max = 5000
    }
  }
}

resource "oci_core_instance" "oc_mirror_registry" {
  count               = var.create_registry_vm ? 1 : 0
  availability_domain = data.oci_identity_availability_domain.availability_domain.name
  compartment_id      = var.compartment_ocid
  shape               = var.registry_shape

  source_details {
    source_type             = "image"
    source_id               = "ocid1.image.oc1.us-sanjose-1.aaaaaaaaigai4e67hq6fgqxnzt37dclyq6srv3lavqzud3x4yvbamv3ze76q"
    boot_volume_size_in_gbs = 128
  }

  shape_config {
    memory_in_gbs = var.registry_memory
    ocpus         = var.registry_ocpu
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
  }

  launch_options {
    boot_volume_type        = "PARAVIRTUALIZED"
    firmware                = "UEFI_64"
    network_type            = "PARAVIRTUALIZED"
    remote_data_volume_type = "PARAVIRTUALIZED"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  freeform_tags = {
    "Type" = "registry"
  }
}