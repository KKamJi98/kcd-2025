#!/bin/bash

set -euo pipefail

aws eks update-kubeconfig --region ap-northeast-2 --name kcd-east --alias kcd-east
aws eks update-kubeconfig --region ap-northeast-2 --name kcd-west --alias kcd-west
