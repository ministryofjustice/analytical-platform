<!-- markdownlint-disable -->
# Deleting a EKS Cluster

To delete a cluster defined by module eks you need to do a destroy, removing module from terraform and doing apply doesn't work.
- there is also a regression in terraform v0.14.x where a refresh is not implicitly done on a destroy which
causes the destroy of the eks module to fail
- terraform fails to delete resource  aws_eks_identity_provider_config.auth0 so this needs to be manually removed from the state first.
- In the future we should remove as many dependencies as possible so that the least number of resources need to be deleted.
So to destroy a cluster need to add the following to the github-actions workflow after terrraform validate: 
```
      - name: Terraform destroy cluster
        id: destroy_cluster
        run: |
          terraform state rm aws_eks_identity_provider_config.auth0[0]
          terraform refresh
          terraform destroy -target=module.eks -auto-approve -input=false
        working-directory: ${{ env.working-directory }}
        env:
          TF_VAR_assume_role: "github-actions-infrastructure"

```
then remove module eks from terraform code or run terraform apply to recreate eks cluster.

**NOTE:** The terraform refresh is fixed  on Terraform v0.15.0 or above should not be necessary however
there is still an issue outstanding to allow the cluster to be deleted via terraform apply  

If the destroy fails then terraform refresh will no longer fix problem and then you need to rm from the state
the resource it is failing on typically:
```
terraform state rm module.eks.kubernetes_config_map.aws_auth[0]
```

You may have to do multiple destroys:
```
terraform destroy -target=module.eks (fails on unauthorized
terraform destroy -target=module.eks (fails on unauthorized
terraform destroy -target=module.eks (fails on localhost refused)
terraform state rm module.my-cluster.kubernetes_config_map.aws_auth[0]
```

### References

[tf destroy fails to remove aws_auth: unauthorized #1162](https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1162)

[Destroy fails with Error: Unauthorized when removing kubernetes resources and access token is used. #27741](https://github.com/hashicorp/terraform/issues/27741)

[Error: Delete http://localhost/api/v1/namespaces/kube-system/configmaps/aws-auth: dial tcp 127.0.0.1:80: connect: connection refused #978](https://github.com/terraform-aws-modules/terraform-aws-eks/issues/978)

[terraform AWS EKS 'destroy' failed module.eks.kubernetes_config_map.aws_auth[0] Error: Unauthorized #1661](https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1661)

[Feat request: Destroy the EKS cluster with "terraform apply" instead of "terraform destroy" #1640](https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1640)