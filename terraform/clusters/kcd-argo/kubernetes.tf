###############################################
# Precreate ServiceAccounts (kcd-argo)
###############################################

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }

  depends_on = [module.eks]
}

