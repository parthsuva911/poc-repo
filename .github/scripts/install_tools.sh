VERSION=$(curl --silent https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl https://storage.googleapis.com/kubernetes-release/release/$VERSION/bin/linux/amd64/kubectl \
    --progress-bar \
    --location \
    --remote-name
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
echo ${{ secrets.KUBECONFIG }} | base64 --decode > kubeconfig.yaml