<!-- markdownlint-disable -->
# Analytical Platform Infrastructure Monitoring

## Overview 

```
┌────────────────────────────────────┐
│EKS Cluster                         │
│                                    │
│  ┌──────────────┐                  |
│  |Grafana       ├──────────────────┼────────► User
│  │              │                  |
│  └─────────────-┘                  |
│                                    |
│  ┌──────────────┐                  |
│  │Prometheus    │                  |
│  │Server        |                  |
│  │              │                  │
│  └──────────────┘                  │        
│                                    │
│  ┌──────────────┐                  │        ┌───────────────┐
│  │Alert         │                  │        |Pagerduty      │
│  │Manager       ├──────────────────┼────────►               |
│  │              │                  │        │               │
│  └──────────────┘                  │        └───────────────┘
│                                    │
└────────────────────────────────────┘
```

There is a requirement to monitor the Analytical Platform EKS clusters and have alerts that go to Pagerduty that can be acted on.
Metrics can be grouped into:
- Control Plane Metrics: although these are managed by AWS. 
- Cluster State Metrics: information on the state of various objects in Kubernetes provided by kube-state-metrics.
- Resource Metrics: CPU, memory, and other resource utilization for Pods, Nodes, Volumes etc.  

## Architecture
>Currently (April 2022) team is working on new Architecture to monitor AWS EKS clusters and other resources (diagram above).
>Part of this work is to remove AWS Managed Prometheus and Grafana and use services running inside each cluster.
>Below is description of current setup.

Each cluster will have a kubernetes prometheus service.
Currently managed prometheus is just a storage solution and doesn't support alerts so a kubernetes prometheus alert manager is also run in the cluster. 

Separate AWS managed prometheus are setup for each cluster in the AWS Management account to keep metrics separate for each cluster. This allows Grafana dashboards to have separate information for each cluster. Pricing of managed prometheus is by data usage no more expensive than one large managed prometheus.   

A single AWS managed grafana in the AWS management account is used for dashboards and can be used over multiple prometheus data sources. Grafana pricing is by number of users accessing each month so cheaper to have only one grafana dashboard and makes it easier to use as don't have to switch between managed grafanas to look at data from different EKS clusters.  
Some public dashboards only allow one prometheus data source to be configured at install time so we need multiple copies of these dashboards in grafana configured for each of the managed prometheus data sources. 

Public dashboards from [Grafana Official and community built dashboards](https://grafana.com/grafana/dashboards) or the 
[Kubernetes Monitoring github repository](https://github.com/kubernetes-monitoring/kubernetes-mixin) will be used whenever possible. 

NOTE: Dashboards in the Kubernetes Monitoring github repository are in jsonnet format and have to be converted to json below importing into grafana. See [Kubernetes Monitoring github repository](https://github.com/kubernetes-monitoring/kubernetes-mixin). These all support specifying multiple prometheus data sources. 

Also public alerts can be found at [github kubernetes-monitoring/kubernetes-mixin/alerts](https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/alerts) and accessed directly in the alerting rules configuration.

## Cross Account IAM Roles

 All the AWS managed prometheus are in the AWS management account and have cross account IAM roles for ingestion as per [Setting up cross-account ingestion into Amazon Managed Service for Prometheus](https://aws.amazon.com/blogs/opensource/setting-up-cross-account-ingestion-into-amazon-managed-service-for-prometheus/).  


## Install

### Managed Prometheus 

A managed prometheus workspace is setup for each EKS cluster in the AWS Management account by terraform in the infrastructure directory. 

### Managed Grafana 

Currently there is no support for managed grafana in terraform so a managed grafana workspace manually created in the AWS management account using the AWS console and user access created for webops engineers. 

The managed grafana has folders 
- kubernetes: dashboards that support multiple prometheus datasources
- management: dashboard configured for management prometheus datasource 
- development: dashboard configured for development prometheus datasource
- prod: dashboard configured for prod prometheus datasource

### Prometheus services inside EKS cluster

These are install using flux and configured in the flux repository.
 
## 1. Control Plane Metrics

Although this is managed by AWS its possible to get an idea of the load on the EKS Cluster. 

### Metrics

Metrics from the control plane come from these 3 services. 

#### API server

apiserver_request_latencies_sum gives you visibility into how much time a request is taking to be processed by the API server.

#### etcd cluster

 etcd_request_latencies_summary_sum shows latency-related data observed by the etcd.

 #### Controller Manager

 rest_client_request_latency_microseconds_sum tells you how much latency is observed by the controller manager.

### Grafana Dashboards

[Kubernetes apiserver(12006)](https://grafana.com/grafana/dashboards/12006) - AWS recommends this dashboard for API server.

[Etcd By Prometheus(3070)](https://grafana.com/grafana/dashboards/3070) - popular etcd dashboard but this shows little data currently.
NOTE: Cannot specify multiple prometheus workspaces.  

### Alerts

Create an alert group for Control Plane with alerts for:
- apiserver
- etcd 
- controller

## 2. Cluster State Metrics

Information on the state of various objects in Kubernetes provided by kube-state-metrics.

### Metrics 

These kube state metrics are recommended 

Component |	Metrics Name |	Description
--------- | ------------ | -------------
| Node	  | kube_node_status_condition |	The status of several node conditions; value would be true/false/unknown
|     | kube_node_spec_unschedulable |	Whether a node is ready to schedule new pods or not
| Deployment | kube_deployment_status_replicas |	How many pods are running in the deployment
|           | kube_deployment_spec_replicas |	How many pods are configured as desired for a deployment
|           | kube_deployment_status_replicas_available |	How many pods are available for a deployment
|           | kube_deployment_status_replicas_unavailable |	Pod status, if they are down and cannot be used for a deployment
|           | kube_deployment_spec_strategy_rollingupdate_max_unavailable |	Maximum number of unavailable pods during a rolling update of a deployment
| Pod	       | kube_pod_status_ready |	If a pod is ready to serve client requests
|           | kube_pod_status_phase |	Current status of the pod; value would be pending/running/succeeded/failed/unknown
|           | kube_pod_container_status_waiting_reason |	Reason a container is in a waiting state
|           | kube_pod_container_status_terminated |	Whether the container is currently in a terminated state or not

### Grafana Dashboards

[Kubernetes Cluster (prometheus) (6417)](https://grafana.com/grafana/dashboards/6417) - popular dashboard giving overall metrics on Cluster Health, Deployments, Nodes, Pods, Containers, Jobs.
NOTE: Cannot specify multiple prometheus workspaces.  

[Kubernetes cluster monitoring (via Prometheus)](https://grafana.com/grafana/dashboards/315) - another popular dashboard. 
NOTE: Cannot specify multiple prometheus workspaces.

### Alerts

Create an alert group for kube-state alerts for above metrics plus there are some existing alerts for kube dns etc already defined that can be reviewed.   

## 3. Resource Metrics

CPU, memory, and other resource utilization for Pods, Nodes, Volumes etc. 

### Metrics

Recommended metrics 

| Component | Metrics Name | Description
| --------- | ------------ | -----------
| Pod |	kube_pod_container_resource_requests |	Number of requested resources by a container; e.g., the sum of memory ||||| | resources requested by a namespace and a pod in a particular node
| |kube_pod_container_resource_limits |	Limit requested for each resource of a container
| Node |	kube_node_status_capacity |	Capacity of each resource in the node with the unit quantity, e.g., pod-5
| | kube_node_status_allocatable |	Number of different allocatable resources of a node that are available for scheduling

### Grafana Dashboards

[Kubernetes / Persistence Volumes](https://github.com/kubernetes-monitoring/kubernetes-mixin/blob/master/dashboards/persistentvolumesusage.libsonnet) - shows disk and inode usage. Will be interesting to see if it shows Elastic File System.  

[Flux Cluster Stats](https://github.com/fluxcd/flux2/tree/main/manifests/monitoring/grafana/dashboards)  - Show Flux deployment errors, each flux deployment and timings.  
NOTE: Cannot specify multiple prometheus workspaces.   

[CoreDNS](https://grafana.com/grafana/dashboards/5926) - Shows CoreDNS request and response metrics.
NOTE: Cannot specify multiple prometheus workspaces.  

[Kubernetes App Metrics](https://grafana.com/grafana/dashboards/1471) CPU, Disk, Memory etc by application. 
NOTE: Cannot specify multiple prometheus workspaces.

### Alerts

Create an alert group for resource alerts for above metrics plus there are some existing alerts for kube dns etc already defined that can be reviewed. 

## 4. CloudWatch Container Insights Monitoring

[Container Insights on Amazon EKS and Kubernetes](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/deploy-container-insights-EKS.html) automates the discovery of Prometheus metrics from containerized systems and workloads. Ingest custom metrics in CloudWatch, includes pre-built dashboards.

Confusingly there are several ways to setup this. Setting it up as a daemonset that runs on each node seems to be the way to get the performance information required. 
Setup by following [Set up the CloudWatch agent to collect cluster metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html)


# References

[https://epsagon.com/development/monitoring-amazon-eks/](https://epsagon.com/development/monitoring-amazon-eks/)

[https://www.stackrox.com/post/2020/04/aws-eks-monitoring-best-practices-for-stability-and-security/](https://www.stackrox.com/post/2020/04/aws-eks-monitoring-best-practices-for-stability-and-security/)

[https://aws.github.io/aws-eks-best-practices/reliability/docs/](https://aws.github.io/aws-eks-best-practices/reliability/docs/)

[https://aws.github.io/aws-eks-best-practices/reliability/docs/controlplane/](https://aws.github.io/aws-eks-best-practices/reliability/docs/controlplane/)


[https://www.datadoghq.com/blog/eks-cluster-metrics/](https://www.datadoghq.com/blog/eks-cluster-metrics/)

[https://www.datadoghq.com/blog/collecting-eks-cluster-metrics/](https://www.datadoghq.com/blog/collecting-eks-cluster-metrics/)

[https://www.replex.io/blog/kubernetes-in-production-the-ultimate-guide-to-monitoring-resource-metrics-with-grafana](https://www.replex.io/blog/kubernetes-in-production-the-ultimate-guide-to-monitoring-resource-metrics-with-grafana)

[https://povilasv.me/grafana-dashboards-for-kubernetes-administrators/](https://povilasv.me/grafana-dashboards-for-kubernetes-administrators/)

[https://aws.amazon.com/blogs/opensource/setting-up-cross-account-ingestion-into-amazon-managed-service-for-prometheus/](https://aws.amazon.com/blogs/opensource/setting-up-cross-account-ingestion-into-amazon-managed-service-for-prometheus/)

[https://fluxcd.io/docs/guides/monitoring/](https://fluxcd.io/docs/guides/monitoring/)