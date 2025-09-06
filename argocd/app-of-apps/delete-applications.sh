#!/usr/bin/env bash

set -euo pipefail

argocd app delete argocd/kcd-2025-west --cascade -y
argocd app delete argocd/kcd-2025-east --cascade -y