terraform {
  cloud {
    organization = "kkamji-lab"

    workspaces {
      name = "kcd-east"
    }
  }
}

