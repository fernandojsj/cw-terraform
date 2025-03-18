# output "rds_without_t_list" {
#   value = local.RDS.rds_without_t_list
# }

# output "t_instance_list" {
#   value = local.RDS.t_instance_list
# }

output "RDS-local" {
  value = local.RDS
}

output "existing_instance_ids" {
  value = data.aws_instances.existing.ids
}

# output "existing_instance_amis" {
#   value = data.aws_instances.existing.existing_instance_amis
# }

output "load_balancers" {
  value = data.external.load_balancers.result
}
