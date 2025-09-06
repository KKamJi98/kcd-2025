# 로컬 변수는 locals.tf로 이동
# Access Entry 관련 로컬 변수는 locals.tf로 이동

module "eks_east" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_names.east
  kubernetes_version = "1.33"

  # vpc-cni 사용 + 접두사 할당 활성화, 코어 애드온 추가
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
      pod_identity_association = local.ebs_csi_pod_identity_associations_east
    }
    metrics-server = {}
    external-dns = {
      pod_identity_association = local.external_dns_pod_identity_associations_east
    }
    snapshot-controller = {}
  }

  # Optional
  endpoint_public_access = true

  # 내장 부트스트랩 비활성화: 별도의 Access Entry로 관리
  enable_cluster_creator_admin_permissions = false

  vpc_id                   = data.terraform_remote_state.basic.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.basic.outputs.public_subnet_ids
  control_plane_subnet_ids = data.terraform_remote_state.basic.outputs.public_subnet_ids

  # 관리형 노드그룹 (Graviton, t4g.small) - 정확히 2대
  eks_managed_node_groups = {
    ops-ng = {
      name           = "opg-ng"
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

      # 개별 노드그룹 SG가 아닌, 공용 Node SG에 규칙 추가로 통일함
    }
  }

  # Access Entry: 현재 Caller 전역 권한 + 외부 주입값 병합
  access_entries = merge(var.access_entries_east, local.cluster_creator_access_entry)

  # metrics-server 포트(10251) 인바운드 허용 (클러스터 SG -> Node SG)
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

module "eks_west" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_names.west
  kubernetes_version = "1.33"

  # vpc-cni 사용 + 접두사 할당 활성화, 코어 애드온 추가
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
      pod_identity_association = local.ebs_csi_pod_identity_associations_west
    }
    metrics-server = {}
    external-dns = {
      pod_identity_association = local.external_dns_pod_identity_associations_west
    }
    snapshot-controller = {}
  }

  # Optional
  endpoint_public_access = true

  # 내장 부트스트랩 비활성화: 별도의 Access Entry로 관리
  enable_cluster_creator_admin_permissions = false

  vpc_id                   = data.terraform_remote_state.basic.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.basic.outputs.public_subnet_ids
  control_plane_subnet_ids = data.terraform_remote_state.basic.outputs.public_subnet_ids

  # 관리형 노드그룹 (Graviton, t4g.small) - 정확히 2대
  eks_managed_node_groups = {
    ops-ng = {
      name           = "ops-ng"
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.small"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 2
      desired_size = 2

      # Use SSH key via Launch Template to avoid remote_access conflict
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
      # 개별 노드그룹 SG가 아닌, 공용 Node SG에 규칙 추가로 통일함
    }
  }

  # Access Entry: 현재 Caller 전역 권한 + 외부 주입값 병합
  access_entries = merge(var.access_entries_west, local.cluster_creator_access_entry)

  # metrics-server 포트(10251) 인바운드 허용 (클러스터 SG -> Node SG)
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

## Pod Identity 관련 리소스는 pod_identity.tf로 분리됨
