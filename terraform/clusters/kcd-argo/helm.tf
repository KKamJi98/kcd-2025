###############################################
# AWS Load Balancer Controller via Helm (kcd-argo)
###############################################

resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.13.0"
  namespace        = "kube-system"
  create_namespace = false

  # Ensure cluster is available before Helm install
  depends_on = [module.eks]

  set = [
    {
      name  = "clusterName"
      value = local.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }
  ]
}

###############################################
# Argo CD via Helm (kcd-argo)
###############################################

resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [module.eks]

  values = [<<-YAML
    global:
      domain: argocd-kcd.kkamji.net

    certificate:
      enabled: true

    server:
      replicas: 1
      ingress:
        enabled: true
        ingressClassName: alb
        hostname: argocd-kcd.kkamji.net
        tls: true
        annotations:
          kubernetes.io/ingress.class: alb
          alb.ingress.kubernetes.io/ssl-redirect: "443"
          alb.ingress.kubernetes.io/backend-protocol: "HTTPS"
          alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-northeast-2:376129852049:certificate/c5061c99-c50c-4d7c-bbdf-562a20fa451d

    redis-ha:
      enabled: false

    controller:
      replicas: 1

    repoServer:
      replicas: 1

    applicationSet:
      replicas: 1

    configs:
      cm:
        oidc.config: |
          name: Keycloak
          issuer: https://keycloak.kkamji.net/realms/master
          clientID: argocd
          enablePKCEAuthentication: true
          requestedScopes: ["openid", "profile", "email", "groups"]
      rbac:
        policy.csv: |
          p, role:admin, *, *, *, allow
          #      p, role:admin, repositories, get, *, allow
          #      p, role:admin, repositories, create, *, allow
          #      p, role:admin, repositories, update, *, allow
          #      p, role:admin, repositories, delete, *, allow
          g, ArgoCDAdmins, role:admin
          g, admin, role:admin

    notifications:
      enabled: true
      secret:
        create: false
        items:
          slack-token: "My Token"
      subscriptions:
        - recipients:
            - slack:00-argocd-alarm
          triggers:
            - on-sync-status-unknown
            - on-sync-failed
            - on-sync-succeeded
            - on-deployed
            - on-health-degraded
        - recipients:
            - slack:00-argocd-alarm
          selector: test=true
          triggers:
            - on-sync-status-unknown
      templates:
        template.app-deployed: |
          email:
            subject: New version of an application {{.app.metadata.name}} is up and running.
          message: |
            {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application {{.app.metadata.name}} is now running new version of deployments manifests.
          slack:
            attachments: |
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#18be52",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                },
                {
                  "title": "Revision",
                  "value": "{{.app.status.sync.revision}}",
                  "short": true
                }
                {{range $index, $c := .app.status.conditions}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "{{$c.type}}",
                  "value": "{{$c.message}}",
                  "short": true
                }
                {{end}}
                ]
              }]
        template.app-health-degraded: |
          email:
            subject: Application {{.app.metadata.name}} has degraded.
          message: |
            {{if eq .serviceType "slack"}}:exclamation:{{end}} Application {{.app.metadata.name}} has degraded.
            Application details: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}.
          slack:
            attachments: |-
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#f4c030",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                }
                {{range $index, $c := .app.status.conditions}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "{{$c.type}}",
                  "value": "{{$c.message}}",
                  "short": true
                }
                {{end}}
                ]
              }]
        template.app-sync-failed: |
          email:
            subject: Failed to sync application {{.app.metadata.name}}.
          message: |
            {{if eq .serviceType "slack"}}:exclamation:{{end}}  The sync operation of application {{.app.metadata.name}} has failed at {{.app.status.operationState.finishedAt}} with the following error: {{.app.status.operationState.message}}
            Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .
          slack:
            attachments: |-
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#E96D76",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                }
                {{range $index, $c := .app.status.conditions}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "{{$c.type}}",
                  "value": "{{$c.message}}",
                  "short": true
                }
                {{end}}
                ]
              }]
        template.app-sync-running: |
          email:
            subject: Start syncing application {{.app.metadata.name}}.
          message: |
            The sync operation of application {{.app.metadata.name}} has started at {{.app.status.operationState.startedAt}}.
            Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .
          slack:
            attachments: |-
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#0DADEA",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                }
                {{range $index, $c := .app.status.conditions}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "{{$c.type}}",
                  "value": "{{$c.message}}",
                  "short": true
                }
                {{end}}
                ]
              }]
        template.app-sync-status-unknown: |
          email:
            subject: Application {{.app.metadata.name}} sync status is 'Unknown'
          message: |
            {{if eq .serviceType "slack"}}:exclamation:{{end}} Application {{.app.metadata.name}} sync is 'Unknown'.
            Application details: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}.
            {{if ne .serviceType "slack"}}
            {{range $c := .app.status.conditions}}
                * {{$c.message}}
            {{end}}
            {{end}}
          slack:
            attachments: |-
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#E96D76",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                }
                {{range $index, $c := .app.status.conditions}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "{{$c.type}}",
                  "value": "{{$c.message}}",
                  "short": true
                }
                {{end}}
                ]
              }]
        template.app-sync-succeeded: |
          email:
            subject: Application {{.app.metadata.name}} has been successfully synced.
          message: |
            {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application {{.app.metadata.name}} has been successfully synced at {{.app.status.operationState.finishedAt}}.
            Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .
          slack:
            attachments: |-
              [{
                "title": "{{ .app.metadata.name}}",
                "title_link":"{{.context.argocdUrl}}/applications/{{.app.metadata.name}}",
                "color": "#18be52",
                "fields": [
                {
                  "title": "Sync Status",
                  "value": "{{.app.status.sync.status}}",
                  "short": true
                },
                {
                  "title": "Repository",
                  "value": "{{.app.spec.source.repoURL}}",
                  "short": true
                }
                {{range $index, $c := .app.status.conditions}}
                {{if not $index}},{{end}}
                {{if $index}},{{end}}
                {
                  "title": "{{$c.type}}",
                  "value": "{{$c.message}}",
                  "short": true
                }
                {{end}}
                ]
              }]
      triggers:
        trigger.on-deployed: |
          - description: Application is synced and healthy. Triggered once per commit.
            oncePer: app.status.sync.revision
            send:
            - app-deployed
            when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
        trigger.on-health-degraded: |
          - description: Application has degraded
            send:
            - app-health-degraded
            when: app.status.health.status == 'Degraded'
        trigger.on-sync-failed: |
          - description: Application syncing has failed
            send:
            - app-sync-failed
            when: app.status.operationState.phase in ['Error', 'Failed']
        trigger.on-sync-running: |
          - description: Application is being synced
            send:
            - app-sync-running
            when: app.status.operationState.phase in ['Running']
        trigger.on-sync-status-unknown: |
          - description: Application status is 'Unknown'
            send:
            - app-sync-status-unknown
            when: app.status.sync.status == 'Unknown'
        trigger.on-sync-succeeded: |
          - description: Application syncing has succeeded
            send:
            - app-sync-succeeded
            when: app.status.operationState.phase in ['Succeeded']
        defaultTriggers: |
          - on-sync-status-unknown
    YAML
  ]
}


resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = local.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_load_balancer_controller_pod_identity.arn

  # Make sure ServiceAccount exists before associating
  depends_on = [helm_release.aws_load_balancer_controller]
}
