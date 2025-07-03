resource "aws_cloudwatch_dashboard" "monitoring_dashboard" {
  dashboard_name = "${var.customer_name}-dashboard-${var.environment}"
  dashboard_body = jsonencode({
    widgets = concat(
      // Cabeçalho ALB (incluso se existir pelo menos 1 ALB)
      length(data.aws_lb.application_lb) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = 0
          width  = 24
          height = 1
          properties = {
            markdown   = "# Application Load Balancer Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets ALB
      local.application_lb_widgets,

      // Cabeçalho NLB (incluso se existir pelo menos 1 NLB)
      length(data.aws_lb.network_lb) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.nlb_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# Network Load Balancer Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets NLB
      local.network_lb_widgets,

      // Cabeçalho EC2 (incluso se existir pelo menos 1 instância EC2)
      length(data.aws_instances.existing.ids) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.ec2_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# EC2 Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets EC2
      local.ec2_widgets,

      // Cabeçalho RDS (incluso se existir pelo menos 1 RDS)
      length(local.RDS.rds_list) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.rds_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# RDS Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets RDS
      local.rds_widgets,

      // Cabeçalho Aurora Provisioned
      length(local.Aurora.provisioned) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.aurora_provisioned_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# Aurora Provisioned Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets Aurora Provisioned
      local.aurora_provisioned_widgets,

      // Cabeçalho Aurora Serverless V1
      length(local.Aurora.serverless_v1) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.aurora_serverless_v1_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# Aurora Serverless V1 Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets Aurora Serverless V1
      local.aurora_serverless_v1_widgets,

      // Cabeçalho Aurora Serverless V2
      length(local.Aurora.serverless_v2) > 0 ? [
        {
          type   = "text"
          x      = 0
          y      = local.aurora_serverless_v2_header_y
          width  = 24
          height = 1
          properties = {
            markdown   = "# Aurora Serverless V2 Metrics\n\n"
            background = "transparent"
          }
        }
      ] : [],
      // Widgets Aurora Serverless V2
      local.aurora_serverless_v2_widgets
    )
  })
}