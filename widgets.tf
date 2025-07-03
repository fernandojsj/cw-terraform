locals {
  # ALB Widgets
  application_lb_widgets = flatten([
    for lb_name, alb in data.aws_lb.application_lb : [
      {
        type   = "text"
        x      = 0
        y      = local.alb_offset + index(keys(data.aws_lb.application_lb), lb_name) * 8
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${lb_name}\n[button:primary:${lb_name}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#LoadBalancer:loadBalancerName=${lb_name})"
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
            horizontal = [{ color = "#ff0000", label = "Alert", value = 5 }]
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
              "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", tg_arn, "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4))
            ]
          ]
          view   = "bar"
          stat   = "Maximum"
          region = data.aws_region.current.name
          period = 60
          title  = "[ALB] HealthyHost"
        }
      }
    ]
  ])

  # NLB Widgets
  network_lb_widgets = flatten([
    for nlb_name, nlb in data.aws_lb.network_lb : [
      {
        type   = "text"
        x      = 0
        y      = local.nlb_header_y + 1 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${nlb_name}\n[button:primary:${nlb_name}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#LoadBalancer:loadBalancerName=${nlb_name})"
          background = "transparent"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = local.nlb_header_y + 3 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
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
        y      = local.nlb_header_y + 3 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
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
        y      = local.nlb_header_y + 3 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
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
        y      = local.nlb_header_y + 3 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
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
        y      = local.nlb_header_y + 3 + index(keys(data.aws_lb.network_lb), nlb_name) * 8
        width  = 4
        height = 6
        properties = {
          title  = "[NLB] HealthyHostCount"
          region = data.aws_region.current.name
          metrics = [
            for tg_arn in local.nlb_target_groups[nlb_name] : [
              "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", tg_arn, "LoadBalancer", join("/", slice(split("/", element(split(":", nlb.arn), 5)), 1, 4))
            ]
          ]
          stat   = "Sum"
          period = 60
        }
      }
    ]
  ])

  # EC2 Widgets
  ec2_widgets = flatten([
    for i, instance_id in tolist(data.aws_instances.existing.ids) : concat(
      [{
        type   = "text"
        x      = 0
        y      = local.ec2_header_y + 1 + i * 7
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${lookup(data.aws_instance.detailed[instance_id].tags, "Name", instance_id)}\n[button:primary:${lookup(data.aws_instance.detailed[instance_id].tags, "Name", instance_id)}](https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/home?region=${data.aws_region.current.name}#InstanceDetails:instanceId=${instance_id})"
          background = "transparent"
        }
      }],
      [
        {
          type   = "metric"
          x      = 0
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title       = "[EC2] CPU Utilization"
            region      = data.aws_region.current.name
            metrics     = [["AWS/EC2", "CPUUtilization", "InstanceId", instance_id]]
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 100 } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80 }] }
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
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 100 } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80 }] }
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
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 100 } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = lookup(data.aws_instance.detailed[instance_id].tags, "OS", "Linux") == "Windows" ? 20 : 80 }] }
          }
        },
        startswith(data.aws_instance.detailed[instance_id].instance_type, "t") ? {
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
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = lookup(local.ec2_instances_credit, data.aws_instance.detailed[instance_id].instance_type, 0) } }
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = floor(lookup(local.ec2_instances_credit, data.aws_instance.detailed[instance_id].instance_type, 0) * 0.5) }] }
          }
          } : {
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
            stat        = "Maximum"
            period      = 60
            yAxis       = { left = { min = 0, max = 1000 } }
            annotations = { horizontal = [] }
          }
        },
        {
          type   = "metric"
          x      = 16
          y      = local.ec2_header_y + 3 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = startswith(data.aws_instance.detailed[instance_id].instance_type, "t") ? "[EC2] Network In/Out" : "[EC2] Status Check"
            region = data.aws_region.current.name
            metrics = startswith(data.aws_instance.detailed[instance_id].instance_type, "t") ? [
              ["AWS/EC2", "NetworkIn", "InstanceId", instance_id],
              ["AWS/EC2", "NetworkOut", "InstanceId", instance_id]
              ] : [
              ["AWS/EC2", "StatusCheckFailed", "InstanceId", instance_id]
            ]
            stat        = "Maximum"
            period      = 60
            annotations = { horizontal = startswith(data.aws_instance.detailed[instance_id].instance_type, "t") ? [] : [{ color = "#ff0000", label = "Alert", value = 1 }] }
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
            metrics = startswith(data.aws_instance.detailed[instance_id].instance_type, "t") ? [
              ["AWS/EC2", "StatusCheckFailed", "InstanceId", instance_id],
              ["AWS/EC2", "StatusCheckFailed_AttachedEBS", "InstanceId", instance_id]
              ] : [
              ["AWS/EC2", "StatusCheckFailed_AttachedEBS", "InstanceId", instance_id]
            ]
            stat        = "Maximum"
            period      = 60
            annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 1 }] }
          }
        }
      ]
    )
  ])

  # RDS Widgets
  rds_widgets = concat(
    # RDS T-instance widgets
    flatten([
      for i, rds_instance in tolist(local.RDS.t_instance_list) : concat(
        [{
          type   = "text"
          x      = 0
          y      = local.rds_t_header_y + i * 14
          width  = 24
          height = 2
          properties = {
            markdown   = "## ${rds_instance.id}\n[button:primary:${rds_instance.id}](https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${rds_instance.id})"
            background = "transparent"
          }
        }],
        [
          {
            type   = "metric"
            x      = 0
            y      = local.rds_t_header_y + 2 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics     = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", rds_instance.id]]
              view        = "timeSeries"
              stat        = "Average"
              region      = data.aws_region.current.name
              period      = 60
              title       = "[RDS] CPU Utilization"
              yAxis       = { left = { min = 0, max = 100 } }
              annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80 }] }
            }
          },
          {
            type   = "metric"
            x      = 6
            y      = local.rds_t_header_y + 2 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics     = [["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", rds_instance.id]]
              view        = "timeSeries"
              stat        = "Minimum"
              region      = data.aws_region.current.name
              period      = 60
              title       = "[RDS] Free Memory"
              annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = lookup(local.db_instance_memory, rds_instance.type, 1) * 1073741824 * 0.2 }] } # 20% da memória em bytes
            }
          },
          {
            type   = "metric"
            x      = 12
            y      = local.rds_t_header_y + 2 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics     = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", rds_instance.id]]
              view        = "timeSeries"
              stat        = "Minimum"
              region      = data.aws_region.current.name
              period      = 60
              title       = "[RDS] Free Storage Space"
              annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 10737418240 }] } # 10GB em bytes
            }
          },
          {
            type   = "metric"
            x      = 18
            y      = local.rds_t_header_y + 2 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics = [
                ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", rds_instance.id],
                [".", "WriteLatency", ".", rds_instance.id]
              ]
              view   = "timeSeries"
              stat   = "Average"
              region = data.aws_region.current.name
              period = 60
              title  = "[RDS] Read/Write Latency"
            }
          },
          {
            type   = "metric"
            x      = 0
            y      = local.rds_t_header_y + 8 + i * 14
            width  = 6
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

              annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = floor(lookup(local.rds_instances_credit, rds_instance.type) / 2) }] } # 50% dos créditos
            }
          },
          {
            type   = "metric"
            x      = 6
            y      = local.rds_t_header_y + 8 + i * 14
            width  = 6
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
              title  = "[RDS] Read/Write IOPS"
            }
          },
          {
            type   = "metric"
            x      = 12
            y      = local.rds_t_header_y + 8 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics = [
                ["AWS/RDS", "WriteThroughput", "DBInstanceIdentifier", rds_instance.id],
                ["AWS/RDS", "ReadThroughput", "DBInstanceIdentifier", rds_instance.id]
              ]
              view   = "timeSeries"
              stat   = "Average"
              region = data.aws_region.current.name
              period = 60
              title  = "[RDS] Read/Write Throughput"
            }
          },
          {
            type   = "metric"
            x      = 18
            y      = local.rds_t_header_y + 8 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics     = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", rds_instance.id]]
              view        = "timeSeries"
              stat        = "Maximum"
              region      = data.aws_region.current.name
              period      = 60
              title       = "[RDS] DB Connections"
              yAxis       = { left = { min = 0, max = try(local.t_instance_max_connections[rds_instance.id], 100) } }
              annotations = { horizontal = [{ label = "Alert", value = try(floor(local.t_instance_max_connections[rds_instance.id] * 0.7), 70), color = "#FF0000" }] } # 70% das conexões máximas
            }
          }
        ]
      )
    ]),

    # RDS Standard Instance widgets
    flatten([
      for i, rds_instance in tolist(local.RDS.rds_list) : concat(
        [{
          type   = "text"
          x      = 0
          y      = local.rds_header_y + i * 14
          width  = 24
          height = 2
          properties = {
            markdown   = "## ${rds_instance.id}\n[button:primary:${rds_instance.id}](https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${rds_instance.id})"
            background = "transparent"
          }
        }],
        [
          {
            type   = "metric"
            x      = 0
            y      = local.rds_header_y + 2 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics     = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", rds_instance.id]]
              view        = "timeSeries"
              stat        = "Average"
              region      = data.aws_region.current.name
              period      = 60
              title       = "[RDS] CPU Utilization"
              yAxis       = { left = { min = 0, max = 100 } }
              annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 80 }] }
            }
          },
          {
            type   = "metric"
            x      = 6
            y      = local.rds_header_y + 2 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics     = [["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", rds_instance.id]]
              view        = "timeSeries"
              stat        = "Minimum"
              region      = data.aws_region.current.name
              period      = 60
              title       = "[RDS] Free Memory"
              annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = lookup(local.db_instance_memory, rds_instance.type, 1) * 1073741824 * 0.2 }] } # 20% da memória em bytes
            }
          },
          {
            type   = "metric"
            x      = 12
            y      = local.rds_header_y + 2 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics     = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", rds_instance.id]]
              view        = "timeSeries"
              stat        = "Minimum"
              region      = data.aws_region.current.name
              period      = 60
              title       = "[RDS] Free Storage Space"
              annotations = { horizontal = [{ color = "#ff0000", label = "Alert", value = 10737418240 }] } # 10GB em bytes
            }
          },
          {
            type   = "metric"
            x      = 18
            y      = local.rds_header_y + 2 + i * 14
            width  = 6
            height = 6
            properties = {
              metrics = [
                ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", rds_instance.id],
                [".", "WriteLatency", ".", rds_instance.id]
              ]
              view   = "timeSeries"
              stat   = "Average"
              region = data.aws_region.current.name
              period = 60
              title  = "[RDS] Read/Write Latency"
            }
          },
          {
            type   = "metric"
            x      = 0
            y      = local.rds_header_y + 8 + i * 14
            width  = 8
            height = 6
            properties = {
              metrics     = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", rds_instance.id]]
              view        = "timeSeries"
              stat        = "Maximum"
              region      = data.aws_region.current.name
              period      = 60
              title       = "[RDS] DB Connections"
              yAxis       = { left = { min = 0, max = try(local.std_instance_max_connections[rds_instance.id], 100) } }
              annotations = { horizontal = [{ label = "Alert", value = try(floor(local.std_instance_max_connections[rds_instance.id] * 0.7), 70), color = "#FF0000" }] } # 70% das conexões máximas
            }
          },
          {
            type   = "metric"
            x      = 8
            y      = local.rds_header_y + 8 + i * 14
            width  = 8
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
              title  = "[RDS] Read/Write IOPS"
            }
          },
          {
            type   = "metric"
            x      = 16
            y      = local.rds_header_y + 8 + i * 14
            width  = 8
            height = 6
            properties = {
              metrics = [
                ["AWS/RDS", "WriteThroughput", "DBInstanceIdentifier", rds_instance.id],
                ["AWS/RDS", "ReadThroughput", "DBInstanceIdentifier", rds_instance.id]
              ]
              view   = "timeSeries"
              stat   = "Average"
              region = data.aws_region.current.name
              period = 60
              title  = "[RDS] Read/Write Throughput"
            }
          }
        ]
      )
    ])
  )

  # Aurora Provisioned Widgets
  aurora_provisioned_widgets = flatten([
    for i, aurora_cluster in tolist(local.Aurora.provisioned) : concat(
      [{
        type   = "text"
        x      = 0
        y      = local.aurora_provisioned_header_y + i * 14
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${aurora_cluster.id} (Aurora Provisioned)\n[button:primary:${aurora_cluster.id}](https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${aurora_cluster.id})"
          background = "transparent"
        }
      }],
      [
        {
          type   = "metric"
          x      = 0
          y      = local.aurora_provisioned_header_y + 2 + i * 14
          width  = 6
          height = 6
          properties = {
            metrics = [["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Average"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora] CPU Utilization"
          }
        },
        {
          type   = "metric"
          x      = 6
          y      = local.aurora_provisioned_header_y + 2 + i * 14
          width  = 6
          height = 6
          properties = {
            metrics = [["AWS/RDS", "FreeableMemory", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Minimum"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora] Free Memory"
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = local.aurora_provisioned_header_y + 2 + i * 14
          width  = 6
          height = 6
          properties = {
            metrics = [["AWS/RDS", "FreeStorageSpace", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Minimum"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora] Free Storage Space"
          }
        },
        {
          type   = "metric"
          x      = 18
          y      = local.aurora_provisioned_header_y + 2 + i * 14
          width  = 6
          height = 6
          properties = {
            metrics = [
              ["AWS/RDS", "ReadLatency", "DBClusterIdentifier", aurora_cluster.id],
              [".", "WriteLatency", ".", aurora_cluster.id]
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[Aurora] Read/Write Latency"
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = local.aurora_provisioned_header_y + 8 + i * 14
          width  = 8
          height = 6
          properties = {
            metrics = [["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Maximum"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora] DB Connections"
          }
        },
        {
          type   = "metric"
          x      = 8
          y      = local.aurora_provisioned_header_y + 8 + i * 14
          width  = 8
          height = 6
          properties = {
            metrics = [
              ["AWS/RDS", "WriteIOPS", "DBClusterIdentifier", aurora_cluster.id],
              ["AWS/RDS", "ReadIOPS", "DBClusterIdentifier", aurora_cluster.id]
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[Aurora] Read/Write IOPS"
          }
        },
        {
          type   = "metric"
          x      = 16
          y      = local.aurora_provisioned_header_y + 8 + i * 14
          width  = 8
          height = 6
          properties = {
            metrics = [
              ["AWS/RDS", "WriteThroughput", "DBClusterIdentifier", aurora_cluster.id],
              ["AWS/RDS", "ReadThroughput", "DBClusterIdentifier", aurora_cluster.id]
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[Aurora] Read/Write Throughput"
          }
        }
      ]
    )
  ])

  # Aurora Serverless V1 Widgets
  aurora_serverless_v1_widgets = flatten([
    for i, aurora_cluster in tolist(local.Aurora.serverless_v1) : concat(
      [{
        type   = "text"
        x      = 0
        y      = local.aurora_serverless_v1_header_y + i * 10
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${aurora_cluster.id} (Aurora Serverless V1)\n[button:primary:${aurora_cluster.id}](https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${aurora_cluster.id})"
          background = "transparent"
        }
      }],
      [
        {
          type   = "metric"
          x      = 0
          y      = local.aurora_serverless_v1_header_y + 2 + i * 10
          width  = 6
          height = 8
          properties = {
            metrics = [["AWS/RDS", "ServerlessDatabaseCapacity", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Average"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora Serverless] Database Capacity"
          }
        },
        {
          type   = "metric"
          x      = 6
          y      = local.aurora_serverless_v1_header_y + 2 + i * 10
          width  = 6
          height = 8
          properties = {
            metrics = [["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Maximum"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora Serverless] DB Connections"
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = local.aurora_serverless_v1_header_y + 2 + i * 10
          width  = 6
          height = 8
          properties = {
            metrics = [
              ["AWS/RDS", "ReadLatency", "DBClusterIdentifier", aurora_cluster.id],
              [".", "WriteLatency", ".", aurora_cluster.id]
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[Aurora Serverless] Read/Write Latency"
          }
        },
        {
          type   = "metric"
          x      = 18
          y      = local.aurora_serverless_v1_header_y + 2 + i * 10
          width  = 6
          height = 8
          properties = {
            metrics = [
              ["AWS/RDS", "WriteIOPS", "DBClusterIdentifier", aurora_cluster.id],
              ["AWS/RDS", "ReadIOPS", "DBClusterIdentifier", aurora_cluster.id]
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[Aurora Serverless] Read/Write IOPS"
          }
        }
      ]
    )
  ])

  # Aurora Serverless V2 Widgets
  aurora_serverless_v2_widgets = flatten([
    for i, aurora_cluster in tolist(local.Aurora.serverless_v2) : concat(
      [{
        type   = "text"
        x      = 0
        y      = local.aurora_serverless_v2_header_y + i * 14
        width  = 24
        height = 2
        properties = {
          markdown   = "## ${aurora_cluster.id} (Aurora Serverless V2)\n[button:primary:${aurora_cluster.id}](https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${aurora_cluster.id})"
          background = "transparent"
        }
      }],
      [
        {
          type   = "metric"
          x      = 0
          y      = local.aurora_serverless_v2_header_y + 2 + i * 14
          width  = 6
          height = 6
          properties = {
            metrics = [["AWS/RDS", "ServerlessDatabaseCapacity", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Average"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora Serverless V2] Database Capacity"
          }
        },
        {
          type   = "metric"
          x      = 6
          y      = local.aurora_serverless_v2_header_y + 2 + i * 14
          width  = 6
          height = 6
          properties = {
            metrics = [["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Average"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora Serverless V2] CPU Utilization"
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = local.aurora_serverless_v2_header_y + 2 + i * 14
          width  = 6
          height = 6
          properties = {
            metrics = [["AWS/RDS", "FreeableMemory", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Minimum"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora Serverless V2] Free Memory"
          }
        },
        {
          type   = "metric"
          x      = 18
          y      = local.aurora_serverless_v2_header_y + 2 + i * 14
          width  = 6
          height = 6
          properties = {
            metrics = [
              ["AWS/RDS", "ReadLatency", "DBClusterIdentifier", aurora_cluster.id],
              [".", "WriteLatency", ".", aurora_cluster.id]
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[Aurora Serverless V2] Read/Write Latency"
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = local.aurora_serverless_v2_header_y + 8 + i * 14
          width  = 8
          height = 6
          properties = {
            metrics = [["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", aurora_cluster.id]]
            view    = "timeSeries"
            stat    = "Maximum"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[Aurora Serverless V2] DB Connections"
          }
        },
        {
          type   = "metric"
          x      = 8
          y      = local.aurora_serverless_v2_header_y + 8 + i * 14
          width  = 8
          height = 6
          properties = {
            metrics = [
              ["AWS/RDS", "WriteIOPS", "DBClusterIdentifier", aurora_cluster.id],
              ["AWS/RDS", "ReadIOPS", "DBClusterIdentifier", aurora_cluster.id]
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[Aurora Serverless V2] Read/Write IOPS"
          }
        },
        {
          type   = "metric"
          x      = 16
          y      = local.aurora_serverless_v2_header_y + 8 + i * 14
          width  = 8
          height = 6
          properties = {
            metrics = [
              ["AWS/RDS", "WriteThroughput", "DBClusterIdentifier", aurora_cluster.id],
              ["AWS/RDS", "ReadThroughput", "DBClusterIdentifier", aurora_cluster.id]
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[Aurora Serverless V2] Read/Write Throughput"
          }
        }
      ]
    )
  ])

  # ECS with Container Insights Widgets
  ecs_with_insights_widgets = flatten([
    for cluster in local.ECS.with_insights : concat(
      [{
        type   = "text"
        x      = 0
        y      = local.ecs_with_insights_header_y + (length([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) : 0)
        width  = 24
        height = 2
        properties = {
          markdown   = "# **Container Metrics**\n\n[button:primary:${cluster.name}](https://${data.aws_region.current.name}.console.aws.amazon.com/ecs/v2/clusters/${cluster.name}/services?region=${data.aws_region.current.name})"
          background = "transparent"
        }
      }],
      flatten([
        for i, service in cluster.services : concat(
          [{
            type   = "text"
            x      = 0
            y      = local.ecs_with_insights_header_y + 2 + (length([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) : 0) + i * 7
            width  = 24
            height = 1
            properties = {
              markdown   = "## ${service.name}"
              background = "transparent"
            }
          }],
          [
            {
              type   = "metric"
              x      = 0
              y      = local.ecs_with_insights_header_y + 3 + (length([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) : 0) + i * 7
              width  = 6
              height = 6
              properties = {
                metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", cluster.name, "ServiceName", service.name, { "stat" : "Maximum", "region" : data.aws_region.current.name }]]
                view    = "timeSeries"
                stacked = false
                region  = data.aws_region.current.name
                period  = 60
                title   = "[ECS] CPU Utilization"
                annotations = {
                  horizontal = [{ label = "alert", value = 90 }]
                }
                yAxis = { left = { min = 0, max = 100 } }
              }
            },
            {
              type   = "metric"
              x      = 6
              y      = local.ecs_with_insights_header_y + 3 + (length([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) : 0) + i * 7
              width  = 6
              height = 6
              properties = {
                metrics = [["AWS/ECS", "MemoryUtilization", "ClusterName", cluster.name, "ServiceName", service.name, { "stat" : "Maximum", "region" : data.aws_region.current.name }]]
                view    = "timeSeries"
                stacked = false
                region  = data.aws_region.current.name
                period  = 60
                title   = "[ECS] Memory Utilization"
                annotations = {
                  horizontal = [{ label = "alert", value = 90 }]
                }
                yAxis = { left = { min = 0, max = 100 } }
              }
            },
            {
              type   = "metric"
              x      = 12
              y      = local.ecs_with_insights_header_y + 3 + (length([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) : 0) + i * 7
              width  = 6
              height = 6
              properties = {
                metrics = [
                  ["ECS/ContainerInsights", "NetworkTxBytes", "ServiceName", service.name, "ClusterName", cluster.name, { "stat" : "Sum" }],
                  ["ECS/ContainerInsights", "NetworkRxBytes", "ServiceName", service.name, "ClusterName", cluster.name, { "stat" : "Sum" }]
                ]
                view    = "timeSeries"
                stacked = false
                region  = data.aws_region.current.name
                period  = 60
                title   = "[ECS] Network"
                annotations = {}
              }
            },
            {
              type   = "metric"
              x      = 18
              y      = local.ecs_with_insights_header_y + 3 + (length([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.with_insights, 0, index(local.ECS.with_insights, cluster)) : length(prev_cluster.services) * 7]) : 0) + i * 7
              width  = 6
              height = 6
              properties = {
                metrics = [["ECS/ContainerInsights", "RunningTaskCount", "ServiceName", service.name, "ClusterName", cluster.name, { "stat" : "Minimum" }]]
                view    = "timeSeries"
                stacked = false
                region  = data.aws_region.current.name
                period  = 60
                title   = "[ECS] Running Tasks"
                annotations = {
                  horizontal = [{ label = "alert", value = 0 }]
                }
              }
            }
          ]
        )
      ])
    )
  ])

  # ECS without Container Insights Widgets
  ecs_without_insights_widgets = flatten([
    for cluster in local.ECS.without_insights : concat(
      [{
        type   = "text"
        x      = 0
        y      = local.ecs_without_insights_header_y + (length([for prev_cluster in slice(local.ECS.without_insights, 0, index(local.ECS.without_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.without_insights, 0, index(local.ECS.without_insights, cluster)) : length(prev_cluster.services) * 7]) : 0)
        width  = 24
        height = 2
        properties = {
          markdown   = "# **Container Metrics**\n\n[button:primary:${cluster.name}](https://${data.aws_region.current.name}.console.aws.amazon.com/ecs/v2/clusters/${cluster.name}/services?region=${data.aws_region.current.name})"
          background = "transparent"
        }
      }],
      flatten([
        for i, service in cluster.services : concat(
          [{
            type   = "text"
            x      = 0
            y      = local.ecs_without_insights_header_y + 2 + (length([for prev_cluster in slice(local.ECS.without_insights, 0, index(local.ECS.without_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.without_insights, 0, index(local.ECS.without_insights, cluster)) : length(prev_cluster.services) * 7]) : 0) + i * 7
            width  = 24
            height = 1
            properties = {
              markdown   = "## ${service.name}"
              background = "transparent"
            }
          }],
          [
            {
              type   = "metric"
              x      = 0
              y      = local.ecs_without_insights_header_y + 3 + (length([for prev_cluster in slice(local.ECS.without_insights, 0, index(local.ECS.without_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.without_insights, 0, index(local.ECS.without_insights, cluster)) : length(prev_cluster.services) * 7]) : 0) + i * 7
              width  = 12
              height = 6
              properties = {
                metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", cluster.name, "ServiceName", service.name, { "stat" : "Maximum", "region" : data.aws_region.current.name }]]
                view    = "timeSeries"
                stacked = false
                region  = data.aws_region.current.name
                period  = 60
                title   = "[ECS] CPU Utilization"
                annotations = {
                  horizontal = [{ label = "alert", value = 90 }]
                }
                yAxis = { left = { min = 0, max = 100 } }
              }
            },
            {
              type   = "metric"
              x      = 12
              y      = local.ecs_without_insights_header_y + 3 + (length([for prev_cluster in slice(local.ECS.without_insights, 0, index(local.ECS.without_insights, cluster)) : length(prev_cluster.services) * 7]) > 0 ? sum([for prev_cluster in slice(local.ECS.without_insights, 0, index(local.ECS.without_insights, cluster)) : length(prev_cluster.services) * 7]) : 0) + i * 7
              width  = 12
              height = 6
              properties = {
                metrics = [["AWS/ECS", "MemoryUtilization", "ClusterName", cluster.name, "ServiceName", service.name, { "stat" : "Maximum", "region" : data.aws_region.current.name }]]
                view    = "timeSeries"
                stacked = false
                region  = data.aws_region.current.name
                period  = 60
                title   = "[ECS] Memory Utilization"
                annotations = {
                  horizontal = [{ label = "alert", value = 90 }]
                }
                yAxis = { left = { min = 0, max = 100 } }
              }
            }
          ]
        )
      ])
    )
  ])
}