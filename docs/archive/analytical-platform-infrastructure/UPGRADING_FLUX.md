<!-- markdownlint-disable -->
# Flux Bootstrap

Flux is bootstrapped by terraform so all other kubernetes services are created using flux in a separate repository. See files flux.tf, irsa.tf

## Flux version locked 

The flux version is locked in flux.tf, and the flux terraform provider version is locked in versions.tf as upgrading flux can will break the cluster as the api signature changes for the Kustomization custom resources when flux version is greater than 0.16.2 and the flux provider version is greate than 0.3.1. 

Also the flux provider creates resources for the terraform kubernetes provider which can fail silently hence resources may only be partially applied and a second run of terraform is required to complete the upgrade. 

**WARNING 1**: If the Kustomization custom resource gets destroyed while flux is active in the cluster it will remove all resources the next time it reconciles as there is no longer a Kustomization for those resources. 

**WARNING 2**: The terraform ignore changes lifecycle clause does not protect from destroying and recreating resources. Hence if terraform determines that the Kustomisation resources has changed API signature it will attempt destroy and recreate the resources which can cause a reconciliation to fail if it runs when no Kustomisation resource is defined. 

## Flux upgrade process

First test on the development branch obviously. 

To update flux:
- Using lens or kubectl scale the deployments to zero for all deployments in the flux-system namespace. 
- update the version of the flux provider in versions.tf to latest version
```
    flux = {
      source  = "fluxcd/flux"
      version = "0.3.1"
    }
``` 
- update flux.tf update the desired flux version and comment out lifecycle ignore changes blocks.
```
    data "flux_install" "main" {
      target_path = local.flux_target_path
      version = "v0.16.2"
    }
```     
```
# lifecycle {
#  ignore_changes = all
# }
```
- when finished reinstate the lifecycle ignore changes blocks.