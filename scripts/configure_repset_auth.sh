#!/bin/bash
##
# Script to connect to the first Mongod instance running in a container of the
# Kubernetes StatefulSet, via the Mongo Shell, to initalise a MongoDB Replica
# Set and create a MongoDB admin user.
#
# IMPORTANT: Only run this once 3 StatefulSet mongod pods are show with status
# running (to see pod status run: $ kubectl get all)
##

# Check for password argument
if [[ $# -eq 0 ]] ; then
    echo 'You must provide one argument for the password of the "main_admin" user to be created'
    echo '  Usage:  configure_repset_auth.sh MyPa55wd123'
    echo
    exit 1
fi

# Initiate replica set configuration
echo "Configuring the MongoDB Replica Set"
kubectl exec mongod-0 -c mongod-container -- mongo --eval 'rs.initiate({_id: "MainRepSet", version: 1, members: [ {_id: 0, host: "mongod-0.mongodb-service.default.svc.cluster.local:27017", priority: 1}, {_id: 1, host: "mongod-1.mongodb-service.default.svc.cluster.local:27017", priority: 0.5}, {_id: 2, host: "mongod-2.mongodb-service.default.svc.cluster.local:27017", priority: 0.5} ]});'

# Wait a bit until the replica set should have a primary ready
echo "Waiting for the Replica Set to initialise..."
sleep 30
kubectl exec mongod-0 -c mongod-container -- mongo --eval 'rs.status();'

# Create the admin user (this will automatically disable the localhost exception)
echo "Creating user: 'main_admin'"
kubectl exec mongod-0 -c mongod-container -- mongo --eval 'db.getSiblingDB("admin").createUser({user:"main_admin",pwd:"'"${1}"'",roles:[{role:"root",db:"admin"}]});'
echo

# Create a local port forwarding to connect mongodb clients
echo " Creating port forward for mongodb-service to: 127.0.0.1:27017"
kubectl port-forward service/mongodb-service 27017:27017 &
echo "Connect string: mongodb://main_admin:<YOUR_PASSWORD>@0.0.0.0:27017/?authSource=admin&replicaSet=MainRepSet&readPreference=primary&appname=MongoDB%20Compass&directConnection=true&ssl=false"
echo

