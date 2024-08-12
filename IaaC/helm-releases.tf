resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.service.nodePorts.http"
    value = "31293"
  }

  set {
    name  = "controller.hostNetwork"
    value = "true"
  }

}

resource "helm_release" "mm_kafka" {
  name       = "mm-kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"

  set {
    name  = "server.dev.enabled"
    value = "true"
  }

  set {
    name  = "ui.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }


}

resource "helm_release" "node_temeletry_processor" {
  name       = "mm-telemetry-processor"
  repository = "https://polyhistor.github.io/helmChartsRepoForMetamycelium/nodejs-telemetry-processor-chart"
  chart      = "mm-telemetry-processor"
  namespace  = "istio-service-mesh"

  values = [
    <<-EOF
    podAnnotations:
      sidecar.istio.io/inject: "true"
    EOF
  ]


}

resource "helm_release" "istio_base" {
  name  = "istio-base"
  chart = "base"

  repository = "https://istio-release.storage.googleapis.com/charts"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  set {
    name  = "defaultRevision"
    value = "default"
  }


}

resource "helm_release" "istiod" {
  name  = "istiod"
  chart = "istiod"

  repository = "https://istio-release.storage.googleapis.com/charts"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  depends_on = [helm_release.istio_base]
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  chart      = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  depends_on = [helm_release.istiod]
}

resource "helm_release" "kiali" {
  name       = "kiali"
  chart      = "kiali-server"
  repository = "https://kiali.org/helm-charts"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  set {
    name  = "external_services.prometheus.url"
    value = "http://prometheus-server.${kubernetes_namespace.istio_system.metadata[0].name}.svc.cluster.local:80"
  }

  set {
    name  = "auth.strategy"
    value = "anonymous"
  }

  set {
    name  = "ingress.enabled"
    value = "false"
  }

  # set {
  #   name  = "auth.token.secret_name"
  #   value = kubernetes_secret.kiali_token.metadata[0].name
  # }

  depends_on = [helm_release.prometheus]
}

resource "helm_release" "minio" {
  name       = "minio"
  chart      = "minio"
  repository = "https://helm.min.io"
  namespace  = "default"

  set {
    name  = "accessKey"
    value = "minioadmin"
  }

  set {
    name  = "secretKey"
    value = "minioadmin"
  }

  set {
    name  = "mode"
    value = "standalone"
  }
}


