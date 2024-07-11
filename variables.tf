# Tenancy 
variable "tenancy_ocid" {
  description = "OCID of your tenancy"
  type        = string
}


# Region
variable "region" {
  description = "Region to create the resources"
  type        = string
  default     = "us-ashburn-1"
}

# Compartment
variable "compartment_ocid" {
  description = "OCID of the compartment to create the instance in"
  type        = string
}

# Networking
 variable "vcn_ocid" {
   description = "OCID of the VCN"
   type        = string
 }

variable "subnet_ocid" {
  description = "OCID of the subnet to use"
  type        = string
}

variable "availability_domain" {
  type        = string
  description = "The availability domain of the instance"
}

# Instance details
variable "instance_shape" {
  description = "Shape of the instance"
  type        = string
  default     = "VM.Standard2.1"
}


variable "instance_name" {
  type        = string
  description = "Display name for compute instance"
  default     = "Grafana_Instance"
}

variable "image_ocid" {
  description = "OCID of the image to use"
  type        = string
  default     = "ocid1.image.oc1.iad.aaaaaaaaxtzkhdlxbktlkhiausqz7qvqg7d5jqbrgy6empmrojtdktwfv7fq"
}

# SSH access
variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

# Dynamic Group Name
variable "dynamic_group_name" {
  description = "The name of the dynamic group"
  type        = string
  default     = "Grafana_dg"
}

# Policy group name
variable "group_name" {
  description = "The name of the group to for the policy"
  type        = string
}
