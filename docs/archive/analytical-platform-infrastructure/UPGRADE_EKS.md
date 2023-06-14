<!-- markdownlint-disable -->
# Upgrade EKS

## Overview 

This documents the process to upgrade EKS version of the management, dev and prod clusters in the infrastructure directory in the repo. 

## Prerequisites

### Setup Self-Hosted Runner on Dev EKS Cluster

Terraform runs on self-hosted in the github-actions-moj (management) EKS cluster therefore it not possible to do an upgrade to the management cluster as it replaces the worker nodes which ultimately run the runners. To overcome this 
- enable a self-hosted runner in the dev cluster by going to the `analytical-platform-flux` repo uncomment the  `cluster/development/actions-runner-controller` and push and apply this change with flux.  
- update the `.github/workflows/github-actions-moj.yml` changing `runs-on: [self-hosted, management-infrastructure]` to `runs-on: [self-hosted, development-infrastructure]` so changes to the github-actions-moj (management) EKS cluster will now run on the runner in the dev cluster. 
- finally when upgrading clusters do it one cluster at a time so comment out the `on` portion of the workflows for all the cluster(s) tht are not being updated.
``` 
"on":
  pull_request:
    paths: ["infrastructure/**"]
  push:
    branches: [main]
    paths: ["infrastructure/**"]
```

### Read Docs for Breaking Changes 

[https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html)

[https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)

### Process

1. Update the [Terraform EKS module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) to latest version and check that EKS cluster is unchanged after updating terraform.

2. For each cluster comment out the the github workflows for the other clusters, update the local.account.cluster_version value for the cluster and push and run workflow. 
   - **NOTE:** I was getting error `InvalidParameterException: Encryption is already enabled on the cluster` after updating the cluster which meant it didn't go on to upgrade the worker nodes so had to run the workflow again manually from the github web page to get worker nodes upgraded

3. Check in Lens that all the pods are now running in the new working nodes.
   - **NOTE:** Its possible to get volume affinity errors on pods that have Persistent Volume Claims to EBS disks if they come up on a node in a different availability zone. 

4. Finally upgrade core deployments and daemon sets that are recommended for EKS version in  the `analytical-platform-flux` repo. For EKS 1.20 following changes required:  
   - Calico 0.3.4 - no change
   - Aws-vpc-cni 1.1.0 to 1.1.7
   - Cluster-autoscaler 9.4.0 to 9.9.2
   - Coredns 1.8.0 to 1.8.3 
   - kube-proxy  1.19.6 to 1.20.4 
   - Registry-creds 0.2.6 to 0.2.7  





## References 

[https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-19-to-1-20-78c9a7edddb5](https://marcincuber.medium.com/amazon-eks-upgrade-journey-from-1-19-to-1-20-78c9a7edddb5)

