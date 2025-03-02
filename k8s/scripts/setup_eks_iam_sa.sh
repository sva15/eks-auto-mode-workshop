#!/bin/bash

# Exit on error
set -e

# Ensure cluster name and region are passed as arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <CLUSTER_NAME> <REGION>"
    exit 1
fi

CLUSTER_NAME="$1"
REGION="$2"

# Check if the cluster exists
echo "Checking if EKS cluster '$CLUSTER_NAME' exists in region '$REGION'..."
if ! aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query "cluster.status" --output text 2>/dev/null | grep -q "ACTIVE"; then
    echo "Error: Cluster '$CLUSTER_NAME' does not exist or is not active in region '$REGION'."
    exit 1
fi

echo "Cluster '$CLUSTER_NAME' exists and is active."

# Create IAM Policy
POLICY_NAME="wordpress-deployment-demo-updated-policy"
echo "Creating IAM policy '$POLICY_NAME'..."
POLICY_ARN=$(aws iam create-policy \
    --region "$REGION" \
    --policy-name "$POLICY_NAME" \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
                "Resource": ["arn:aws:secretsmanager:'"$REGION"':*:secret:mysql-db-secret-*"]
            }
        ]
    }' --query "Policy.Arn" --output text)

echo "IAM policy created with ARN: $POLICY_ARN"

# Associate IAM OIDC provider (only run if not already associated)
if ! eksctl utils describe-iam-identity-mappings --cluster "$CLUSTER_NAME" --region "$REGION" | grep -q "arn:aws:iam::"; then
    echo "Associating IAM OIDC provider..."
    eksctl utils associate-iam-oidc-provider --region="$REGION" --cluster="$CLUSTER_NAME" --approve
    echo "OIDC provider associated."
else
    echo "OIDC provider already associated."
fi

# Create IAM Service Account
SA_NAME="wordpress-deployment-demo-sa-updated"
echo "Creating IAM Service Account '$SA_NAME'..."
eksctl create iamserviceaccount \
    --name "$SA_NAME" \
    --region "$REGION" \
    --cluster "$CLUSTER_NAME" \
    --attach-policy-arn "$POLICY_ARN" \
    --approve \
    --override-existing-serviceaccounts

echo "IAM Service Account '$SA_NAME' created successfully."