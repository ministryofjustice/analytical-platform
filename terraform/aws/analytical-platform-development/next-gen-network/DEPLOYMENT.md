# Secure VPC Deployment Documentation

## Overview
This document outlines the "Secure by Design" and "Deny by Default" VPC network deployed using Terraform. The architecture prioritises strict traffic filtering, comprehensive logging, and defence-in-depth strategies.

## 1. Network Architecture
- **VPC Stance:** Deny by default.
- **Subnet Strategy:** Strictly separated subnets (e.g., `private`, `firewall`) to enforce traffic inspection flows.
- **Connectivity:**
  - No direct internet access for compute (EC2/ECS).
  - All egress traffic must traverse the Network Firewall (with the exception of S3).
## 2. Traffic Inspection (Network Firewall)
The AWS Network Firewall acts as the central inspection point for all traffic.

- **Policy:** strict order (`STRICT_ORDER`) stateful engine.
- **Default Action:** `aws:drop_established` / `aws:alert_established`.
- **Managed Rule Groups:**
  - `AttackInfrastructureStrictOrder` (Action: **DROP**)
  - `BotNetCommandAndControlDomainsStrictOrder` (Action: **DROP**)
  - `MalwareDomainsStrictOrder` (Action: **DROP**)
- **Custom Rule Groups:**
  - `strict`: Explicit Allow-list for IP/Port combinations (e.g., SSH).
  - `strict_fqdn`: Explicit Allow-list for FQDNs (HTTP Host / TLS SNI).

## 3. DNS Security (Route 53 Resolver Firewall)
DNS queries are filtered to prevent resolution of known malicious domains.

- **Action:** **BLOCK** (Returns `NXDOMAIN`).
- **Blocked Lists:**
  - `AWSManagedDomainsAggregateThreatList`
  - `AWSManagedDomainsAmazonGuardDutyThreatList`
  - `AWSManagedDomainsBotnetCommandandControl`
  - `AWSManagedDomainsMalwareDomainList`

## 4. Connectivity & Access (VPC Endpoints)
Private connectivity is configured for AWS Systems Manager and S3 to enable secure access without traversing the public internet or NAT Gateway.

- **Interface Endpoints:**
  - `com.amazonaws.eu-west-2.ssm`
  - `com.amazonaws.eu-west-2.ssmmessages`
  - `com.amazonaws.eu-west-2.ec2messages`
- **Gateway Endpoints:**
  - `com.amazonaws.eu-west-2.s3`
- **Security:** Endpoints are secured by Security Groups unrestricted only from within the VPC private subnets.

## 5. Observability (Flow Logs)
Comprehensive traffic logging is enabled to support security audits and incident response.

- **Destination:** CloudWatch Logs
- **Traffic Type:** ALL (Accepted & Rejected)
- **Format:** Extended format (Version 5+) including:
  - Packet Direction (`flow-direction`)
  - AWS Service Identification (`pkt-src-aws-service`, `pkt-dst-aws-service`)
  - Traffic Path (`traffic-path`)
  - Packet Metadata (`tcp-flags`, `type`, `packets`, `bytes`)

## Known Exceptions
- **DNS Allowlisting:** No "Deny All" wildcard rule exists; only known malicious domains are blocked. Unknown domains will resolve.
- **Network Firewall Inspection:** S3 traffic is routed via the Gateway Endpoint and bypasses the Network Firewall for performance.
