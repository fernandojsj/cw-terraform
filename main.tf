resource "aws_cloudwatch_dashboard" "monitoring_dashboard" {
  dashboard_name = "${var.name}-dashboard-${var.env}"
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
      length(local.map_of_rds.rds_list) > 0 ? [
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
      local.rds_widgets
    )
  })
}
