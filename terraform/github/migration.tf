resource "null_resource" "migrate_repo_content" {
  depends_on = [module.data-platform-apps]
  for_each   = { for repo in local.ap_migration_apps : repo.name => repo }

  triggers = {
    github_repository = module.data-platform-apps[each.value.name].repository.name
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<EOF
  mkdir ${path.module}/tmp_migration \
   && cd ${path.module}/tmp_migration
   && chmod +x "${path.module}/scripts/repo-content-migration/repo-migration.sh" \
   && "${path.module}/scripts/repo-content-migration/repo-migration.sh" \
   -s ${each.value.source_repo_name} \
   -t ${module.data-platform-apps[each.value.name].repository.name} \
   && rm -rf ${path.module}/tmp_migration
  EOF
  }
}
