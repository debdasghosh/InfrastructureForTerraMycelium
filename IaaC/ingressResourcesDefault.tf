resource "kubernetes_ingress_v1" "keycloak_ingress" {
  metadata {
    name = "keycloak-ingress"
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "localhost"
      http {
        path {
          path = "/keycloak"
          backend {
            service {
              name = "keycloak"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/kafka"
          backend {
            service {
              name = "mm-kafka"
              port {
                number = 9092
              }
            }
          }
        }
      }
    }
  }
  wait_for_load_balancer = false
}
