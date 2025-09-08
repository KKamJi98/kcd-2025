# kcd-east cluster

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_name
  kubernetes_version = "1.33"

  addons = {
    coredns    = {}
    kube-proxy = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
        }
      })
    }
    aws-ebs-csi-driver = {
      pod_identity_association = local.ebs_csi_pod_identity_associations
    }
    metrics-server = {}
    external-dns = {
      pod_identity_association = local.external_dns_pod_identity_associations
    }
    snapshot-controller = {}
  }

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = false

  vpc_id                   = data.terraform_remote_state.basic.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.basic.outputs.public_subnet_ids
  control_plane_subnet_ids = data.terraform_remote_state.basic.outputs.public_subnet_ids

  eks_managed_node_groups = {
    ops-ng = {
      name           = "ops-ng"
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.small"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 2
      desired_size = 2

      key_name = data.terraform_remote_state.basic.outputs.key_pair_name

      enable_bootstrap_user_data = true
      cloudinit_pre_nodeadm = [
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  maxPods: 110
          EOT
        }
      ]
    }
  }

  access_entries = merge(var.access_entries, local.cluster_creator_access_entry)

  node_security_group_additional_rules = {
    metrics_server_10251 = {
      description                   = "Allow metrics-server on TCP 10251 from cluster"
      protocol                      = "tcp"
      from_port                     = 10251
      to_port                       = 10251
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}

