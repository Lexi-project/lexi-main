terraform {
  required_providers {
    multipass = {
      source = "larstobi/multipass"
      version = "1.4.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
}

provider "multipass" {}

provider "kubernetes" {
  config_path = "./k3s.yaml"
  config_context = "default"
}

resource "multipass_instance" "k3s_master" {
  count  = var.master_node_count
  name   = "k3s-master-${count.index}"
  disk = "10GiB"
}

resource "multipass_instance" "k3s_worker" {
  depends_on = [ multipass_instance.k3s_master, null_resource.install_kubernetes_master ]
  count  = var.worker_node_count
  name   = "k3s-worker-${count.index}"
  disk = "10GiB"
}

resource "null_resource" "install_kubernetes_master" {
  count = var.master_node_count
  depends_on = [multipass_instance.k3s_master]

  provisioner "local-exec" {
    command = "multipass exec ${multipass_instance.k3s_master[count.index].name} -- bash -c 'curl -sfL https://get.k3s.io | sh -'"
  }
} 

resource "null_resource" "install_kubernetes_worker" {
  count = var.worker_node_count
  depends_on = [multipass_instance.k3s_master, null_resource.install_kubernetes_master, multipass_instance.k3s_worker]

  provisioner "local-exec" {
    command = <<-EOT
      IP=$(multipass info ${multipass_instance.k3s_master[0].name} | grep IPv4 | awk '{print $2}')
      TOKEN=$(multipass exec ${multipass_instance.k3s_master[0].name} -- sudo cat /var/lib/rancher/k3s/server/node-token)
      multipass exec ${multipass_instance.k3s_worker[count.index].name} -- bash -c "curl -sfL https://get.k3s.io | K3S_URL=https://$IP:6443 K3S_TOKEN=$TOKEN sh -"
    EOT
  }
}