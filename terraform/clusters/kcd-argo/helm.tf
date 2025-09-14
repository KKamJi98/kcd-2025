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
  wait             = true
  timeout          = 600
  atomic           = true

  set = [
    {
      name  = "clusterName"
      value = local.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
    }
  ]

  # Ensure cluster is available before Helm install
  depends_on = [
    module.eks,
    kubernetes_service_account.aws_load_balancer_controller,
    aws_eks_pod_identity_association.aws_load_balancer_controller,
    aws_iam_role_policy_attachment.aws_load_balancer_controller_policy_attach
  ]
}

###############################################
# Argo CD via Helm (kcd-argo)
###############################################

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.3.7"
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 600
  atomic           = true

  values = [<<-YAML
    global:
      domain: kcd-argo.kkamji.net

    certificate:
      enabled: true

    server:
      replicas: 1
      ingress:
        enabled: true
        ingressClassName: alb
        hostname: kcd-argo.kkamji.net
        tls: true
        annotations:
          alb.ingress.kubernetes.io/scheme: internet-facing
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
          alb.ingress.kubernetes.io/ssl-redirect: '443'
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

  depends_on = [
    module.eks,
    helm_release.aws_load_balancer_controller
  ]
}
