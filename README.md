# Terraform AWS CloudWatch Dashboard

Módulo Terraform para criação automática de dashboards CloudWatch com monitoramento de ALB, NLB, EC2, RDS e ECS.

## ⚠️ IMPORTANTE: Tag de Monitoramento Obrigatória

**TODOS os recursos devem ter a tag `Monitoring = "True"` para serem incluídos no dashboard.**

Recursos sem esta tag **NÃO** serão monitorados.

```hcl
tags = {
  Monitoring = "True"
  # outras tags...
}
```

## Recursos Monitorados

### Application Load Balancer (ALB)
- Request Count
- Latency
- 5xx Error Rate
- Healthy Host Count

### Network Load Balancer (NLB)
- New Flow Count
- Active Flow Count
- Consumed LCUs
- Processed Packets
- Healthy Host Count

### EC2 Instances
**Instâncias Tipo T (t2, t3, t3a, t4g)**:
- CPU Utilization
- Memory Utilization
- Disk Utilization
- **Credit Utilization** (específico para tipo T)
- Network In/Out
- Status Check

**Instâncias Não-T (m5, c5, r5, etc.)**:
- CPU Utilization
- Memory Utilization
- Disk Utilization
- Network In/Out
- Status Check
- Status Check EBS

### RDS Instances
**Instâncias Tipo T (db.t2, db.t3, db.t4g)**:
- CPU Utilization
- Free Memory (threshold dinâmico: 20% da memória)
- Free Storage Space (threshold: 10GB)
- Read/Write Latency
- **Credit Usage** (específico para tipo T)
- Read/Write IOPS
- Read/Write Throughput
- Database Connections (threshold: 80% do max_connections)

**Instâncias Não-T (db.m5, db.r5, etc.)**:
- CPU Utilization
- Free Memory (threshold dinâmico: 20% da memória)
- Free Storage Space (threshold: 10GB)
- Read/Write Latency
- Database Connections (threshold: 80% do max_connections)
- Read/Write IOPS (widget maior: 8 width)
- Read/Write Throughput (widget maior: 8 width)

### Aurora Clusters
**Aurora Provisioned**:
- CPU Utilization
- Free Memory
- Free Storage Space
- Read/Write Latency
- Database Connections
- Read/Write IOPS (widget maior: 8 width)
- Read/Write Throughput (widget maior: 8 width)

**Aurora Serverless V1**:
- **Database Capacity** (ACUs - Aurora Capacity Units)
- Database Connections
- Read/Write Latency
- Read/Write IOPS

**Aurora Serverless V2**:
- **Database Capacity** (ACUs - Aurora Capacity Units)
- CPU Utilization
- Free Memory
- Read/Write Latency
- Database Connections
- Read/Write IOPS (widget maior: 8 width)
- Read/Write Throughput (widget maior: 8 width)

### ECS Clusters
**Com Container Insights Habilitado**:
- CPU Utilization
- Memory Utilization
- Network Tx/Rx Bytes (métricas específicas do Container Insights)
- Running Task Count

**Sem Container Insights**:
- CPU Utilization
- Memory Utilization

## Configuração Obrigatória

### 1. Tag Monitoring Obrigatória

**OBRIGATÓRIO**: Todos os recursos devem ter a tag `Monitoring = "True"`:

```hcl
# Exemplo para EC2
resource "aws_instance" "example" {
  # ... outras configurações
  
  tags = {
    Monitoring = "True"
    OS = "Linux"
    Name = "minha-instancia"
  }
}

# Exemplo para RDS
resource "aws_db_instance" "example" {
  # ... outras configurações
  
  tags = {
    Monitoring = "True"
    Name = "minha-database"
  }
}

# Exemplo para ALB
resource "aws_lb" "example" {
  # ... outras configurações
  
  tags = {
    Monitoring = "True"
    Name = "meu-load-balancer"
  }
}

# Exemplo para ECS Cluster
resource "aws_ecs_cluster" "example" {
  # ... outras configurações
  
  tags = {
    Monitoring = "True"
    Name = "meu-cluster"
  }
}
```

### 2. Tag OS para EC2
**OBRIGATÓRIO**: Todas as instâncias EC2 devem ter a tag `OS` definida:

```hcl
tags = {
  Monitoring = "True"
  OS = "Windows"  # ou "Linux"
}
```

**Comportamento**:
- **Windows**: Usa métricas `CWAgent` com `objectname = "Memory"` e `LogicalDisk`
- **Linux**: Usa métricas `CWAgent` padrão (`mem_used_percent`, `disk_used_percent`)

### 3. Cálculo de Max Connections RDS
O módulo calcula automaticamente o `max_connections` baseado na engine:

**MySQL**: `LEAST({DBInstanceClassMemory/12582880}, 10000)`
**PostgreSQL**: `LEAST({DBInstanceClassMemory/9531392}, 5000)`

Threshold de alerta: **80%** do valor calculado

## Uso do Módulo

```hcl
module "cloudwatch_dashboard" {
  source  = ""
  
  # Variáveis obrigatórias
  customer_name    = "minha-empresa"
  environment      = "production"
  
  # Variáveis opcionais
  aws_region           = "us-east-1"  # Se não informado, usa região atual
  rds_alarm_action_arn = aws_sns_topic.rds_alerts.arn  # Opcional, usa alarm_action_arn se não informado
  alarm_action_arn     = aws_sns_topic.alerts.arn
}
```

## Variáveis

| Nome | Descrição | Tipo | Obrigatório | Padrão |
|------|-----------|------|-------------|--------|
| `customer_name` | Nome do cliente para identificação do dashboard | `string` | ✅ | - |
| `environment` | Ambiente (dev, staging, prod, etc.) | `string` | ✅ | - |
| `alarm_action_arn` | ARN da ação do alarme - **Opcional**: se não fornecido, alarmes não serão criados | `string` | ❌ | `null` |
| `aws_region` | Região AWS onde os recursos estão localizados | `string` | ❌ | Região atual |
| `rds_alarm_action_arn` | ARN específico para alarmes RDS - **Opcional**- | `string` | ❌ | `null` |

## Outputs

| Nome | Descrição |
|------|----------|
| `dashboard_name` | Nome do dashboard CloudWatch criado |
| `dashboard_url` | URL do dashboard no console AWS |
| `monitored_resources` | Resumo dos recursos monitorados |

## Scripts Python
O módulo utiliza scripts Python para descoberta automática de recursos:
- `get_application_load_balancers.py`
- `get_network_load_balancers.py` 
- `get_rds.py`
- `get_aurora.py`
- `get_target_groups.py`
- `get_ecs.py`

## Pré-requisitos

### 1. Tags Obrigatórias

**CRÍTICO**: Todos os recursos devem ter as seguintes tags:

```hcl
tags = {
  Monitoring = "True"  # OBRIGATÓRIO para todos os recursos
  OS = "Linux"         # OBRIGATÓRIO apenas para EC2 ("Linux" ou "Windows")
}
```

### 2. Permissões IAM
O usuário/role deve ter as seguintes permissões:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:*",
        "ec2:Describe*",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:DescribeTags",
        "rds:Describe*",
        "rds:ListTagsForResource",
        "ecs:ListClusters",
        "ecs:DescribeClusters",
        "ecs:ListServices",
        "ecs:DescribeServices"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. Estrutura do Repositório
```
terraform-aws-cloudwatch-dashboard/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── data.tf
├── locals.tf
├── widgets.tf
├── alarms.tf
├── README.md
└── scripts/
    ├── get_application_load_balancers.py
    ├── get_network_load_balancers.py
    ├── get_rds.py
    ├── get_aurora.py
    ├── get_target_groups.py
    └── get_ecs.py
```

## Pontos Importantes

1. **🏷️ Tag Monitoring Obrigatória**: Apenas recursos com `Monitoring = "True"` são monitorados
2. **Separação T vs Não-T**: Instâncias tipo T têm widgets específicos para créditos
3. **Tag OS Obrigatória**: EC2 sem tag OS pode causar erros nas métricas
4. **Thresholds Dinâmicos**: Memória RDS e conexões calculadas automaticamente
5. **Widgets Responsivos**: Layout ajusta automaticamente baseado no número de recursos
6. **Compatibilidade**: Suporta AWS Provider 5.x
7. **CloudWatch Agent**: Necessário para métricas de memória e disco do EC2
8. **Aurora Serverless**: Métricas específicas para V1 (capacity-based) e V2 (hybrid)
9. **Descoberta Automática**: Aurora clusters são categorizados automaticamente por tipo
10. **ECS Container Insights**: Clusters com Container Insights habilitado têm métricas avançadas (Network Tx/Rx)
11. **ECS Separação**: Clusters são automaticamente separados por status do Container Insights
12. **⚠️ Alarmes Aurora**: Não são criados alarmes automáticos para Aurora. Se necessário, adicione manualmente no console AWS
13. **🔔 Alarmes Opcionais**: Alarmes só são criados se `alarm_action_arn` for fornecido. Sem ARN = apenas dashboard

## Estrutura de Arquivos

```
├── main.tf              # Recursos principais
├── data.tf              # Data sources
├── locals.tf            # Cálculos locais
├── widgets.tf           # Definição dos widgets
├── alarms.tf            # Alarmes CloudWatch
├── variables.tf         # Variáveis de entrada
├── outputs.tf           # Outputs do módulo
├── versions.tf          # Versões dos providers
└── scripts/             # Scripts Python para descoberta
    ├── get_application_load_balancers.py
    ├── get_network_load_balancers.py
    ├── get_rds.py
    ├── get_aurora.py    
    ├── get_target_groups.py
    └── get_ecs.py
```