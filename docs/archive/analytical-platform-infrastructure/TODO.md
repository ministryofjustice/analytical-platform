<!-- markdownlint-disable -->
# TODO

This file lists the number of improvements we wish to see in the future of this repository. Or things we know we've done wrong for now, until we can find a better way of doing it:

## Bootstrapping Flux

We currently bootstrap our EKS cluster with Flux using the flux terraform provider. This works but has a couple of downsides.

- The flux provider can't easily work out which resources are already created. Therefore to avoid terraform plans showing that changes are requried to the flux configuration each time, we have added `ignore changes = all` to the resource that applies the flux configuration.

[https://toolkit.fluxcd.io/guides/installation/#bootstrap-with-terraform](https://toolkit.fluxcd.io/guides/installation/#bootstrap-with-terraform)

- The secret that contains the ssh-key that flux uses to sync with the repository has been created manually. Once we have a way of adding secrets e.g. https://github.com/external-secrets/kubernetes-external-secrets then we can automate the creation of the the secret.

