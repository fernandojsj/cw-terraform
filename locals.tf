locals {
  # Região efetiva (usa variável ou detecta automaticamente)
  effective_region = var.aws_region != null ? var.aws_region : data.aws_region.current.name
  
  # RDS data processing
  rds_result = data.external.RDS.result

  RDS = {
    rds_list        = length(local.rds_result["RDS"]) > 0 && local.rds_result["RDS"] != "" ? jsondecode(local.rds_result["RDS"]) : []
    t_instance_list = length(local.rds_result["T_instances"]) > 0 && local.rds_result["T_instances"] != "" ? jsondecode(local.rds_result["T_instances"]) : []
  }

  # Aurora data processing
  aurora_result = data.external.Aurora.result

  Aurora = {
    provisioned   = length(local.aurora_result["aurora_provisioned"]) > 0 && local.aurora_result["aurora_provisioned"] != "" ? jsondecode(local.aurora_result["aurora_provisioned"]) : []
    serverless_v1 = length(local.aurora_result["aurora_serverless_v1"]) > 0 && local.aurora_result["aurora_serverless_v1"] != "" ? jsondecode(local.aurora_result["aurora_serverless_v1"]) : []
    serverless_v2 = length(local.aurora_result["aurora_serverless_v2"]) > 0 && local.aurora_result["aurora_serverless_v2"] != "" ? jsondecode(local.aurora_result["aurora_serverless_v2"]) : []
  }

  # Target groups mapping
  alb_target_groups = {
    for lb_name, _ in data.aws_lb.application_lb :
    lb_name => [
      for tg_arn in split(",", lookup(data.external.Map_of_targetGroups.result, lb_name, "")) :
      "targetgroup/${join("/", slice(split("/", tg_arn), 1, 3))}"
      if startswith(tg_arn, "arn:aws:elasticloadbalancing")
    ]
  }

  nlb_target_groups = {
    for lb_name, _ in data.aws_lb.network_lb :
    lb_name => [
      for tg_arn in split(",", lookup(data.external.Map_of_targetGroups.result, lb_name, "")) :
      "targetgroup/${join("/", slice(split("/", tg_arn), 1, 3))}"
      if startswith(tg_arn, "arn:aws:elasticloadbalancing")
    ]
  }

  # Layout calculations
  alb_block_height                  = length(data.aws_lb.application_lb) * 8
  nlb_block_height                  = length(data.aws_lb.network_lb) * 8
  ec2_block_height                  = length(data.aws_instances.existing.ids) * 7
  rds_block_height                  = length(local.RDS.rds_list) * 14
  rds_t_block_height                = length(local.RDS.t_instance_list) * 14
  aurora_provisioned_block_height   = length(local.Aurora.provisioned) * 14
  aurora_serverless_v1_block_height = length(local.Aurora.serverless_v1) * 10
  aurora_serverless_v2_block_height = length(local.Aurora.serverless_v2) * 14

  alb_offset                    = 1
  nlb_header_y                  = local.alb_offset + local.alb_block_height
  ec2_header_y                  = local.nlb_header_y + 1 + local.nlb_block_height
  rds_header_y                  = local.ec2_header_y + 1 + local.ec2_block_height
  rds_t_header_y                = local.rds_header_y + local.rds_block_height + 4
  aurora_provisioned_header_y   = local.rds_t_header_y + local.rds_t_block_height + 4
  aurora_serverless_v1_header_y = local.aurora_provisioned_header_y + local.aurora_provisioned_block_height + 4
  aurora_serverless_v2_header_y = local.aurora_serverless_v1_header_y + local.aurora_serverless_v1_block_height + 4

  # Instance configurations
  ec2_instances_credit = {
    "t2.nano"  = 72, "t2.micro" = 144, "t2.small" = 288, "t2.medium" = 576, "t2.large" = 864, "t2.xlarge" = 1296, "t2.2xlarge" = 1958.4,
    "t3.nano"  = 144, "t3.micro" = 288, "t3.small" = 576, "t3.medium" = 576, "t3.large" = 864, "t3.xlarge" = 2304, "t3.2xlarge" = 4608,
    "t3a.nano" = 144, "t3a.micro" = 288, "t3a.small" = 576, "t3a.medium" = 576, "t3a.large" = 864, "t3a.xlarge" = 2304, "t3a.2xlarge" = 4608,
    "t4g.nano" = 144, "t4g.micro" = 288, "t4g.small" = 576, "t4g.medium" = 576, "t4g.large" = 864, "t4g.xlarge" = 2304, "t4g.2xlarge" = 4608
  }

  rds_instances_credit = {
    "db.t2.micro"  = 144,
    "db.t2.small"  = 288,
    "db.t2.medium" = 576,

    "db.t3.micro"   = 288,
    "db.t3.small"   = 576,
    "db.t3.medium"  = 576,
    "db.t3.large"   = 864,
    "db.t3.xlarge"  = 2304,
    "db.t3.2xlarge" = 4608,

    "db.t4g.micro"   = 288,
    "db.t4g.small"   = 576,
    "db.t4g.medium"  = 576,
    "db.t4g.large"   = 864,
    "db.t4g.xlarge"  = 2304,
    "db.t4g.2xlarge" = 4608
  }

  db_instance_memory = {
    "db.t3.micro"    = 1, "db.t3.small" = 2, "db.t3.medium" = 4, "db.t3.large" = 8, "db.t3.xlarge" = 16, "db.t3.2xlarge" = 32,
    "db.t4g.micro"   = 1, "db.t4g.small" = 2, "db.t4g.medium" = 4, "db.t4g.large" = 8, "db.t4g.xlarge" = 16, "db.t4g.2xlarge" = 32,
    "db.m5.large"    = 8, "db.m5.xlarge" = 16, "db.m5.2xlarge" = 32, "db.m5.4xlarge" = 64, "db.m5.8xlarge" = 128, "db.m5.12xlarge" = 192, "db.m5.16xlarge" = 256, "db.m5.24xlarge" = 384,
    "db.m6g.large"   = 8, "db.m6g.xlarge" = 16, "db.m6g.2xlarge" = 32, "db.m6g.4xlarge" = 64, "db.m6g.8xlarge" = 128, "db.m6g.12xlarge" = 192, "db.m6g.16xlarge" = 256,
    "db.r5.large"    = 16, "db.r5.xlarge" = 32, "db.r5.2xlarge" = 64, "db.r5.4xlarge" = 128, "db.r5.8xlarge" = 256, "db.r5.12xlarge" = 384, "db.r5.16xlarge" = 512, "db.r5.24xlarge" = 768,
    "db.r6g.large"   = 16, "db.r6g.xlarge" = 32, "db.r6g.2xlarge" = 64, "db.r6g.4xlarge" = 128, "db.r6g.8xlarge" = 256, "db.r6g.12xlarge" = 384, "db.r6g.16xlarge" = 512,
    "db.x1.16xlarge" = 976, "db.x1.32xlarge" = 1952,
    "db.x2g.medium"  = 16, "db.x2g.large" = 32, "db.x2g.xlarge" = 64, "db.x2g.2xlarge" = 128, "db.x2g.4xlarge" = 256, "db.x2g.8xlarge" = 512, "db.x2g.12xlarge" = 768, "db.x2g.16xlarge" = 1024,
    "db.m7g.large"   = 8, "db.m7g.xlarge" = 16, "db.m7g.2xlarge" = 32, "db.m7g.4xlarge" = 64, "db.m7g.8xlarge" = 128, "db.m7g.12xlarge" = 192, "db.m7g.16xlarge" = 256,
    "db.r7g.large"   = 16, "db.r7g.xlarge" = 32, "db.r7g.2xlarge" = 64, "db.r7g.4xlarge" = 128, "db.r7g.8xlarge" = 256, "db.r7g.12xlarge" = 384, "db.r7g.16xlarge" = 512
  }

  t_instance_max_connections = {
    for inst in local.RDS.t_instance_list :
    inst["id"] => floor(inst["max_connections"] * 0.8)
  }

  std_instance_max_connections = {
    for inst in local.RDS.rds_list :
    inst["id"] => floor(inst["max_connections"] * 0.8)
  }

  # Alarm configurations
  alb_map = { for index, alb in data.aws_lb.application_lb : "alb_${index}" => alb.arn_suffix }

  mem_metrics = {
    for instance_id in data.aws_instances.existing.ids :
    instance_id => lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? {
      name = "Memory % Committed Bytes In Use"
      dimensions = {
        InstanceId   = instance_id
        ImageId      = data.aws_instance.detailed[instance_id].ami
        InstanceType = data.aws_instance.detailed[instance_id].instance_type
        objectname   = "Memory"
      }
      } : {
      name = "mem_used_percent"
      dimensions = {
        InstanceId   = instance_id
        ImageId      = data.aws_instance.detailed[instance_id].ami
        InstanceType = data.aws_instance.detailed[instance_id].instance_type
      }
    }
  }

  disk_metrics = {
    for instance_id in data.aws_instances.existing.ids :
    instance_id => lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? {
      name      = "LogicalDisk % Free Space"
      threshold = 20
      dimensions = {
        InstanceId   = instance_id
        ImageId      = data.aws_instance.detailed[instance_id].ami
        InstanceType = data.aws_instance.detailed[instance_id].instance_type
        objectname   = "LogicalDisk"
        instance     = "C:"
      }
      } : {
      name      = "disk_used_percent"
      threshold = 80
      dimensions = {
        InstanceId   = instance_id
        ImageId      = data.aws_instance.detailed[instance_id].ami
        InstanceType = data.aws_instance.detailed[instance_id].instance_type
        path         = "/"
        device       = "nvme0n1p1"
        fstype       = "ext4"
      }
    }
  }
}