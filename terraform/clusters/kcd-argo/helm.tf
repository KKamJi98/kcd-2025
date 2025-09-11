###############################################
# AWS Load Balancer Controller via Helm (kcd-argo)
###############################################

resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.13.0"
  namespace        = "kube-system"
  create_namespace = false

  # Ensure cluster is available before Helm install
  depends_on = [module.eks]

  set = [
    {
      name  = "clusterName"
      value = local.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }
  ]
}

###############################################
# Argo CD via Helm (kcd-argo)
###############################################

resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [module.eks]

  values = [<<-YAML
    global:
      domain: argocd-kcd.kkamji.net

    certificate:
      enabled: true

    server:
      replicas: 1
      ingress:
        enabled: true
        ingressClassName: alb
        hostname: argocd-kcd.kkamji.net
        tls: true
        annotations:
          alb.ingress.kubernetes.io/scheme: internet-facing
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
          alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
          alb.ingress.kubernetes.io/backend-protocol: "HTTPS"
          alb.ingress.kubernetes.io/certificate-arn: ${data.terraform_remote_state.acm.outputs.acm_certificate_arn}

    redis-ha:
      enabled: false

    controller:
      replicas: 1

    repoServer:
      replicas: 1

    applicationSet:
      replicas: 1
    YAML
  ]
}


resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = local.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_load_balancer_controller_pod_identity.arn

  # Make sure ServiceAccount exists before associating
  depends_on = [helm_release.aws_load_balancer_controller]
}
