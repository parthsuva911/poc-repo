# Function to check if namespace is available
check_namespace() {
    kubectl get namespace "${BRANCH}" &> /dev/null
    return $?
}

# Function to create Kubernetes deployment
create_deployment() {
    export ECR_REPOSITORY=${{ env.ECR_REGISTRY }}/${{ env.ECR_REPOSITORY }}
    export IMAGE_TAG=${{ env.SHORT_SHA }}
    export KUBECONFIG=kubeconfig.yaml
    envsubst < manifests/deployment.tmpl.yaml > manifests/deployment.yaml

    deployment_name=$(grep -E '^\s*name:' manifests/deployment.yaml | awk '{print $2}')
    echo "Deployment name: $deployment_name"
    
    kubectl apply -f manifests/ -n "$BRANCH"
    echo $deployment_name
}

# Function to wait for deployment to complete
wait_for_deployment() {
    deployment_name="$1"
    kubectl rollout status deployment/"$deployment_name" -n "${BRANCH}"
    return $?
}

# Function to rollback deployment
rollback_deployment() {
    deployment_name="$1"
    # kubectl apply -f "$deployment_manifest"
    kubectl rollout undo deployment/"$deployment_name" -n "${BRANCH}"
}

# Main function
main() {
    # deployment_name=$(basename "$deployment_manifest" .yaml)
    BRANCH="develop"

    if check_namespace "${BRANCH}"; then
        echo "Namespace ${BRANCH} exists for deployment."
        # deployment_name=$(create_deployment) 
        # if wait_for_deployment "$deployment_name"; then
        #     echo "Deployment succeeded."
        # else
        #     echo "Deployment failed. Rolling back..."
        #     rollback_deployment "$deployment_name"
        # fi
    else
        echo "Namespace ${BRANCH} not available."
    fi
}

# Usage: ./script.sh <namespace> <deployment_manifest>
main
