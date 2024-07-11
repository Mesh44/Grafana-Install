# Define required providers
terraform {
  required_version = ">= 0.13"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.0.0"
    }
  }
}

# Configure the OCI provider
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
#  user_ocid        = var.user_ocid
#  fingerprint      = var.fingerprint
#  private_key_path = var.private_key_path
  region           = var.region
}

# Data source for availability domain
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

# Create the compute instance
resource "oci_core_instance" "grafana_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_name
  shape               = var.instance_shape

  shape_config {
    ocpus         = 1
    memory_in_gbs = 15
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = var.image_ocid
  }

  # Add SSH key to the instance
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Create Dynamic Group
resource "oci_identity_dynamic_group" "grafana_dynamic_group" {
  compartment_id = var.tenancy_ocid
  name           = var.dynamic_group_name
  description    = "Dynamic group for Grafana instance"
  matching_rule  = "Any {instance.id = '${oci_core_instance.grafana_instance.id}'}"
}


# Create a Policy
resource "oci_identity_policy" "read_all_resources_policy" {
  name           = "AllowGrafanatoReadallResources"
  description    = "Allow msGroup to read all resources in tenancy"
  compartment_id = var.tenancy_ocid
  statements     = ["Allow group ${oci_identity_dynamic_group.grafana_dynamic_group.name} to read all-resources in tenancy"]
  }

# Install and configure Grafana
resource "null_resource" "install_grafana" {
  depends_on = [oci_core_instance.grafana_instance]

  connection {
    type        = "ssh"
    user        = "opc"
     host        = oci_core_instance.grafana_instance.public_ip
   }


   provisioner "remote-exec" {
     inline = [
    "#!/bin/bash",
    "set -x",
    "exec > >(tee /tmp/grafana_install.log) 2>&1",
    "sudo yum install -y https://dl.grafana.com/enterprise/release/grafana-enterprise-11.1.0-1.x86_64.rpm",
    "echo 'Yum install completed'",
    "sudo systemctl daemon-reload",
    "echo 'Daemon reload completed'",
    "sudo systemctl start grafana-server",
    "echo 'Grafana server started'",
    "sudo systemctl enable grafana-server.service",
    "echo 'Grafana server enabled'",
    "sudo grafana-cli plugins install oci-metrics-datasource",
    "echo 'Plugin installation completed'",
    "sudo chown -R grafana:grafana /var/lib/grafana/plugins",
    "echo 'Ownership changed for OCI plugins'",
    "echo 'allow_loading_unsigned_plugins = oci-metrics-datasource' | sudo tee -a /etc/grafana/grafana.ini",
    "sudo systemctl restart grafana-server",
    "echo 'Grafana server re-started'",
    "sudo firewall-cmd --zone=public --add-port=3000/tcp --permanent",
    "echo 'Firewall port added'",
    "sudo firewall-cmd --reload",
    "echo 'Firewall reloaded'",
    "sudo systemctl status grafana-server",
    "echo 'Installation completed'"
    ]
  }
}

# Create a security list to Grafana port 3000
resource "oci_core_security_list" "grafana_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_ocid
  display_name   = "Grafana Security List"

  # Ingress rule for Grafana web access
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    description = "Allow incoming traffic to Grafana web interface"
    tcp_options {
      min = 3000
      max = 3000
    }
  }
}


# Output the public IP of the instance
output "instance_public_ip" {
  value = oci_core_instance.grafana_instance.public_ip
}

output "instance_metadata" {
  value = oci_core_instance.grafana_instance.metadata
}

output "dynamic_group" {
  value = oci_identity_dynamic_group.grafana_dynamic_group.name
}
