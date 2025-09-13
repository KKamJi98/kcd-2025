###############################################
# Pod Identity Associations (kcd-west)
###############################################

resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = local.cluster_name
  namespace       = "kube-system"
  service_account = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  role_arn        = aws_iam_role.aws_load_balancer_controller_pod_identity.arn

  # Ensure ServiceAccount exists before associating
  depends_on = [kubernetes_service_account.aws_load_balancer_controller]
}
