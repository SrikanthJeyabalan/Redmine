resource "aws_ecs_task_definition" "service" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "Srikanth_redmine"
      image     = var.RFRedmineImage
      cpu       = var.RFRedmineContainerCpu
      memory    = var.RFRedmineContainerMemory
      essential = true
      portMappings = [
        {
          containerPort = 3000
        }
      ]
    MountPoints = [
        {
          sourceVolume  = "app-logs-volume"
          containerPath = "/app/log"
        },
        {
          sourceVolume  = "app-data-volume"
          containerPath = "/app/nginx/logs"
        }
      ]
    }