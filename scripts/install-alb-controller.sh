#!/bin/bash

# AWS Load Balancer Controller Installation Script
# Usage: ./install-alb-controller.sh <CLUSTER_NAME> <AWS_REGION>

set -e  # Exit on error

# Validate inputs
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <CLUSTER_NAME> <AWS_REGION>"
    exit 1
fi

CLUSTER_NAME=$1
AWS_REGION=$2

# Verify kubectl is configured for the cluster
echo "Verifying cluster access..."
kubectl cluster-info > /dev/null 2>&1 || {
    echo "ERROR: kubectl is not properly configured for cluster $CLUSTER_NAME"
    exit 1
}

# Add EKS Helm repository
echo "Adding EKS Helm repository..."
helm repo add eks https://aws.github.io/eks-charts > /dev/null
helm repo update > /dev/null

# Install AWS Load Balancer Controller
echo "Installing AWS Load Balancer Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.create=false \
  --set region="$AWS_REGION" \
  --wait  # Wait for deployment to complete

# Verify installation
echo "Verifying installation..."
kubectl -n kube-system rollout status deployment aws-load-balancer-controller --timeout=120s

echo "AWS Load Balancer Controller successfully installed!"