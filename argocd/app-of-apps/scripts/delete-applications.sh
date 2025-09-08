#!/usr/bin/env bash

set -euo pipefail

argocd app delete argocd/kcd-2025-root-west --cascade -y
argocd app wait kcd-2025-root-west --operation

argocd app delete argocd/kcd-2025-root-east --cascade -y
argocd app wait kcd-2025-root-east --operation
