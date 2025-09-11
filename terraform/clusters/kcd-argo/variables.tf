variable "region" {
  description = "AWS region for this cluster"
  type        = string
  default     = "ap-northeast-2"
}

variable "access_entries" {
  description = "EKS cluster access entries map"
  type = map(object({
    kubernetes_groups = optional(list(string))
    principal_arn     = string
    type              = optional(string, "STANDARD")
    user_name         = optional(string)
    tags              = optional(map(string), {})
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        namespaces = optional(list(string))
        type       = string
      })
    })), {})
  }))
  default = {}
}

variable "domain_name" {
  description = "Route53 hosted zone root domain (without wildcard)."
  type        = string
  default     = "kkamji.net"
}
