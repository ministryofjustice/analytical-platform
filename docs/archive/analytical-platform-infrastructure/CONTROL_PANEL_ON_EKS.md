<!-- markdownlint-disable -->
# Control Panel on EKS

The Control Panel on EKS differs in a few areas from the legacy KOPS based cluster.

- [Kubernetes RBAC Permissions and Roles](## Kubernetes RBAC Permissions and Roles)

- [New user process](## New user process)


- [OIDC](## OIDC)



## Kubernetes RBAC Permissions and Roles 

As the Control Panel on EKS uses Helm 3 it requires a more powerful set of Kubernetes RBAC permissions.

### ClusterRoles

We create a set of ClusterRoles for the Control Panel using flux.

`secrets-read-write` - This role grants permission to read, write and delete secrets. It is required so that the Control panel can query, deploy and delete helm releases.

`cpanel-bootstrap`- This role grants permissions to create namespaces and persistent volumes and to create a new role binding to the `cpanel-deploy` role.

`cpanel-deploy` - This role grants permissions to read, write and delete most kubernetes resource types (e.g. deployments, services, network policies etc.). 

### ClusterRoleBindings

We then create ClusterRoleBindings between the `cpanel-frontend` and `cpanel-worker` service accounts and the `secrets-read-write` `cpanel-bootstrap` ClusterRoles with flux.

These grant the Control Panel service accounts the permissions in these roles for all namespaces.


### RoleBindings

The `bootstrap-user` helm chart creates a RoleBinding between the `cpanel-frontend` and `cpanel-worker` service accounts and the `cpanel-deploy` Cluster Role in a user's namespace.

This grants the Control Panel service accounts the permissions in the `cpanel-deploy` ClusterRole for a specific user's namespace. This allows the control panel to list, deploy and delete helm charts in user namespaces.

## New user process

When a new Analytical Platform user logs into the Control panel.

- The user is prompted to login with their Github user ID and password and then to enter their MFA code.

- Auth0 checks to see if they are a member of the `moj-analytical-services` github organisation and that they have MFA enabled on their Github account.

If these checks are successful then Auth0 passes an authentication token to the Control Panel.

The Control Panel checks to see if the user already exists in the Control Panel database, if they don't then it will do the following.

- An entry for the user in the Control Panel database is created.

- An IAM role is created for the user in the data AWS account.

- The` bootstrap-user` helm chart is deployed. This creates the user's namespace and a RoleBinding between the Kubernetes service accounts that the Control Panel uses and the `cpanel-deploy` ClusterRole in the user's namespace.

- The `provision-user` helm chart is then deployed. This creates a Persistent Volume, a Persistent Volume Claim, a set of Jobs that configure git on the Persistent Volume claim, a set of Network policies for the user namespace, a secret containing details about the user and a RoleBinding to allow the user to access objects in their namespace from the Control Panel (via OIDC).

## OIDC

The Control Panel uses OIDC to authenticate with EKS and obtain Kubernetes permissions for an user.

In order to be able to do this we have to configure an OIDC identity provider on the EKS cluster.

See AWS documentation on [using OIDC identity providers with EKS](https://docs.amazonaws.cn/en_us/eks/latest/userguide/authenticate-oidc-identity-provider.html)

We configure the OIDC identity provider using terraform in the [https://github.com/ministryofjustice/analytics-platform-infrastructure](https://github.com/ministryofjustice/analytics-platform-infrastructure) repo.

We have to specify the following details

- `Issuer URL` - This is the Auth0 domain e.g. `https://alpha-analytics-moj.eu.auth0.com/`

- `Client ID` - This the Client ID of the Auth0 application the control panel uses.

- `Username claim` - This configures which field in the authentication token should be used for the user name. It should be set to `nickname`

- `Groups claim` - This configures which field in the authentication token should be used for the group membership. It should be set to `https://api.alpha.mojanalytics.xyz/claims/groups` or `https://api.dev.mojanalytics.xyz/claims/groups`


The `provision-user` helm chart creates a RoleBinding to the user that is authenticated by OIDC.

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: user-soundwave
  namespace: user-soundwave
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin # Does not allow user to modify resource quotas or the namespace itself
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: https://alpha-analytics-moj.eu.auth0.com/#soundwave
``` 









 