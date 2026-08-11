#!/usr/bin/env bash
set -euo pipefail

echo "=== Cluster-wide Health Check ==="

echo -e "\n--- Node Status ---"
kubectl get nodes

echo -e "\n--- System Pods ---"
kubectl get pods -n kube-system | grep -E "(autoscaler|coredns)"

echo -e "\n--- Karpenter ---"
kubectl get pods -n karpenter
kubectl get nodeclaims

echo -e "\n--- Ingress ---"
kubectl get pods -n ingress-nginx
kubectl get ingress -A | head -10

echo -e "\n--- External DNS ---"
kubectl get pods -n external-dns

echo -e "\n--- External Secrets ---"
kubectl get pods -n external-secrets
kubectl get externalsecrets -A | grep -v "SecretSynced" | head -10

echo -e "\n--- Kyverno ---"
kubectl get pods -n kyverno

echo -e "\n--- Velero ---"
kubectl get pods -n velero
velero backup-location get 2>/dev/null || echo "velero CLI not installed"

echo -e "\n--- KEDA ---"
kubectl get pods -n keda
kubectl get scaledobjects -A

echo -e "\n--- Recent Events (Warnings) ---"
kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp' | tail -20
