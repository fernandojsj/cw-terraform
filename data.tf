# ==========Região atual==========
data "aws_region" "current" {}


# ==========instâncias EC2==========
data "aws_instances" "existing" {

  filter {
    name   = "tag:OS"
    values = ["Windows", "Linux"]
  }
}

data "aws_instance" "detailed" {
  for_each    = toset(data.aws_instances.existing.ids)
  instance_id = each.value
}

# ==========application load balancers==========
data "external" "load_balancers" {
  program = ["python3", "./scripts/get_application_load_balancers.py"]
}
data "aws_lb" "application_lb" {
  for_each = toset(keys(data.external.load_balancers.result))
  name     = each.key
}


# ==========network load balancers==========
data "external" "network_load_balancers" {
  program = ["python3", "./scripts/get_network_load_balancers.py"]
}
data "aws_lb" "network_lb" {
  for_each = toset(keys(data.external.network_load_balancers.result))
  name     = each.key
}


# ==========target groups==========
data "external" "Map_of_targetGroups" {
  program = ["python3", "./scripts/get_target_groups.py"]
}


# =====RDS=====
data "external" "RDS" {
  program = ["python3", "./scripts/get_rds.py"]
}