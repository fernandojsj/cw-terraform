locals {
  map_of_rds = {
    aurora_list = split(", ", data.external.RDS.result["Aurora_list"])
    rds_list    = split(", ", data.external.RDS.result["RDS"])
    aurora_serverless_list = split(", ", data.external.RDS.result["Aurora_serverless_list"])
  }

  target_groups = {
    for lb_name, _ in data.aws_alb.existing :
    lb_name => [
      for tg_arn in split(",", lookup(data.external.Map_of_targetGroups.result, lb_name, "")) :
      "targetgroup/${join("/", slice(split("/", tg_arn), 1, 3))}" # Extrai somente `targetgroup/{nome}/{id}`
      if startswith(tg_arn, "arn:aws:elasticloadbalancing")
    ]
  }

  load_balancer_widgets = flatten([
    for lb_name, alb in data.aws_alb.existing : [
      {
        type   = "text"
        x      = 0
        y      = 1 + index(keys(data.aws_alb.existing), lb_name) * 8
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
        y      = 3 + index(keys(data.aws_alb.existing), lb_name) * 8
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
        y      = 3 + index(keys(data.aws_alb.existing), lb_name) * 8
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
        y      = 3 + index(keys(data.aws_alb.existing), lb_name) * 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4)), { "id" : "m1", "visible": false }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4)), { "id" : "m2", "visible": false }],
            [{ "expression" : "IF(m1 > 0, 100*(m2/m1), 0)", "label" : "5xx_Percent", "id" : "e1" }]
          ]
          view   = "timeSeries"
          stat   = "Sum"
          region = data.aws_region.current.name
          period = 300
          title  = "[ALB] 5xx Error"
          yAxis   = { left = { min = 0, max = 25 } }
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
        type   = "metric",
        x      = 18,
        y      = 3 + index(keys(data.aws_alb.existing), lb_name) * 8,
        width  = 6,
        height = 6,
        properties = {
          metrics = [
            for tg_arn in local.target_groups[lb_name] : [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup", tg_arn,
              "LoadBalancer", join("/", slice(split("/", alb.arn), 1, 4))
            ]
          ],
          view    = "bar",
          stat    = "Maximum",
          region  = data.aws_region.current.name,
          period  = 60,
          title   = "[ALB] HealthyHost"
        }
      }
  ]])

  ec2_widgets = flatten([
    for i, instance_id in tolist(data.aws_instances.existing.ids) : concat(
      [
        {
          type   = "text"
          x      = 0
          y      = 1 + length(data.aws_alb.existing) * 8 + 2 + i * 7 // Adjusted Y coordinate
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
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7
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
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7
          width  = 4
          height = 6
          properties = {
            title   = "[EC2] Memory Utilization"
            region  = data.aws_region.current.name
            metrics = [["CWAgent", "mem_used_percent", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type]]
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
          x      = 8
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Disk Utilization"
            region = data.aws_region.current.name
            metrics = [
              ["CWAgent", "disk_used_percent", "path", "/", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type, "device", lookup(data.aws_instance.detailed[instance_id].tags, "OS", "") == "Windows" ? "xvda1" : "nvme0n1p1", "fstype", "ext4"]
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
          x      = 12
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7
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
            annotations = {}
          }
        },
        {
          type   = "metric"
          x      = 16
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7
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
                  value = 80
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 20
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7
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
                  value = 80
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
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7
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
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7 // Adjusted Y coordinate
          width  = 4
          height = 6
          properties = {
            title   = "[EC2] Memory Utilization"
            region  = data.aws_region.current.name
            metrics = [["CWAgent", "mem_used_percent", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type]]
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
          x      = 8
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7 // Adjusted Y coordinate
          width  = 4
          height = 6
          properties = {
            title  = "[EC2] Disk Utilization"
            region = data.aws_region.current.name
            metrics = [
              ["CWAgent", "disk_used_percent", "path", "/", "InstanceId", instance_id, "ImageId", data.aws_instance.detailed[instance_id].ami, "InstanceType", data.aws_instance.detailed[instance_id].instance_type, "device", lookup(data.aws_instance.detailed[instance_id].tags, "OS", "") == "Windows" ? "xvda1" : "nvme0n1p1", "fstype", "ext4"]
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
          x      = 12
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7 // Adjusted Y coordinate
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
                  value = 80
                }
              ]
            }
          }
        },
        {
          type   = "metric"
          x      = 16
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7 // Adjusted Y coordinate
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
            annotations = {}
          }
        },
        {
          type   = "metric"
          x      = 20
          y      = 1 + length(data.aws_alb.existing) * 8 + 4 + i * 7 // Adjusted Y coordinate
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
                  value = 80
                }
              ]
            }
          }
        }
      ]
    )
  ])

  rds_widgets = flatten([
    for i, rds_instance in tolist(local.map_of_rds.rds_list) : concat(
      [
        // RDS Instance Header with Button
        {
          type   = "text"
          x      = 0
          y      = 1 + length(data.aws_alb.existing) * 9 + length(data.aws_instances.existing.ids) * 8 + 4 + i * 14 // Adjust Y position for header
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
          y      = 1 + length(data.aws_alb.existing) * 9 + length(data.aws_instances.existing.ids) * 8 + 6 + i * 14
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
          }
        },
        // Memory Utilization
        {
          type   = "metric"
          x      = 4
          y      = 1 + length(data.aws_alb.existing) * 9 + length(data.aws_instances.existing.ids) * 8 + 6 + i * 14
          width  = 4
          height = 6
          properties = {
            metrics = [["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", rds_instance]]
            view    = "timeSeries"
            stat    = "Average"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[RDS] Memory Utilization"
            yAxis   = { left = { min = 0 } }
          }
        },
        // Storage Utilization
        {
          type   = "metric"
          x      = 8
          y      = 1 + length(data.aws_alb.existing) * 9 + length(data.aws_instances.existing.ids) * 8 + 6 + i * 14
          width  = 4
          height = 6
          properties = {
            metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", rds_instance]]
            view    = "timeSeries"
            stat    = "Average"
            region  = data.aws_region.current.name
            period  = 60
            title   = "[RDS] Storage Utilization"
            yAxis   = { left = { min = 0 } }
          }
        },
        // Database Connections and Max Connections
        {
          type   = "metric"
          x      = 12
          y      = 1 + length(data.aws_alb.existing) * 9 + length(data.aws_instances.existing.ids) * 8 + 6 + i * 14
          width  = 4
          height = 6
          properties = {
            metrics = [
              ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", rds_instance],
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[RDS] DB Connections"
            yAxis  = { left = { min = 0 } }
          }
        },
        // WriteIOPS and ReadIOPS
        {
          type   = "metric"
          x      = 16
          y      = 1 + length(data.aws_alb.existing) * 9 + length(data.aws_instances.existing.ids) * 8 + 6 + i * 14
          width  = 4
          height = 6
          properties = {
            metrics = [
              ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", rds_instance],
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[RDS] WriteIOPS"
            yAxis  = { left = { min = 0 } }
          }
        },
        {
          type   = "metric"
          x      = 20
          y      = 1 + length(data.aws_alb.existing) * 9 + length(data.aws_instances.existing.ids) * 8 + 6 + i * 14
          width  = 4
          height = 6
          properties = {
            metrics = [
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", rds_instance]
            ]
            view   = "timeSeries"
            stat   = "Average"
            region = data.aws_region.current.name
            period = 60
            title  = "[RDS] ReadIOPS"
            yAxis  = { left = { min = 0 } }
          }
        }
      ]
    )
  ])

  
}

resource "aws_cloudwatch_dashboard" "monitoring_dashboard" {
  dashboard_name = "${var.name}-dashboard-${var.env}"
  dashboard_body = jsonencode({
    widgets = concat(
      // Load Balancer Metrics Header
      [
        {
          type   = "text"
          x      = 0
          y      = 0
          width  = 24
          height = 1
          properties = {
            markdown   = "# Load Balancer Metrics\n\n"
            background = "transparent"
          }
        }
      ],
      local.load_balancer_widgets,
      // EC2 Metrics Header
      [
        {
          type   = "text"
          x      = 0
          y      = 1 + length(data.aws_alb.existing) * 8 + 1
          width  = 24
          height = 1
          properties = {
            markdown   = "# EC2 Metrics\n\n"
            background = "transparent"
          }
        }
      ],
      local.ec2_widgets,
      [
        {
          type   = "text"
          x      = 0
          y      = 1 + length(data.aws_alb.existing) * 9 + length(data.aws_instances.existing.ids) * 8 + 2
          width  = 24
          height = 1
          properties = {
            markdown   = "# RDS Metrics\n\n"
            background = "transparent"
          }
        }
      ],
      local.rds_widgets
    )
  })
}
