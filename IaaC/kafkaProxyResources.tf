resource "kubernetes_deployment" "kafka_rest_proxy" {
  metadata {
    name = "kafka-rest-proxy"
    labels = {
      app = "kafka-rest-proxy"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "kafka-rest-proxy"
      }
    }

    template {
      metadata {
        labels = {
          app = "kafka-rest-proxy"
        }
      }

      spec {
        container {
          image = "confluentinc/cp-kafka-rest"
          name  = "kafka-rest-proxy"

          env {
            name  = "KAFKA_REST_HOST_NAME"
            value = "kafka-rest-proxy"
          }
          env {
            name  = "KAFKA_REST_BOOTSTRAP_SERVERS"
            value = "PLAINTEXT://mm-kafka.default.svc.cluster.local:9092"
          }
          env {
            name  = "KAFKA_REST_LISTENERS"
            value = "http://0.0.0.0:8082"
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "kafka_rest_proxy" {
  metadata {
    name = "kafka-rest-proxy"
  }
  spec {
    selector = {
      app = "kafka-rest-proxy"
    }
    port {
      port        = 8082
      target_port = 8082
    }
  }
}


