data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

// VPC 정보를 통해 CIDR 블록을 조회 (api-server SG 인바운드에 사용)
data "aws_vpc" "this" {
  id = data.terraform_remote_state.basic.outputs.vpc_id
}
