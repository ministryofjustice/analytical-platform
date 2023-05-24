provider "aws" {
  alias  = "session-info"
  region = "eu-west-2"
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.whoami.issuer_arn)) ? null : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GlobalGitHubActionAdmin"
  }
}


provider "aws" {
  region = "eu-west-1"
  alias  = "landing"
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts["landing"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "dev"
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts["dev"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "prod"
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts["prod"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "data_engineering"
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts["data_engineering"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "sandbox"
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts["sandbox"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "dev_data"
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts["dev_data"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  region = "eu-west-2"
  alias  = "mi_dev"
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts["mi_dev"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  alias  = "data"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts["data"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  alias  = "management"
  region = "eu-west-1"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.whoami.issuer_arn)) ? null : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GlobalGitHubActionAdmin"
  }
}