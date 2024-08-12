resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"

    labels = {
      "istio-injection" = "true"
    }
  }
}

resource "kubernetes_namespace" "istio_service_mesh" {
  metadata {
    name = "istio-service-mesh"
    labels = {
      "istio-injection" = "true"
    }
  }
}


resource "kubernetes_namespace" "opa_istio_service_mesh" {
  metadata {
    name = "opa-istio"
  }
}




