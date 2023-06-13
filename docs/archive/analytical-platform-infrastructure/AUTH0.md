<!-- markdownlint-disable -->
# Auth0 configuration

## Auth0 terraform provider

The 'Auth0 terraform provider' application manages client creation for infrastructure via terraform.

It is manually created in Auth0, not via infrastructure code, to prevent cycle dependency during code deployment.

It needs to be **machine to machine** app type, be **oidc_conformant** and use **RS256** as the JWT signing algorithm.

Callback and logout URL's do not need to be set for this application

It needs to be authorised in the Auth0 Management API

    DEV   - API Identifier - https://dev-analytics-moj.eu.auth0.com/api/v2/
    PROD  - API Identifier - https://alpha-analytics-moj.eu.auth0.com/api/v2/


And granted these permissions

    read:clients
    update:clients
    delete:clients
    create:clients

The **client_id** and **secret** are then stored in AWS Secrets Manager

    DEV   -   /development/auth0-terraform/auth0-creds
    PROD  -   /production/auth0-terraform/auth0-creds

## Analytical Tools

### Auth0 Application

Each of the Analytical Tools have an Application in Auth0.

These are created using the Auth0 terraform provider.

They need to be a **regular_web** app type, be **oidc_conformant** and use **RS256** as the JWT signing algorithm.

You also need to set the callback and logout urls that will be used with this application.

Example terrafom for an Auth0 application

```
resource "auth0_client" "jupyter-lab" {
  name                = "Jupyter Lab EKS"
  description         = "Auth0 Client used by Jupyter Lab on EKS"
  app_type            = "regular_web"
  callbacks           = ["https://*-jupyter-lab.tools.${local.account.zone}/callback"]
  allowed_logout_urls = ["https://*-jupyter-lab.tools.${local.account.zone}"]
  oidc_conformant     = true
  jwt_configuration {
    alg = "RS256"
  }
}


```

Once the applications have been created in Auth0 you need to enable the `github` connection for each.

- In the Auth0 Management Console [https://manage.auth0.com/](https://manage.auth0.com/), select the tenant that you want to configure the Application in.

- Select **Applications** - **Applications**

- Select the one of the application you created for the Analytical tools.

- Enable the **Github** connection (under the **Connections** tab) and ensure all other connections are disabled.

- Repeat for the other Auth0 applications you have created.

## Control Panel

### Auth0 Application

The Control panel has an Application in Auth0. These are created using the Auth0 terraform provider.

Once the application has been created in Auth0 you need to enable the `github` connection for each.

- In the Auth0 Management Console [https://manage.auth0.com/](https://manage.auth0.com/), select the tenant that you want to configure the Application in.

- Select the application you created for the Control panel.

- Enable the **Github** and **oidc-client** connections (under the **Connections** tab) and ensure all other connections are disabled.

### Auth0 Management API

The Auth0 application that you created for Control Panel needs to be given permissions to the **Auth0 Management API** so that it can manage Auth0 permissions.

- In the Auth0 Management Console [https://manage.auth0.com/](https://manage.auth0.com/), select the tenant that you want to create the Application in.

- Select **Applications** - **API**

- Select **Auth0 Management API**

- Select **Machine to Machine Applications**

- Authorise the Auth0 application used by the Control panel

- Enable the following permissions for the Auth0 application

```
read:client_grants
create:client_grants
delete:client_grants
update:client_grants
read:users
update:users
delete:users
create:users
read:users_app_metadata
update:users_app_metadata
delete:users_app_metadata
create:users_app_metadata


create:user_tickets
read:clients
update:clients
delete:clients
create:clients
read:client_keys
update:client_keys
delete:client_keys
create:client_keys
read:connections
update:connections
delete:connections
create:connections
read:resource_servers
update:resource_servers
delete:resource_servers
create:resource_servers
read:device_credentials
update:device_credentials
delete:device_credentials
create:device_credentials
read:rules
update:rules
delete:rules
create:rules
read:rules_configs
update:rules_configs
delete:rules_configs


read:email_provider
update:email_provider
delete:email_provider
create:email_provider
blacklist:tokens
read:stats

read:tenant_settings
update:tenant_settings
read:logs
read:shields
create:shields
update:triggers
read:triggers
read:grants
delete:grants
read:guardian_factors
update:guardian_factors
read:guardian_enrollments
delete:guardian_enrollments
create:guardian_enrollment_tickets
read:user_idp_tokens
create:passwords_checking_job
delete:passwords_checking_job
read:custom_domains
delete:custom_domains
create:custom_domains
read:email_templates
create:email_templates
update:email_templates

```

### Auth0 Authorisation Extension API

The Auth0 application that you created for Control Panel needs to be given permissions to the **Auth0 Authorisation Extension API** so that it can manage Auth0 permissions.

- In the Auth0 Management Console [https://manage.auth0.com/](https://manage.auth0.com/), select the tenant that you want to create the Application in.

- Select **Applications** - **API**

- Select **auth0-authorization-extension-api**

- Select **Machine to Machine Applications**

- Authorise the Auth0 application used by the Control panel

- Enable the following permissions for the Auth0 application

```
read:users
read:groups
create:groups
update:groups
delete:groups
delete:roles
delete:permissions
```

### Auth0 Rules

You also need to ensure that the client ID of the Auth0 Application you created for the Control panel is added to the `add-group-claim-to-token.js` rule in the [Auth0 config repo](https://github.com/ministryofjustice/analytics-platform-auth0)
