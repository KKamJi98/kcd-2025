locals {
  cluster_name = "kcd-argo"
}

locals {
  cluster_creator_access_entry = {
    cluster_creator = {
      principal_arn = data.aws_iam_session_context.current.issuer_arn
      type          = "STANDARD"
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
        admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

locals {
  ebs_csi_pod_identity_associations = [
    {
      role_arn        = aws_iam_role.ebs_csi_driver_pod_identity.arn
      service_account = "ebs-csi-controller-sa"
      namespace       = "kube-system"
    }
  ]
}

locals {
  external_dns_pod_identity_associations = [
    {
      role_arn        = aws_iam_role.external_dns_pod_identity.arn
      service_account = "external-dns"
      namespace       = "kube-system"
    }
  ]
}

