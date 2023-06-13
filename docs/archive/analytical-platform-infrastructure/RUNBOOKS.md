<!-- markdownlint-disable -->
# Kubernetes Alert Runbooks

[Playbooks (or runbooks)](https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q/edit#) are an important part of an alerting system; it's best to have an entry for each alert or family of alerts that catch a symptom, which can further explain what the alert means and how it might be addressed.

It is a recommended practice that you add an annotation of "runbook" to every prometheus alert with a link to a clear description of it's meaning and suggested remediation or mitigation. While some problems will require private and custom solutions, most common problems have common solutions. In practice, you'll want to automate many of the procedures (rather than leaving them in a wiki), but even a self-correcting problem should provide an explanation as to what happened and why to observers.

This page collects the alerts defined in the  [flux kubernetes definition for prometheus](https://github.com/moj-analytical-services/analytical-platform-flux/blob/main/clusters/development/prometheus/prometheus.yaml) and there is a link for each alert to this document. See [A Complete Guide to Monitoring Amazon EKS](https://epsagon.com/development/monitoring-amazon-eks/) for a background on the alert setup. 

**NOTE:** Alerts are only for webops managed resources. No alerts for any pods created by data scientists in namespaces prefixed user etc. 

# EKS-control-plane Alerts 

These are alerts from the EKS control plane and this is managed by AWS so we won’t have access to most of the components, like the API server, scheduler, control manager, etc., and you won’t know how they’re performing. But there are a few metrics exposed through the API server that can give you an idea as to how things are going. 

## KubernetesApiServerEtcdAccessLatency

### Description

Latency for apiserver to access etcd is higher than 1 sec

### Action 

If this happens repeatedly need to look at scaling up EKS or setting the service level to higher than 1 sec. 

## KubernetesApiServerLatency

### Description

ApiServer requests taking longer than 1 sec

### Action

If this happens repeatedly need to look at scaling up EKS or setting the service level to higher than 1 sec. 

## KubernetesWorkQueuesTimes

### Description

Duration for controller-manager workqueues is higher than 1 sec

### Action

If this happens repeatedly need to look at scaling up EKS or setting the service level to higher than 1 sec. 

## KubernetesControllerManagerAWSRequests

### Description

Duration for controller-manager AWS requests greater than 1 sec

### Action

If this happens repeatedly need to look at scaling up EKS or setting the service level to higher than 1 sec. 

# cluster-state-node Alerts

Cluster state metrics provide information on the state of various objects in Kubernetes. The most important objects to monitor for the performance of clusters are pods and nodes, as they give an almost complete picture of a production environment’s performance.

The most popular tool to get these metrics is kube-state-metrics, a service from Kubernetes that gives you data on objects by listening to API servers. 



## KubernetesNodeNotReady

### Description

xxxxxxx Nodes are in NotReady status for more than an hour

### Action 

if this occurs outside of upgrading nodes during a kubernetes upgrade need to investigate the setup of the node. Describe the nodes in kubectl or lens. then ssh into the node and look for certificate errors, authentication errors etc. 


## KubernetesNodeUnschedulable

### Description

xxxxxxx nodes are Unschedulable for more than an 5 mins

### Action 

This prevents pods being scheduled on the node. Describe the nodes in kubectl or lens. Try to determine why it is unschedulable.

## KubernetesNodeDaemonsetUnavailable

### Description

xxxxxxxxxx nodes are unable to run Non-user pods for more than an 5 mins

### Action 

This prevents pods being run on the node. Describe the nodes in kubectl or lens. Try to determine why it is unavailable.


# cluster-state-deployment Alerts

Cluster state deployment metrics alerts. 

## KubernetesPodMaxUnavailableDeployment

### Description

Maximum number of unavailable pods during a Non-user rolling update for more than an 5 mins

### Action 

in kubectl or lens look at events, and logs for the pods failing to determine reason for failure.


## KubernetesPodUnavailableDeployment

### Description

Pods unavailable for a Non-user deployment for more than an 5 mins

### Action 

in kubectl or lens look at events, and logs for the pods failing to determine reason for failure.


# cluster-state-pod Alerts

Cluster state metrics for pods alerts. 

## KubernetesPodNotReady

### Description

Non-user Pod status is NotReady for more than an 5 mins

### Action 

in kubectl or lens look at events, and logs for the pods failing to determine reason for failure.

## KubernetesPodFailures

### Description

Non-user Pods have more than 500 failures for more than an hour

### Action 

in kubectl or lens look at events, and logs for the pods failing to determine reason for failure.

# past-issues Alerts

These are past issues we have had and we want to be alerted if they happen again. 

## KubernetesEtcObjectsTooMany

### Description

Number of objects in EKS Cluster greater than 31000

### Action 

in kubectl or lens look at events, and logs and see what is creating the large number of kubernetes objects. 