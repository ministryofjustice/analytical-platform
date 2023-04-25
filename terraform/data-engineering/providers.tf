provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.whoami.issuer_arn)) ? null : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GlobalGitHubActionAdmin"
  }

}

provider "aws" {
  alias  = "data-engineering"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::189157455002:role/GlobalGitHubActionAdmin"
  }

}

provider "aws" {
  alias  = "session-info"
  region = "eu-west-2"
}
