cd flask-app
docker image build --tag "${ECR_REGISTRY}"/"${ECR_REPOSITORY}":"${SHORT_SHA}" .
# docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
docker push "${ECR_REGISTRY}"/"${ECR_REPOSITORY}":"${SHORT_SHA}"