terraform {
  cloud {
    organization = "kkamji-lab"

    workspaces {
      name = "kcd-argo"
    }
  }
}

