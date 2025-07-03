# ALB 5XX Error Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx_error" {
  for_each = var.alarm_action_arn != null ? local.alb_map : {}

  alarm_name                = "${upper(var.customer_name)}_${upper(var.environment)}_ALB_${upper(each.key)}_5XX-STATUS-HIGH"
  alarm_description         = "CRITICAL"
  actions_enabled           = true
  alarm_actions             = [var.alarm_action_arn]
  ok_actions                = [var.alarm_action_arn]
  insufficient_data_actions = []
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  threshold                 = 5
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  treat_missing_data        = "missing"

  metric_query {
    id          = "m1"
    return_data = false
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = 60
      stat        = "Sum"
      dimensions  = { LoadBalancer = each.value }
    }
  }

  metric_query {
    id          = "m2"
    return_data = false
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      period      = 60
      stat        = "Sum"
      dimensions  = { LoadBalancer = each.value }
    }
  }

  metric_query {
    id          = "e1"
    label       = "5xx_Percent"
    return_data = true
    expression  = "IF(m1 > 0, 100*(m2/m1), 0)"
  }
}

# EC2 CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_utilization" {
  for_each = var.alarm_action_arn != null ? toset(data.aws_instances.existing.ids) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_CPU-HIGH"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { InstanceId = each.value }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.alarm_action_arn]
  ok_actions          = [var.alarm_action_arn]
}

# EC2 Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_mem_utilization" {
  for_each = var.alarm_action_arn != null ? local.mem_metrics : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_MEM-HIGH"
  namespace           = "CWAgent"
  metric_name         = each.value.name
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = each.value.dimensions
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.alarm_action_arn]
  ok_actions          = [var.alarm_action_arn]
}

# EC2 Disk Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_disk_utilization" {
  for_each = var.alarm_action_arn != null ? local.disk_metrics : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_DISK-HIGH"
  namespace           = "CWAgent"
  metric_name         = each.value.name
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = each.value.threshold
  comparison_operator = each.value.name == "LogicalDisk % Free Space" ? "LessThanOrEqualToThreshold" : "GreaterThanOrEqualToThreshold"
  dimensions          = each.value.dimensions
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.alarm_action_arn]
  ok_actions          = [var.alarm_action_arn]
}

# EC2 Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  for_each = var.alarm_action_arn != null ? toset(data.aws_instances.existing.ids) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_STATUS-CHECK"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { InstanceId = each.value }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.alarm_action_arn]
  ok_actions          = [var.alarm_action_arn]
}

# EC2 EBS Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_status_check_ebs" {
  for_each = var.alarm_action_arn != null ? toset(data.aws_instances.existing.ids) : []

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_EBS-FAILED"
  metric_name         = "StatusCheckFailed_AttachedEBS"
  namespace           = "AWS/EC2"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { InstanceId = each.value }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.alarm_action_arn]
  ok_actions          = [var.alarm_action_arn]
}

# EC2 Credit Balance Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_credit_balance" {
  for_each = var.alarm_action_arn != null ? {
    for id in data.aws_instances.existing.ids : id => id
    if contains(keys(local.ec2_instances_credit), data.aws_instance.detailed[id].instance_type)
  } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_EC2_${upper(data.aws_instance.detailed[each.key].tags["Name"])}_CREDIT-USAGE"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/EC2"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 1
  threshold           = floor(lookup(local.ec2_instances_credit, data.aws_instance.detailed[each.key].instance_type, 0) * 0.5) # 50% dos créditos
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "missing"
  dimensions          = { InstanceId = each.value }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.alarm_action_arn]
  ok_actions          = [var.alarm_action_arn]
}

# RDS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  for_each = (var.rds_alarm_action_arn != null || var.alarm_action_arn != null) ? { for idx, rds in local.RDS.t_instance_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_RDS_${upper(each.value.id)}_CPU-HIGH"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
  ok_actions          = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
}

# RDS Credit Balance Alarm
resource "aws_cloudwatch_metric_alarm" "rds_credit_balance" {
  for_each = (var.rds_alarm_action_arn != null || var.alarm_action_arn != null) ? { for idx, rds in local.RDS.t_instance_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_RDS_${upper(each.value.id)}_CREDIT-LOW"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/RDS"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 1
  threshold           = floor(lookup(local.rds_instances_credit, each.value.type, 0) * 0.5) # 50% dos créditos
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "missing"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
  ok_actions          = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
}

# RDS Memory Alarm
resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  for_each = (var.rds_alarm_action_arn != null || var.alarm_action_arn != null) ? { for idx, rds in local.RDS.t_instance_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name         = "${upper(var.customer_name)}_${upper(var.environment)}_RDS_${upper(each.value.id)}_MEM-LOW"
  metric_name        = "FreeableMemory"
  namespace          = "AWS/RDS"
  statistic          = "Minimum"
  period             = 60
  evaluation_periods = 1
  # Alerta quando memória livre for menor que 20% da memória total da instância
  threshold           = lookup(local.db_instance_memory, each.value.type, 1) * 1024 * 1024 * 1024 * 0.2 # 20% da memória em bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
  ok_actions          = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
}

# RDS Storage Alarm
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  for_each = (var.rds_alarm_action_arn != null || var.alarm_action_arn != null) ? { for idx, rds in local.RDS.t_instance_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name         = "${upper(var.customer_name)}_${upper(var.environment)}_RDS_${upper(each.value.id)}_STORAGE-LOW"
  metric_name        = "FreeStorageSpace"
  namespace          = "AWS/RDS"
  statistic          = "Minimum"
  period             = 60
  evaluation_periods = 1
  # Alerta quando espaço livre for menor que 20% do armazenamento total
  threshold           = each.value.allocated_storage_gb * 1024 * 1024 * 1024 * 0.2 # 20% do armazenamento em bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
  ok_actions          = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
}

# RDS Database Connections Alarm
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  for_each = (var.rds_alarm_action_arn != null || var.alarm_action_arn != null) ? { for idx, rds in local.RDS.t_instance_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_RDS_${upper(each.value.id)}_CONN-HIGH"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = local.t_instance_max_connections[each.value.id]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
  ok_actions          = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
}

# Alarmes para instâncias RDS não-T

# RDS CPU Utilization Alarm (não-T)
resource "aws_cloudwatch_metric_alarm" "rds_std_cpu_utilization" {
  for_each = (var.rds_alarm_action_arn != null || var.alarm_action_arn != null) ? { for idx, rds in local.RDS.rds_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_RDS_${upper(each.value.id)}_CPU-HIGH"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
  ok_actions          = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
}

# RDS Memory Alarm (não-T)
resource "aws_cloudwatch_metric_alarm" "rds_std_memory" {
  for_each = (var.rds_alarm_action_arn != null || var.alarm_action_arn != null) ? { for idx, rds in local.RDS.rds_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name         = "${upper(var.customer_name)}_${upper(var.environment)}_RDS_${upper(each.value.id)}_MEM-LOW"
  metric_name        = "FreeableMemory"
  namespace          = "AWS/RDS"
  statistic          = "Minimum"
  period             = 60
  evaluation_periods = 1
  # Alerta quando memória livre for menor que 20% da memória total da instância
  threshold           = lookup(local.db_instance_memory, each.value.type, 16) * 1024 * 1024 * 1024 * 0.2 # 20% da memória em bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
  ok_actions          = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
}

# RDS Storage Alarm (não-T)
resource "aws_cloudwatch_metric_alarm" "rds_std_storage" {
  for_each = (var.rds_alarm_action_arn != null || var.alarm_action_arn != null) ? { for idx, rds in local.RDS.rds_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name         = "${upper(var.customer_name)}_${upper(var.environment)}_RDS_${upper(each.value.id)}_STORAGE-LOW"
  metric_name        = "FreeStorageSpace"
  namespace          = "AWS/RDS"
  statistic          = "Minimum"
  period             = 60
  evaluation_periods = 1
  # Alerta quando espaço livre for menor que 20% do armazenamento total
  threshold           = each.value.allocated_storage_gb * 1024 * 1024 * 1024 * 0.2 # 20% do armazenamento em bytes
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
  ok_actions          = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
}

# RDS Database Connections Alarm (não-T)
resource "aws_cloudwatch_metric_alarm" "rds_std_connections" {
  for_each = (var.rds_alarm_action_arn != null || var.alarm_action_arn != null) ? { for idx, rds in local.RDS.rds_list : rds["id"] => rds if length(rds["id"]) > 0 } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_RDS_${upper(each.value.id)}_CONN-HIGH"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = local.std_instance_max_connections[each.value.id]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  dimensions          = { DBInstanceIdentifier = each.value.id }
  alarm_description   = "CRITICAL"
  alarm_actions       = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
  ok_actions          = [var.rds_alarm_action_arn != null ? var.rds_alarm_action_arn : var.alarm_action_arn]
}

# ECS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_utilization" {
  for_each = var.alarm_action_arn != null ? {
    for key, service in flatten([
      for cluster in concat(local.ECS.with_insights, local.ECS.without_insights) : [
        for svc in cluster.services : {
          cluster_name = cluster.name
          service_name = svc.name
          key         = "${cluster.name}-${svc.name}"
        }
      ]
    ]) : service.key => service
  } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_ECS_${upper(each.value.cluster_name)}_${upper(each.value.service_name)}_CPU-HIGH"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 90
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }
  alarm_description = "CRITICAL"
  alarm_actions     = [var.alarm_action_arn]
  ok_actions        = [var.alarm_action_arn]
}

# ECS Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_utilization" {
  for_each = var.alarm_action_arn != null ? {
    for key, service in flatten([
      for cluster in concat(local.ECS.with_insights, local.ECS.without_insights) : [
        for svc in cluster.services : {
          cluster_name = cluster.name
          service_name = svc.name
          key         = "${cluster.name}-${svc.name}"
        }
      ]
    ]) : service.key => service
  } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_ECS_${upper(each.value.cluster_name)}_${upper(each.value.service_name)}_MEM-HIGH"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 90
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }
  alarm_description = "CRITICAL"
  alarm_actions     = [var.alarm_action_arn]
  ok_actions        = [var.alarm_action_arn]
}

# ECS Running Tasks Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks" {
  for_each = var.alarm_action_arn != null ? {
    for key, service in flatten([
      for cluster in local.ECS.with_insights : [
        for svc in cluster.services : {
          cluster_name = cluster.name
          service_name = svc.name
          key         = "${cluster.name}-${svc.name}"
        }
      ]
    ]) : service.key => service
  } : {}

  alarm_name          = "${upper(var.customer_name)}_${upper(var.environment)}_ECS_${upper(each.value.cluster_name)}_${upper(each.value.service_name)}_TASKS-LOW"
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "LessThanOrEqualToThreshold"
  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }
  alarm_description = "CRITICAL"
  alarm_actions     = [var.alarm_action_arn]
  ok_actions        = [var.alarm_action_arn]
}