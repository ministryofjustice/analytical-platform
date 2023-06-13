module "ecr" {
  for_each = local.repositories

  source = "./modules/ecr"

  name      = each.key
  push_arns = each.value["allowed_push_arns"]
  pull_arns = each.value["allowed_pull_arns"]
}
