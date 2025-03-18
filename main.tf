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

############################### ALARMES ####################################

# Transformando a lista de ARNs em um mapa para uso no for_each
locals {
  alb_map = { for index, alb_arn in data.external.load_balancers.result : "alb_${index}" => alb_arn }
}

# Alarme para [ALB] 5XX Error
resource "aws_cloudwatch_metric_alarm" "alb_5xx_Error" {
  for_each = local.alb_map

  alarm_name          = "${upper(var.customer_name)}-${upper(each.key)}-5XX_STATUS_HIGH"
  metric_name         = "5xx_Percent"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    LoadBalancer = each.value # Agora, `each.value` contém o ARN correto
  }

  alarm_description = "Alarm for ALB 5xx Error for ${each.key}"
  alarm_actions     = [var.alarm_action_arn]
  ok_actions        = [var.alarm_action_arn]
}

# Alarme para [EC2] CPUUtilization
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_utilization" {
  for_each = toset(data.aws_instances.existing.ids)

  alarm_name          = "${upper(var.customer_name)}-${upper(data.aws_instance.detailed[each.key].tags["Name"])}-CPU_HIGH"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = each.value
  }

  alarm_description = "CRITICAL"
  alarm_actions     = [var.alarm_action_arn]
  ok_actions        = [var.alarm_action_arn] # Ação quando o valor voltar a OK
}

# Definir as métricas de memória corretamente para Windows e Linux
locals {
  mem_metrics = {
    for instance_id in data.aws_instances.existing.ids :
    instance_id => lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? 
    {
      name       = "Memory % Committed Bytes In Use"
      dimensions = {
        InstanceId = instance_id
        objectname = "Memory"
      }
    } : {
      name       = "mem_used_percent"
      dimensions = {
        InstanceId = instance_id
      }
    }
  }

  disk_metrics = {
    for instance_id in data.aws_instances.existing.ids :
    instance_id => lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? 
    {
      name       = "LogicalDisk % Free Space"
      threshold  = 20
      dimensions = {
        InstanceId = instance_id
        objectname = "LogicalDisk"
        instance   = "C:"
      }
    } : {
      name       = "disk_used_percent"
      threshold  = 80
      dimensions = {
        InstanceId = instance_id
        path       = "/"
      }
    }
  }
}

# Alarme para [EC2] Memory Utilization
resource "aws_cloudwatch_metric_alarm" "ec2_mem_utilization" {
  for_each = local.mem_metrics

  alarm_name          = "${upper(var.customer_name)}-${upper(data.aws_instance.detailed[each.key].tags["Name"])}-MEM_HIGH"
  namespace           = "CWAgent"
  metric_name         = each.value.name
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions

  alarm_description = "Alarm for EC2 Memory Utilization for Instance ${each.key}"
  alarm_actions     = [var.alarm_action_arn]
  ok_actions        = [var.alarm_action_arn]
}

# Alarme para [EC2] Disk Utilization
resource "aws_cloudwatch_metric_alarm" "ec2_disk_utilization" {
  for_each = local.disk_metrics

  alarm_name          = "${upper(var.customer_name)}-${upper(data.aws_instance.detailed[each.key].tags["Name"])}-DISK_HIGH"
  namespace           = "CWAgent"
  metric_name         = each.value.name
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanThreshold"
  dimensions          = each.value.dimensions

  alarm_description = "Alarm for EC2 Disk Utilization for Instance ${each.key}"
  alarm_actions     = [var.alarm_action_arn]
  ok_actions        = [var.alarm_action_arn]
}


# Alarme para [EC2] StatusCheckFailed
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  for_each = toset(data.aws_instances.existing.ids)

  alarm_name          = "${upper(var.customer_name)}-${upper(data.aws_instance.detailed[each.key].tags["Name"])}"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1 # Status check falhado
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = each.value
  }

  alarm_description = "Alarm for EC2 Status Check Failed for Instance ${each.value}"
  alarm_actions     = [var.alarm_action_arn]
  ok_actions        = [var.alarm_action_arn] # Ação quando o valor voltar a OK
}

# Alarme para [EC2] StatusCheckFailed
resource "aws_cloudwatch_metric_alarm" "ec2_status_check_ebs" {
  for_each = toset(data.aws_instances.existing.ids)

  alarm_name          = "${upper(var.customer_name)}-${upper(data.aws_instance.detailed[each.key].tags["Name"])}-EBS_FAILED"
  metric_name         = "StatusCheckFailed_AttachedEBS"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = each.value
  }

  alarm_description = "Alarm for EC2 Status Check EBS Failed for Instance ${each.value}"
  alarm_actions     = [var.alarm_action_arn]
  ok_actions        = [var.alarm_action_arn] # Ação quando o valor voltar a OK
}
