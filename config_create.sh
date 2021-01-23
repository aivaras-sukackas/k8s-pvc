#!/bin/bash
user=<vartotojo vardas>
KUBERNETES_API_ENDPOINT=$(kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " ")
clusterName=$(kubectl config view -o jsonpath='{.clusters[0].name}')
###------no-editting-after-this-user(!?)---------

#nuskaitome sukurto vartotojo token'o Secret'o pavadinimą
        userTokenSecret=`kubectl describe sa $user -n $user | grep Tokens: | awk '{print $2}'`
#nuskaitome vartotojo prisijungimo token'ą
        userToken=`kubectl get secret $userTokenSecret -n $user -o "jsonpath={.data.token}" | base64 -d`
#nuskaitome varotojo prisijungimo sertifikatą
        userCertificate=`kubectl get secret $userTokenSecret -n $user -o "jsonpath={.data['ca\.crt']}" `


#sukurti config fail'ą
cat <<EOT>> ~/config
apiVersion: v1
kind: Config
preferences: {}

# Define the cluster
clusters:
- cluster:
    certificate-authority-data: $userCertificate
    # You'll need the API endpoint of your Cluster here:
    server: $KUBERNETES_API_ENDPOINT
  name: $clusterName
# Define the user
users:
- name: $user
  user:
    as-user-extra: {}
    client-key-data: $userCertificate
    token: $userToken

# Define the context: linking a user to a cluster
contexts:
- context:
    cluster: $clusterName
    namespace: $user
    user: $user
  name: $user

# Define current context
current-context: $user
EOT