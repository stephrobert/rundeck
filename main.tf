terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

// instance the provider
provider "libvirt" {
  // uri = "qemu:///system"
  uri = "qemu+ssh://root@devbox/system"
}

// variables that can be overriden
variable "hostname" { default = "rundeck" }
variable "domain" { default = "robert.local" }
variable "ip_type" { default = "dhcp" } # dhcp is other valid type
variable "memoryMB" { default = 1024*2 }
variable "cpu" { default = 2 }

// fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "os_image" {
  name = "${var.hostname}-os_image"
  pool = "default"
  source = "AlmaLinux-8-GenericCloud-latest.x86_64.qcow2"
  format = "qcow2"
}

// Use CloudInit ISO to add ssh-key to the instance
resource "libvirt_cloudinit_disk" "commoninit" {
          name = "${var.hostname}-commoninit.iso"
          pool = "default"
          user_data      = data.template_cloudinit_config.config.rendered
          network_config = data.template_file.network_config.rendered
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    hostname = var.hostname
    fqdn = "${var.hostname}.${var.domain}"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = "${data.template_file.user_data.rendered}"
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config_${var.ip_type}.cfg")
}

// Create the machine
resource "libvirt_domain" "domain-alma" {
  # domain name in libvirt, not hostname
  name = "${var.hostname}"
  memory = var.memoryMB
  vcpu = var.cpu

  disk {
      volume_id = libvirt_volume.os_image.id
  }
  network_interface {
      network_name = "bridged-network"
      mac = "52:54:00:36:14:e8"
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }
}

terraform {
  required_version = ">= 0.12"
}


output "ips" {
  #value = libvirt_domain.domain-alma
  #value = libvirt_domain.domain-alma.*.network_interface
  # show IP, run 'terraform refresh' if not populated
  value = libvirt_domain.domain-alma.*.network_interface
}

