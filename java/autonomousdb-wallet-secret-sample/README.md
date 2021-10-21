# Java Sample Using an Oracle Wallet as a Kubernetes Secret

In this minimalistic Java sample we show you how to use a wallet downloaded by the Oracle Database Operator for Kubernetes.

An example is also provided to use a wallet downloaded from the Cloud Console.

This microservice can also be used to validate connectivity with the database by looking at its log or issuing http requests.

## Configuration

To configure the database wallet you only need to update [src/main/k8s/app.yaml](src/main/k8s/app.yaml) to use the same secret name that you used to download the wallet with the Operator.

The key part to understand its simplicity is that the deployment file uses the same mount path that the container configures in the oracle.net.wallet_location VM parameter [src/main/docker/Dockerfile](src/main/docker/Dockerfile). You don't need to change this file if you are going to use the example's mount path.

If you want to configure a previously downloaded wallet you can just create the secret (and use the same secret name for the Pod's spec) pointing to the directory where you unzipped the wallet:

```sh
kubectl create secret generic database-wallet --from-file=<path-to-wallets-unzipped-folder>
```
The Java microservice retrieves username, password and url also from a secret. To create it you can use the following script as an example:

```sh
kubectl create secret generic user-jdbc \
  --from-literal=user='<username>' \
  --from-literal=password='<password>' \
  --from-literal=url='jdbc:oracle:thin:@<alias-in-tnsnames.ora>'
```
## Install, build and deploy

It is as simple as to build the maven project, create the docker image and deploy the Pod:

```sh
mvn clean install
docker build -t adb-health-check target
kubectl apply -f target/app.yaml
```

## Usage

After successsful installation you can validate first connectivity through the Pod's log:

```sh
kubectl logs pods/adb-health-check
'Database version: Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production'
'Version 19.13.0.1.0'
'Retrieveing connections: true'
```

And you can use the Pod's http listener to validate connectivity (for local tests you can just port forward a local port):

```sh
kubectl port-forward adb-health-check 8080:8080 &
curl -X GET http://localhost:8080
'{"database-version": "19.0", "database-sysdate": "2021-10-06 15:38:43"}'
```
