locals {
  /* MPE SIMULATION */
  application_name = "analytical-platform"
  environment      = "development"
  component        = "next-gen-network"
  /* END MPE SIMULATION */

  /* SUBNETS */
  all_subnets = merge([
    for subnet_type, azs in local.environment_configuration.vpc_subnets : {
      for az, config in azs :
      "${subnet_type}-${az}" => merge(config, {
        type = subnet_type
        az   = az
      })
    }
  ]...)
  /* END SUBNETS */
}
