output "dashboard_name" {
  description = "Nome do dashboard CloudWatch criado"
  value       = aws_cloudwatch_dashboard.monitoring_dashboard.dashboard_name
}

output "dashboard_url" {
  description = "URL do dashboard no console AWS"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.monitoring_dashboard.dashboard_name}"
}

output "monitored_resources" {
  description = "Resumo dos recursos monitorados"
  value = {
    alb_count                = length(data.aws_lb.application_lb)
    nlb_count                = length(data.aws_lb.network_lb)
    ec2_count                = length(data.aws_instances.existing.ids)
    rds_count                = length(local.RDS.rds_list)
    rds_t_count              = length(local.RDS.t_instance_list)
    aurora_provisioned_count = length(local.Aurora.provisioned)
    aurora_serverless_v1_count = length(local.Aurora.serverless_v1)
    aurora_serverless_v2_count = length(local.Aurora.serverless_v2)
  }
}
