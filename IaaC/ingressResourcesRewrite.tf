resource "kubernetes_ingress_v1" "kafka_rest_proxy_ingress" {
  metadata {
    name = "kafka-rest-proxy-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "localhost"
      http {
        path {
          path      = "/kafka-rest-proxy(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "kafka-rest-proxy"
              port {
                number = 8082
              }
            }
          }
        }

        path {
          path_type = "Prefix"
          path      = "/kiali(/|$)(.*)"

          backend {
            service {
              name = "kiali"
              port {
                number = 20001
              }
            }
          }
        }

      }
    }
  }

  wait_for_load_balancer = false
}

