// This is a filter that is applied to envoy proxy to make external authorizer api use OPA on through grCP ( note target_uri )
resource "k8s_networking_istio_io_envoy_filter_v1alpha3" "minimal" {
  metadata = {
    name      = "ext-authz"
    namespace = "istio-system"
  }

  spec = {
    config_patches = [{
      apply_to = "HTTP_FILTER"
      match = {
        context = "SIDECAR_INBOUND"
        listener = {
          filter_chain = {
            filter = {
              name = "envoy.filters.network.http_connection_manager"
              sub_filter = {
                name = "envoy.filters.http.router"
              }
            }
          }
        }
      }
      patch = {
        operation = "INSERT_BEFORE"
        value = {
          name = "envoy.ext_authz"
          typed_config = {
            "@type"               = "type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz"
            transport_api_version = "V3"
            status_on_error = {
              code = "ServiceUnavailable"
            }
            with_request_body = {
              max_request_bytes     = 8192
              allow_partial_message = true
            }
            grpc_service = {
              google_grpc = {
                target_uri  = "127.0.0.1:9191"
                stat_prefix = "ext_authz"
              }
            }
          }
        }
      }
    }]
  }
}

resource "kubernetes_secret_v1" "opa_istio_cert" {
  metadata {
    name      = "server-cert"
    namespace = "opa-istio"
  }

  data = {
    "tls.crt" = file("${path.module}/certs/cert.pem")
    "tls.key" = file("${path.module}/certs/key.pem")
  }
}

resource "kubernetes_config_map" "inject_policy" {
  metadata {
    name      = "inject-policy"
    namespace = "opa-istio"
  }

  data = {
    "inject.rego" = <<EOF
    package istio

    uid := input.request.uid

    inject = {
      "apiVersion": "admission.k8s.io/v1",
      "kind": "AdmissionReview",
      "response": {
        "allowed": true,
        "uid": uid,
        "patchType": "JSONPatch",
        "patch": base64.encode(json.marshal(patch)),
      },
    }

    patch = [{
      "op": "add",
      "path": "/spec/containers/-",
      "value": opa_container,
    }, {
      "op": "add",
      "path": "/spec/volumes/-",
      "value": opa_config_volume,
    }, {
      "op": "add",
      "path": "/spec/volumes/-",
      "value": opa_policy_volume,
    }]

    opa_container = {
      "image": "openpolicyagent/opa:latest-istio",
      "name": "opa-istio",
      "args": [
        "run",
        "--server",
        "--config-file=/config/config.yaml",
        "--addr=localhost:8181",
        "--diagnostic-addr=0.0.0.0:8282",
        "/policy/policy.rego",
      ],
      "volumeMounts": [{
        "mountPath": "/config",
        "name": "opa-istio-config",
      }, {
        "mountPath": "/policy",
        "name": "opa-policy",
      }],
      "readinessProbe": {
        "httpGet": {
          "path": "/health?plugins",
          "port": 8282,
        },
      },
      "livenessProbe": {
        "httpGet": {
          "path": "/health?plugins",
          "port": 8282,
        },
      }
    }

    opa_config_volume = {
      "name": "opa-istio-config",
      "configMap": {"name": "opa-istio-config"},
    }

    opa_policy_volume = {
      "name": "opa-policy",
      "configMap": {"name": "opa-policy"},
    }
EOF
  }
}

resource "kubernetes_service" "admission_controller" {
  metadata {
    name      = "admission-controller"
    namespace = "opa-istio"

    labels = {
      app = "admission-controller"
    }
  }

  spec {
    selector = {
      app = "admission-controller"
    }

    port {
      name        = "https"
      protocol    = "TCP"
      port        = 443
      target_port = 8443
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "admission_controller" {
  metadata {
    name      = "admission-controller"
    namespace = "opa-istio"
    labels = {
      app = "admission-controller"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "admission-controller"
      }
    }

    template {
      metadata {
        labels = {
          app = "admission-controller"
        }
      }

      spec {
        container {
          image = "openpolicyagent/opa:latest"
          name  = "opa"
          port {
            container_port = 8443
          }

          args = [
            "run",
            "--server",
            "--tls-cert-file=/certs/tls.crt",
            "--tls-private-key-file=/certs/tls.key",
            "--addr=0.0.0.0:8443",
            "/policies/inject.rego"
          ]

          liveness_probe {
            http_get {
              path   = "/health?plugins"
              port   = 8443
              scheme = "HTTPS"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          readiness_probe {
            http_get {
              path   = "/health?plugins"
              port   = 8443
              scheme = "HTTPS"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          volume_mount {
            mount_path = "/certs"
            name       = "server-cert"
            read_only  = true
          }

          volume_mount {
            mount_path = "/policies"
            name       = "inject-policy"
            read_only  = true
          }
        }

        volume {
          name = "inject-policy"

          config_map {
            name = "inject-policy"
          }
        }

        volume {
          name = "server-cert"

          secret {
            secret_name = "server-cert"
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_secret_v1.opa_istio_cert,
    kubernetes_config_map.inject_policy
  ]
}

# resource "kubernetes_mutating_webhook_configuration_v1" "opa_istio_admission_controller" {
#   metadata {
#     name = "opa-istio-admission-controller"
#   }

#   webhook {
#     name = "opa.terraform.io"

#     admission_review_versions = ["v1", "v1beta1"]

#     client_config {
#       service {
#         namespace = "opa-istio"
#         name      = "admission-controller"
#       }
#     }

#     rule {
#       api_groups   = ["*"]
#       api_versions = ["*"]
#       operations   = ["CREATE", "UPDATE"]
#       resources    = ["*"]
#       scope        = "Namespaced"
#     }

#     reinvocation_policy = "IfNeeded"
#     side_effects        = "None"
#   }

#   depends_on = [
#     kubernetes_service.admission_controller,
#     kubernetes_deployment.admission_controller
#   ]

# }

resource "kubernetes_config_map" "opa_istio_config" {
  metadata {
    name = "opa-istio-config"
  }

  data = {
    "config.yaml" = <<EOF
    plugins:
      envoy_ext_authz_grpc:
        addr: :9191
        path: istio/authz/allow
    decision_logs:
      console: true
    EOF
  }
}

resource "kubernetes_config_map" "opa_policy" {
  metadata {
    name = "opa-policy"
  }

  data = {
    "policy.rego" = <<EOF
    package istio.authz

    import input.attributes.request.http as http_request
    import input.parsed_path

    default allow = false

    allow {
        parsed_path[0] == "health"
        http_request.method == "GET"
    }

    allow {
        roles_for_user[r]
        required_roles[r]
    }

    roles_for_user[r] {
        r := user_roles[user_name][_]
    }

    required_roles[r] {
        perm := role_perms[r][_]
        perm.method = http_request.method
        perm.path = http_request.path
    }

    user_name = parsed {
        [_, encoded] := split(http_request.headers.authorization, " ")
        [parsed, _] := split(base64url.decode(encoded), ":")
    }

    user_roles = {
        "alice": ["guest"],
        "bob": ["admin"]
    }

    role_perms = {
        "guest": [
            {"method": "GET",  "path": "/productpage"},
        ],
        "admin": [
            {"method": "GET",  "path": "/productpage"},
            {"method": "GET",  "path": "/api/v1/products"},
        ],
    }
EOF
  }
}
