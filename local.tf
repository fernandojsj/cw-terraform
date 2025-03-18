locals {
  map_of_rds = {
    aurora_list            = split(", ", data.external.RDS.result["Aurora_list"])
    rds_list               = split(", ", data.external.RDS.result["RDS"])
    aurora_serverless_list = split(", ", data.external.RDS.result["Aurora_serverless_list"])
  }
  alb_target_groups = {
    for lb_name, _ in data.aws_lb.application_lb :
    lb_name => [
      for tg_arn in split(",", lookup(data.external.Map_of_targetGroups.result, lb_name, "")) :
      "targetgroup/${join("/", slice(split("/", tg_arn), 1, 3))}" # Extrai somente `targetgroup/{nome}/{id}`
      if startswith(tg_arn, "arn:aws:elasticloadbalancing")
    ]
  }
  nlb_target_groups = {
    for lb_name, _ in data.aws_lb.network_lb :
    lb_name => [
      for tg_arn in split(",", lookup(data.external.Map_of_targetGroups.result, lb_name, "")) :
      "targetgroup/${join("/", slice(split("/", tg_arn), 1, 3))}" # Extrai somente `targetgroup/{nome}/{id}`
      if startswith(tg_arn, "arn:aws:elasticloadbalancing")
    ]
  }
}

locals {
  # Alturas de cada seção
  alb_block_height = length(data.aws_lb.application_lb) * 8
  nlb_block_height = length(data.aws_lb.network_lb) * 8
  ec2_block_height = length(data.aws_instances.existing.ids) * 7
  # Se cada RDS ocupar 14 unidades de altura:
  rds_block_height = length(local.map_of_rds.rds_list) * 14

  # Offsets (posição Y inicial de cada seção)
  alb_offset     = 1                                               # ALB: logo abaixo do cabeçalho do dashboard
  nlb_header_y   = local.alb_offset + local.alb_block_height       # Cabeçalho NLB logo após ALB
  ec2_header_y   = local.nlb_header_y + 1 + local.nlb_block_height # Cabeçalho EC2 após NLB (1 linha para o título)
  rds_header_y   = local.ec2_header_y + 1 + local.ec2_block_height # Cabeçalho RDS após EC2
  rds_t_header_y = local.rds_header_y + length(local.RDS.rds_list) * 14 + 4
}

locals {
  result = data.external.RDS

  RDS = {
    rds_list               = length(local.result.result["RDS"]) > 0 && local.result.result["RDS"] != "" ? split(", ", local.result.result["RDS"]) : []
    rds_without_t_list     = length(local.result.result["RDS"]) > 0 && local.result.result["RDS"] != "" ? split(", ", local.result.result["RDS"]) : []
    aurora_list            = length(local.result.result["Aurora_list"]) > 0 && local.result.result["Aurora_list"] != "" ? split(", ", local.result.result["Aurora_list"]) : []
    aurora_serverless_list = length(local.result.result["Aurora_serverless_list"]) > 0 && local.result.result["Aurora_serverless_list"] != "" ? split(", ", local.result.result["Aurora_serverless_list"]) : []
    t_instance_list = (
      length(local.result.result["T_instances"]) > 0 && local.result.result["T_instances"] != ""
    ) ? jsondecode(local.result.result["T_instances"]) : []
  }

  t_instance_max_connections = {
    for inst in local.RDS.t_instance_list :
    inst["id"] => floor(inst["max_connections"] * 0.8) # Aplica 80% do max_connections
  }
}

locals {
  ec2_instances_credit = {
    "t2.nano"     = 144
    "t2.micro"    = 144
    "t2.small"    = 288
    "t2.medium"   = 576
    "t2.large"    = 864
    "t2.xlarge"   = 1296
    "t2.2xlarge"  = 1958.4
    "t3.nano"     = 144
    "t3.micro"    = 288
    "t3.small"    = 576
    "t3.medium"   = 576
    "t3.large"    = 864
    "t3.xlarge"   = 2304
    "t3.2xlarge"  = 4608
    "t3a.nano"    = 144
    "t3a.micro"   = 288
    "t3a.small"   = 576
    "t3a.medium"  = 576
    "t3a.large"   = 864
    "t3a.xlarge"  = 2304
    "t3a.2xlarge" = 4608
    "t4g.nano"    = 144
    "t4g.micro"   = 288
    "t4g.small"   = 576
    "t4g.medium"  = 576
    "t4g.large"   = 864
    "t4g.xlarge"  = 2304
    "t4g.2xlarge" = 4608
  }

  rds_instances_credit = {
    "db.t2.micro"    = 144
    "db.t2.small"    = 288
    "db.t2.medium"   = 576
    "db.t3.micro"    = 144
    "db.t3.small"    = 288
    "db.t3.medium"   = 576
    "db.t3.large"    = 864
    "db.t3.xlarge"   = 2304
    "db.t3.2xlarge"  = 4608
    "db.t4g.micro"   = 144
    "db.t4g.small"   = 288
    "db.t4g.medium"  = 576
    "db.t4g.large"   = 864
    "db.t4g.xlarge"  = 2304
    "db.t4g.2xlarge" = 4608
  }
}

locals {
  # Widgets de Application LB (ALB)
  application_lb_widgets = flatten([
    for lb_name, alb in data.aws_lb.application_lb : [
      {
        type   = "text"
        x      = 0
        y      = local.alb_offset + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${lb_name}\n\n[button:primary:${lb_name}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#LoadBalancer:loadBalancerName=${alb.name})"
          background = "transparent"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = local.alb_offset + 2 + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 6
        height = 6
        properties = {
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4))]]
          view    = "timeSeries"
          stat    = "Sum"
          region  = data.aws_region.current.name
          period  = 60
          title   = "[ALB] RequestCount"
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = local.alb_offset + 2 + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 6
        height = 6
        properties = {
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4))]]
          view    = "timeSeries"
          stat    = "Average"
          region  = data.aws_region.current.name
          period  = 60
          title   = "[ALB] Latency"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = local.alb_offset + 2 + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4)), { "id" : "m1", "visible" : false }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4)), { "id" : "m2", "visible" : false }],
            [{ "expression" : "IF(m1 > 0, 100*(m2/m1), 0)", "label" : "5xx_Percent", "id" : "e1" }]
          ]
          view   = "timeSeries"
          stat   = "Sum"
          region = data.aws_region.current.name
          period = 300
          title  = "[ALB] 5xx Error"
          yAxis  = { left = { min = 0, max = 25 } }
          annotations = {
            horizontal = [
              {
                color = "#ff0000"
                label = "Alert"
                value = 5
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = local.alb_offset + 2 + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            for tg_arn in local.alb_target_groups[lb_name] : [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup", tg_arn,
              "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4))
            ]
          ],
          view   = "bar",
          stat   = "Maximum",
          region = data.aws_region.current.name,
          period = 60,
          title  = "[ALB] HealthyHost"
        }
      }
    ]
  ])

  # Widgets de Network LB (NLB)
  network_lb_widgets = flatten([
    for nlb_name, nlb in data.aws_lb.network_lb : [
      {
        type   = "text"
        x      = 0
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${nlb.name}\n\n[button:primary:${nlb.name}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#LoadBalancer:loadBalancerName=${nlb.name})"
          background = "transparent"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 5
        height = 6
        properties = {
          title   = "[NLB] New Flow Count"
          region  = data.aws_region.current.name
          metrics = [["AWS/NetworkELB", "NewFlowCount", "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4))]]
          stat    = "Maximum"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 5
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 5
        height = 6
        properties = {
          title   = "[NLB] Active Flow Count"
          region  = data.aws_region.current.name
          metrics = [["AWS/NetworkELB", "ActiveFlowCount", "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4))]]
          stat    = "Sum"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 5
        height = 6
        properties = {
          title   = "[NLB] ConsumedLCUs"
          region  = data.aws_region.current.name
          metrics = [["AWS/NetworkELB", "ConsumedLCUs", "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4))]]
          stat    = "Maximum"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 15
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 5
        height = 6
        properties = {
          title   = "[NLB] Processed Packets"
          region  = data.aws_region.current.name
          metrics = [["AWS/NetworkELB", "ProcessedPackets", "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4))]]
          stat    = "Sum"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 20
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 4
        height = 6
        properties = {
          title  = "[NLB] HealthyHostCount"
          region = data.aws_region.current.name
          metrics = [
            for tg_arn in local.nlb_target_groups[nlb_name] : [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup", tg_arn,
              "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4))
            ]
          ],
          stat   = "Sum",
          period = 60
        }
      },
    ]
  ])

  # Widgets de EC2
  ec2_widgets = flatten([
    for i, instance_id in tolist(data.aws_instances.existing.ids) : concat(
      [
        {
          type   = "text"
          x      = 0
          y      = local.ec2_header_y + 1 + i * 7
          width  = 24
          height = 2
          properties = {
            markdown   = "## ${lookup(data.aws_instance.detailed[instance_id].tags, "Name", instance_id)}\n[button:primary:${lookup(data.aws_instance.detailed[instance_id].tags, "Name", instance_id)}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#InstanceDetails:instanceId=${instance_id})"
            background = "transparent"
          }
        }
      ],
      !startswith(data.aws_instance.detailed[instance_id].instance_type, "t") ? [
        {
          type   = "metric"
          x      = 0
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title   = "[EC2] CPU Utilization"
            region  = data.aws_region.current.name
            metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", instance_id]]
            stat    = "Maximum"
            period  = 60
            yAxis   = { left = { min = 0, max = 100 } }
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = 80
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 4
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Memory Utilization"
            region = data.aws_region.current.name
            metrics = lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? [
      ["CWAgent", "Memory % Committed Bytes In Use", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "objectname", "Memory", "InstanceType", data.aws_instance.detailed[instance_id].instance_type]
    ] : [
      ["CWAgent", "mem_used_percent", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type]
    ]
            stat   = "Maximum"
            period = 60
            yAxis  = { left = { min = 0, max = 100 } }
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = 80
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 8
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Disk Utilization"
            region = data.aws_region.current.name
 metrics = lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? [
      ["CWAgent", "LogicalDisk % Free Space", "instance", "C:", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "objectname", "LogicalDisk", "InstanceType", data.aws_instance.detailed[instance_id].instance_type]
    ] : [
      ["CWAgent", "disk_used_percent", "path", "/", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type, "device", "nvme0n1p1", "fstype", "ext4"]
    ]

            stat   = "Maximum"
            period = 60
            yAxis  = { left = { min = 0, max = 100 } }
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? 20 : 80
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Network In/Out"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "NetworkIn", "InstanceId", instance_id],
              ["AWS/EC2", "NetworkOut", "InstanceId", instance_id]
            ]
            stat   = "Maximum"
            period = 60
            annotations = {
            }
          }
        },
        {
          type   = "metric"
          x      = 16
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Status Check"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "StatusCheckFailed", "InstanceId", instance_id]
            ]
            stat   = "Maximum"
            period = 60
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = 1
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 20
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Status Check EBS"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "StatusCheckFailed_AttachedEBS", "InstanceId", instance_id]
            ]
            stat   = "Maximum"
            period = 60
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = 1
                }
              ]
            }
          }
        }
      ]
      :
      [
        {
          type   = "metric"
          x      = 0
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title   = "[EC2] CPU Utilization"
            region  = data.aws_region.current.name
            metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", instance_id]]
            stat    = "Maximum"
            period  = 60
            yAxis   = { left = { min = 0, max = 100 } }
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = 80
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 4
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Memory Utilization"
            region = data.aws_region.current.name
           metrics = lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? [
      ["CWAgent", "Memory % Committed Bytes In Use", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "objectname", "Memory", "InstanceType", data.aws_instance.detailed[instance_id].instance_type]
    ] : [
      ["CWAgent", "mem_used_percent", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type]
    ]
            stat   = "Maximum"
            period = 60
            yAxis  = { left = { min = 0, max = 100 } }
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = 80
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 8
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Disk Utilization"
            region = data.aws_region.current.name
            metrics = lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? [
      ["CWAgent", "LogicalDisk % Free Space", "instance", "C:", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "objectname", "LogicalDisk", "InstanceType", data.aws_instance.detailed[instance_id].instance_type]
    ] : [
      ["CWAgent", "disk_used_percent", "path", "/", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type, "device", "nvme0n1p1", "fstype", "ext4"]
    ]

            stat   = "Maximum"
            period = 60
            yAxis  = { left = { min = 0, max = 100 } }
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? 20 : 80
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Credit Utilization"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "CPUCreditUsage", "InstanceId", instance_id],
              ["AWS/EC2", "CPUCreditBalance", "InstanceId", instance_id]
            ]
            stat   = "Maximum"
            period = 60
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = floor(lookup(local.ec2_instances_credit, data.aws_instance.detailed[instance_id].instance_type, 0) * 0.4)
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 16
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Network In/Out"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "NetworkIn", "InstanceId", instance_id],
              ["AWS/EC2", "NetworkOut", "InstanceId", instance_id]
            ]
            stat   = "Maximum"
            period = 60
            annotations = {
            }
          }
        },
        {
          type   = "metric"
          x      = 20
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Status Check Failed"
            region = data.aws_region.current.name
            metrics = [
              ["AWS/EC2", "StatusCheckFailed", "InstanceId", instance_id],
              ["AWS/EC2", "StatusCheckFailed_AttachedEBS", "InstanceId", instance_id]
            ]
            stat   = "Maximum"
            period = 60
            annotations = {
              horizontal = [
                {
                  color = "#ff0000"
                  label = "Alert"
                  value = 1
                }
              ]
            }
          }
        }
      ]
    )
  ])

  # Widgets de RDS
  rds_widgets = concat(
    // Primeiro grupo: local.RDS.t_instance_list
    flatten([
      for i, rds_instance in tolist(local.RDS.t_instance_list) : concat(
        [
          // Cabeçalho da instância
          {
            type   = "text"
            x      = 0
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 24
            height = 2
            properties = {
              markdown   = "## ${rds_instance.id}\n[button:primary:${rds_instance.id}](https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${rds_instance.id})"
              background = "transparent"
            }
          }
        ],
        [
          // CPU Utilization
          {
            type   = "metric"
            x      = 0
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", rds_instance.id]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] CPU Utilization"
              yAxis   = { left = { min = 0, max = 100 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = 80
                  }
                ]
              }
            }
          },
          // Memory Utilization
          {
            type   = "metric"
            x      = 4
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", rds_instance.id]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] Memory Utilization"
              yAxis   = { left = { min = 0, max = 100 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = 80
                  }
                ]
              }
            }
          },
          // Disk Utilization
          {
            type   = "metric"
            x      = 8
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", rds_instance.id]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] Disk Utilization"
              yAxis   = { left = { min = 0, max = 100 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = 90
                  }
                ]
              }
            }
          },
          // Credit Usage
          {
            type   = "metric"
            x      = 12
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              title = "[RDS] Credit Usage"
              metrics = [
                ["AWS/RDS", "CPUCreditBalance", "DBInstanceIdentifier", rds_instance.id],
                ["AWS/RDS", "CPUCreditUsage", "DBInstanceIdentifier", rds_instance.id]
              ]
              view   = "timeSeries"
              stat   = "Average"
              region = data.aws_region.current.name
              period = 60
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = floor(lookup(local.rds_instances_credit, rds_instance.type, 0) * 0.4)
                  }
                ]
              }
            }
          },
          // Write/Read IOPS
          {
            type   = "metric"
            x      = 16
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [
                ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", rds_instance.id],
                ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", rds_instance.id]
              ]
              view   = "timeSeries"
              stat   = "Average"
              region = data.aws_region.current.name
              period = 60
              title  = "[RDS] Write/Read IOPS"
            }
          },
          // DB Connections
          {
            type   = "metric"
            x      = 20
            y      = local.rds_t_header_y + 1 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", rds_instance.id]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] DB Connections"
              annotations = {
                horizontal = [
                  {
                    label = "Alert"
                    value = local.t_instance_max_connections[rds_instance.id]
                    color = "#FF0000"
                  }
                ]
              }
            }
          }
        ]
      )
    ]),
    // Segundo grupo: local.RDS.rds_list
    flatten([
      for i, rds_instance in tolist(local.RDS.rds_without_t_list) : concat(
        [
          // Cabeçalho da instância
          {
            type   = "text"
            x      = 0
            y      = local.rds_header_y + 3 + i * 14
            width  = 24
            height = 2
            properties = {
              markdown   = "## ${rds_instance}\n[button:primary:${rds_instance}](https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${rds_instance})"
              background = "transparent"
            }
          }
        ],
        [
          // CPU Utilization
          {
            type   = "metric"
            x      = 0
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", rds_instance]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] CPU Utilization"
              yAxis   = { left = { min = 0, max = 100 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = 80
                  }
                ]
              }
            }
          },
          // Memory Utilization
          {
            type   = "metric"
            x      = 4
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", rds_instance]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] Memory Utilization"
              yAxis   = { left = { min = 0, max = 100 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = 80
                  }
                ]
              }
            }
          },
          // Disk Utilization
          {
            type   = "metric"
            x      = 8
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", rds_instance]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] Disk Utilization"
              yAxis   = { left = { min = 0, max = 100 } }
              annotations = {
                horizontal = [
                  {
                    color = "#ff0000"
                    label = "Alert"
                    value = 90
                  }
                ]
              }
            }
          },
          // DB Connections
          {
            type   = "metric"
            x      = 12
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", rds_instance]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] DB Connections"
              annotations = {
                horizontal = [
                  {
                    label = "Alert"
                    value = local.t_instance_max_connections[rds_instance]
                    color = "#FF0000"
                  }
                ]
              }
            }
          },
          // WriteIOPS
          {
            type   = "metric"
            x      = 16
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", rds_instance]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] WriteIOPS"
            }
          },
          // ReadIOPS
          {
            type   = "metric"
            x      = 20
            y      = local.rds_header_y + 3 + i * 14
            width  = 4
            height = 6
            properties = {
              metrics = [["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", rds_instance]]
              view    = "timeSeries"
              stat    = "Average"
              region  = data.aws_region.current.name
              period  = 60
              title   = "[RDS] ReadIOPS"
            }
          }
        ]
      )
    ])
  )
}