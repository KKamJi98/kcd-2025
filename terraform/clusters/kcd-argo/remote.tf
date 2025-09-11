data "terraform_remote_state" "basic" {
  backend = "remote"
  config = {
    organization = "kkamji-lab"
    workspaces = {
      name = "basic"
    }
  }
}

data "terraform_remote_state" "acm" {
  backend = "remote"
  config = {
    organization = "kkamji-lab"
    workspaces = {
      name = "kcd-acm"
    }
  }
}
