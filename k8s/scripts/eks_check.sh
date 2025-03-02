#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install it first."
    exit 1
fi

# 1. Verify cluster connectivity
echo "Checking cluster information..."
kubectl cluster-info

# 2. List all nodes to confirm they are ready
echo "Listing all nodes..."
kubectl get nodes

# 3. Check the current Kubernetes context
echo "Checking the current kubeconfig context..."
kubectl config current-context

# 4. List all namespaces to verify access scope
echo "Listing all namespaces..."
kubectl get ns

# 5. Run a test pod to check deployment capability
echo "Deploying a test pod..."
kubectl run test-pod --image=nginx --restart=Never
echo "Waiting for the test pod to be scheduled..."
sleep 5  # Give Kubernetes time to schedule the pod

# 6. Verify the test pod status
echo "Checking test pod status..."
kubectl get pods

echo "EKS cluster verification completed."

# Cleanup test pod (optional)
echo "Cleaning up test pod..."
kubectl delete pod test-pod --ignore-not-found=true
