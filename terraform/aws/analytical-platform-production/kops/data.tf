##################################################
# AWS
##################################################

data "aws_caller_identity" "current" {}

data "aws_iam_policy" "access_mojap_non_sensitive_files_for_docker_builds" {
  name = "access-mojap-non-sensitive-files-for-docker-builds"
}

data "aws_iam_policy" "alpha_cluster_autoscaler" {
  name = "alpha-cluster-autoscaler"
}

data "aws_iam_policy" "dev_cluster_autoscaler" {
  name = "dev-cluster-autoscaler"
}

data "aws_route53_zone" "alpha_mojanalytics_xyz" {
  name = "alpha.mojanalytics.xyz"
}

data "aws_route53_zone" "dev_mojanalytics_xyz" {
  name = "dev.mojanalytics.xyz"
}
