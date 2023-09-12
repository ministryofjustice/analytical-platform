##################################################
# General
##################################################

account_ids = {
  analytical-platform-data-production       = "593291632749"
  analytical-platform-development           = "525294151996"
  analytical-platform-management-production = "042130406152"
}

tags = {
  business-unit          = "Platforms"
  application            = "Data Platform"
  component              = "Airflow"
  environment            = "production"
  is-production          = "true"
  owner                  = "data-platform:data-platform-tech@digital.justice.gov.uk"
  infrastructure-support = "data-platform:data-platform-tech@digital.justice.gov.uk"
  source-code            = "github.com/ministryofjustice/data-platform/terraform/aws/analytical-platform-data-production/airflow"
}

##################################################
# Network
##################################################

noms_live_dead_end_cidr_block     = "10.40.0.0/18"
laa_prod_cidr_block               = "10.205.0.0/20"
modernisation_platform_cidr_block = "10.26.0.0/15"
azs                               = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

dev_vpc_cidr_block       = "10.200.0.0/16"
dev_private_subnet_cidrs = ["10.200.20.0/24", "10.200.21.0/24", "10.200.22.0/24"]
dev_public_subnet_cidrs  = ["10.200.10.0/24", "10.200.11.0/24", "10.200.12.0/24"]

prod_vpc_cidr_block       = "10.201.0.0/16"
prod_private_subnet_cidrs = ["10.201.20.0/24", "10.201.21.0/24", "10.201.22.0/24"]
prod_public_subnet_cidrs  = ["10.201.10.0/24", "10.201.11.0/24", "10.201.12.0/24"]

transit_gateway_ids = {
  "airflow-cloud-platform" = "tgw-009e14703041026a5"
  "airflow-moj"            = "tgw-0e7b982ea47c28fba"
}

prod_vpc_sg_name = "airflow-prod"

##################################################
# EKS Cluster
##################################################

dev_eks_role_arn    = "arn:aws:iam::593291632749:role/airflow-dev-eksRole-role-211908c"
dev_cluster_sg_name = "airflow-dev-eksClusterSecurityGroup-6a4dde4"
dev_node_sg_id      = "sg-01930457ae391c7f0"

prod_eks_role_arn    = "arn:aws:iam::593291632749:role/airflow-prod-eksRole-role-de6b4f5"
prod_cluster_sg_name = "airflow-prod-eksClusterSecurityGroup-6ab84a6"
prod_node_sg_id      = "sg-0f73e78564012634a"

node_group_instance_types = {
  standard    = ["t3a.large", "t3.large", "t2.large"]
  high-memory = ["r6i.8xlarge"] # up from r6i.4xlarge to r6i.8xlarge
}
