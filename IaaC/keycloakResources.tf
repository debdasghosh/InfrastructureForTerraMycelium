resource "kubernetes_service" "keycloak" {
  metadata {
    name = "keycloak"
    labels = {
      app = "keycloak"
    }
  }
  spec {
    selector = {
      app = "keycloak"
    }
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }

  }
}


resource "kubernetes_deployment" "keycloak" {
  metadata {
    name = "keycloak"
    labels = {
      app = "keycloak"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "keycloak"
      }
    }

    template {
      metadata {
        labels = {
          app = "keycloak"
        }
      }

      spec {
        container {
          image = "quay.io/keycloak/keycloak:21.1.1"
          name  = "keycloak"
          args  = ["start-dev"]

          env {
            name  = "KEYCLOAK_ADMIN"
            value = "admin"
          }

          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = "admin"
          }

          env {
            name  = "KC_HTTP_RELATIVE_PATH"
            value = "/keycloak"
          }


          env {
            name  = "KC_PROXY"
            value = "passthrough"
          }


          port {
            name           = "http"
            container_port = 8080
          }
        }
      }
    }
  }
}
