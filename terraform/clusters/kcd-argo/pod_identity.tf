###############################################
# Pod Identity for EBS CSI / ExternalDNS (kcd-argo)
###############################################

resource "aws_iam_role" "ebs_csi_driver_pod_identity" {
  name = "kkamji-ebs-csi-driver-role-argo"
  assume_role_policy = templatefile("${path.module}/../../templates/pod_identity_assume_role_policy.tpl", {
    account_id   = data.aws_caller_identity.current.account_id
    partition    = data.aws_partition.current.partition
    region       = var.region
    cluster_name = local.cluster_name
  })

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_pod_identity" {
  role       = aws_iam_role.ebs_csi_driver_pod_identity.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ExternalDNS policy (per-cluster to avoid name conflict)
resource "aws_iam_policy" "external_dns_policy" {
  name        = "kkamji-external-dns-policy-argo"
  description = "Permissions for ExternalDNS to manage Route53 records (argo)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:route53:::hostedzone/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListHostedZonesByName",
          "route53:ListTagsForResource"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role" "external_dns_pod_identity" {
  name = "kkamji-external-dns-role-argo"
  assume_role_policy = templatefile("${path.module}/../../templates/pod_identity_assume_role_policy.tpl", {
    account_id   = data.aws_caller_identity.current.account_id
    partition    = data.aws_partition.current.partition
    region       = var.region
    cluster_name = local.cluster_name
  })

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "external_dns_policy_attach" {
  role       = aws_iam_role.external_dns_pod_identity.name
  policy_arn = aws_iam_policy.external_dns_policy.arn
}

###############################################
# Pod Identity for AWS Load Balancer Controller (kcd-argo)
###############################################

# IAM policy for ALB Controller (from templates/aws_load_balancer_policy.json)
resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  name        = "kkamji-aws-lbc-policy-argo"
  description = "Permissions for AWS Load Balancer Controller (argo)"

  policy = file("${path.module}/../../templates/aws_load_balancer_policy.json")
}

# IAM role trusted by EKS Pod Identity
resource "aws_iam_role" "aws_load_balancer_controller_pod_identity" {
  name = "kkamji-aws-lbc-role-argo"
  assume_role_policy = templatefile("${path.module}/../../templates/pod_identity_assume_role_policy.tpl", {
    account_id   = data.aws_caller_identity.current.account_id
    partition    = data.aws_partition.current.partition
    region       = var.region
    cluster_name = local.cluster_name
  })

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_policy_attach" {
  role       = aws_iam_role.aws_load_balancer_controller_pod_identity.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller_policy.arn
}
