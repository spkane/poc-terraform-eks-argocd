data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../../network/terraform.tfstate"
  }
}