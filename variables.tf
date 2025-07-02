################## VARIÁVEIS PRINCIPAIS ##########################

variable "customer_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alarm_action_arn" {
  type = string
}

variable "aws_region" {
  type = string  
}

variable "rds_alarm_action_arn" {
  type = string
  default = null
}
