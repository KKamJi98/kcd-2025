output "acm_certificate_arn" {
  description = "ACM certificate ARN for wildcard domain"
  value       = aws_acm_certificate.wildcard.arn
}
