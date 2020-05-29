#!/bin/sh
##
# Script to just undeploy the MongoDB Service & StatefulSet but nothing else.
##

# Just delete mongod stateful set + mongodb service onlys (keep rest of k8s environment in place)
kubectl delete statefulsets mongo
kubectl delete services mongo

# Show persistent volume claims are still reserved even though mongod stateful-set has been undeployed
kubectl get persistentvolumes

