resource "kubernetes_service" "frontend-service" {
  metadata {
    name = "frontend-service"
  }
  spec {
    selector = {
      app = "frontend-pod"
    }
    port {
      port        = var.frontend_envs.PORT
      target_port = var.frontend_envs.PORT
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "frontend-deployment" {
  metadata {
    name = "frontend-deployment"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "frontend-pod"
      }
    }
    template {
      metadata {
        labels = {
          app = "frontend-pod"
        }
      }
      spec {
        container {
          image = var.frontend_envs.IMAGE
          name  = "frontend"
          dynamic "env" {
            for_each = var.frontend_envs
            content {
              name  = env.key
              value = env.value
            }
          }
        }
      }
    }
  }
}

