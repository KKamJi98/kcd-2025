###############################################
# AWS Load Balancer Controller via Helm (kcd-east)
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
    aws_eks_pod_identity_association.aws_load_balancer_controller
  ]
}
