###############################################
# AWS Load Balancer Controller via Helm (kcd-west)
###############################################

resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.13.0"
  namespace        = "kube-system"
  create_namespace = false

  # Ensure cluster is available before Helm install
  depends_on = [
    module.eks,
    kubernetes_service_account.aws_load_balancer_controller,
    aws_eks_pod_identity_association.aws_load_balancer_controller
  ]

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
      value = "aws-load-balancer-controller"
    }
  ]
}

resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = local.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_load_balancer_controller_pod_identity.arn

  # Make sure ServiceAccount exists before associating
  depends_on = [kubernetes_service_account.aws_load_balancer_controller]
}
