#!/bin/bash

# set -x

# Check if AWS CLI is installed
if ! command -v aws > /dev/null; then
    echo "AWS CLI is not installed. Please install it and configure your credentials."
    exit 1
fi

read -p "Enter AWS region (default: ap-south-1): " aws_region
aws_region=${aws_region:-ap-south-1}

read -p "Enter project name (default: poc2): " project_name
project_name=${project_name:-poc2}

read -p "Enter project name (default: 10.0.0.0/16): " vpc_cidr
vpc_cidr=${vpc_cidr:-10.0.0.0/16}

read -p "Enter project name (default: 10.0.1.0/24): " subnet_1_cidr
subnet_1_cidr=${subnet_1_cidr:-10.0.1.0/24}

read -p "Enter project name (default: 10.0.2.0/24): " subnet_2_cidr
subnet_2_cidr=${subnet_2_cidr:-10.0.2.0/24}

read -p "Enter project name (default: 1.29): " eks_version
eks_version=${eks_version:-1.29}

echo "deploying cloudformation stack"
aws cloudformation create-stack \
    --stack-name "$project_name-stack" \
    --template-body "file://infra.yml" \
    --region $aws_region \
    --parameters \
    "ParameterKey=ProjectName,ParameterValue=$project_name" \
    "ParameterKey=VpcCidr,ParameterValue=$vpc_cidr" \
    "ParameterKey=Subnet1Cidr,ParameterValue=$subnet_1_cidr" \
    "ParameterKey=Subnet2Cidr,ParameterValue=$subnet_2_cidr" \
    "ParameterKey=EKSVersion,ParameterValue=$eks_version" \
    --capabilities CAPABILITY_NAMED_IAM
echo "Cloudformation stack deployment started."

echo "Wait for cloudformation stack to deploy completely."
aws cloudformation wait stack-create-complete --region $aws_region --stack-name "$project_name-stack"
echo "Cloudformation stack is deployed completely."

cluster_name="$project_name-cluster"

echo "Update kubeconfig."
aws eks update-kubeconfig --name poc-cluster --region $aws_region
echo "kubeconfig is updated."

echo "Retriving OIDC ID for newly created cluster."
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --region $aws_region --output text | cut -d '/' -f 5)
if ! echo $oidc_id > /dev/null; then
    echo "IAM OIDC provider is not configured. Configuring now."
    aws iam list-open-id-connect-providers  --region $aws_region | grep $oidc_id | cut -d "/" -f4
    eksctl utils associate-iam-oidc-provider --cluster $cluster_name  --region $aws_region --approve
    echo "IAM OIDC provider is configured."
else
    echo "IAM OIDC provider is already configured."
    echo "OIDC ID of new cluster is $oidc_id"
fi

echo "Creating IAM permission for AWS Load Balancer Controller."
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json
policy_arn=$(aws iam create-policy \
                    --policy-name $project_name-AWSLoadBalancerControllerIAMPolicy \
                    --policy-document file://iam_policy.json \
                    --query 'Policy.Arn' \
                    --output text)
echo "Attaching IAM permission for AWS Load Balancer Controller."
eksctl create iamserviceaccount 
    --cluster=$cluster_name \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --role-name AmazonEKSLoadBalancerControllerRole \
    --attach-policy-arn=$policy_arn \
    --approve
echo "IAM permission for AWS Load Balancer Controller is created and attached to sa."

echo "Adding eks-charts helm charts"
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
echo "Installing AWS load balancer controller."
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$cluster_name \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller
