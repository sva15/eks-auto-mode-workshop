# eks-auto-mode-workshop


aws eks update-kubeconfig --name sandbox-vpc-eks-test --region us-west-2



kubectl apply -k .

kubectl delete -k .



kubectl get pods --watch


kubectl get svc wordpress




helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
helm upgrade --install aws-efs-csi-driver --namespace kube-system aws-efs-csi-driver/aws-efs-csi-driver



efs_id = "fs-0fcb78e173efe62c2"





helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm install aws-ebs-csi aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system \
  --set controller.serviceAccount.create=true \
  --set controller.serviceAccount.name=ebs-csi-controller-sa



helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

helm install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args={--kubelet-insecure-tls}



helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml




new guide:

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install -n kube-system csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver

helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
helm install -n kube-system secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws



export CLUSTERNAME="sandbox-vpc-eks-test"
export REGION="us-west-2"

POLICY_ARN=$(aws --region "$REGION" --query Policy.Arn --output text iam create-policy --policy-name wordpress-deployment-policy --policy-document '{
    "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource": ["arn:aws:secretsmanager:us-west-2:120717539064:secret:sandbox-vpc-eks-test-aurora-db-secret-995I4K"]
    } ]
}')

eksctl create addon --name eks-pod-identity-agent --cluster "$CLUSTERNAME" --region "$REGION"



ROLE_ARN=$(aws --region "$REGION" --query Role.Arn --output text iam create-role --role-name wordpress-deployment-role --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}')

aws iam attach-role-policy \
    --role-name wordpress-deployment-role \
    --policy-arn $POLICY_ARN


eksctl create podidentityassociation \
    --cluster "$CLUSTERNAME" \
    --namespace default \
    --region "$REGION" \
    --service-account-name wordpress-deployment-sa \
    --role-arn $ROLE_ARN \
    --create-service-account true


kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/examples/ExampleSecretProviderClass-PodIdentity.yaml

kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/examples/ExampleDeployment-PodIdentity.yaml



kubectl exec -it $(kubectl get pods | awk '/nginx-pod-identity-deployment/{print $1}' | head -1) -- cat /mnt/secrets-store/MySecret; echo





final setup:


eksctl create iamserviceaccount --name wordpress-deployment-sa --region="$REGION" --cluster "$CLUSTERNAME" --attach-policy-arn "$POLICY_ARN" --approve --override-existing-serviceaccounts



kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/examples/ExampleSecretProviderClass-IRSA.yaml