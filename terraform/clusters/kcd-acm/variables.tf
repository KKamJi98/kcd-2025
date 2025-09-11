variable "region" {
  description = "AWS region for ACM certificate"
  type        = string
  default     = "ap-northeast-2"
}

variable "domain_name" {
  description = "Route53 hosted zone root domain (without wildcard)"
  type        = string
  default     = "kkamji.net"
}

