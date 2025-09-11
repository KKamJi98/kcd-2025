#!/usr/bin/env bash

kubectl apply -f west-root-application.yaml --context kcd-argo
kubectl apply -f east-root-application.yaml --context kcd-argo

