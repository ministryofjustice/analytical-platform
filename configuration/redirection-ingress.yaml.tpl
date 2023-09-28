apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-redirection-ingress
  namespace: data-platform-production
  annotations:
    external-dns.alpha.kubernetes.io/set-identifier: app-redirection-ingress-data-platform-production-green
    external-dns.alpha.kubernetes.io/aws-weight: "100"
    nginx.ingress.kubernetes.io/server-snippet: |
%{ for key, value in json_map ~}
      if ($host ~* ^${key}\.apps\.alpha\.mojanalytics\.xyz$) {
          return 301 https://${key}.apps.live.cloud-platform.service.justice.gov.uk$request_uri;
      }
%{ endfor ~}
spec:
  ingressClassName: default
  tls:
  - hosts:
    - "*.apps.alpha.mojanalytics.xyz"
    secretName: apps-alpha-certificate
  rules:
  - host: "*.apps.alpha.mojanalytics.xyz"
    http:
      paths:
      - path: /
        pathType: ImplementationSpecific
        backend:
          service:
            name: shutdown-service
            port:
              number: 80
