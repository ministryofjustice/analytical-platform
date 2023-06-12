rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

/*
  terraform_required_providers has been disabled so that child modules can inherit the providers from their parent.
  Also, when parent and child both specified versions, Dependabot would raise PR to update both parent and child modules, and they would conflict
*/
rule "terraform_required_providers" {
  enabled = false
}
