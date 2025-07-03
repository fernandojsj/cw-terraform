variable "customer_name" {
  description = "Nome do cliente para identificação do dashboard"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod, etc.)"
  type        = string
}

variable "alarm_action_arn" {
  description = "ARN da ação do alarme (SNS topic, etc.) - Opcional: se não fornecido, alarmes não serão criados"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "Região AWS onde os recursos estão localizados"
  type        = string
  default     = null
}

variable "rds_alarm_action_arn" {
  description = "ARN específico para alarmes RDS (opcional)"
  type        = string
  default     = null
}
