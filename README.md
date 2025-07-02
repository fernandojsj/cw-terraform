# Terraform AWS CloudWatch Dashboard

Módulo Terraform para criação automática de dashboards CloudWatch com monitoramento de ALB, NLB, EC2 e RDS.

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

## Configuração Obrigatória

### Tag OS para EC2
**OBRIGATÓRIO**: Todas as instâncias EC2 devem ter a tag `OS` definida:

```hcl
tags = {
  OS = "Windows"  # ou "Linux"
}
```

**Comportamento**:
- **Windows**: Usa métricas `CWAgent` com `objectname = "Memory"` e `LogicalDisk`
- **Linux**: Usa métricas `CWAgent` padrão (`mem_used_percent`, `disk_used_percent`)

### Cálculo de Max Connections RDS
O módulo calcula automaticamente o `max_connections` baseado na engine:

**MySQL**: `LEAST({DBInstanceClassMemory/12582880}, 10000)`
**PostgreSQL**: `LEAST({DBInstanceClassMemory/9531392}, 5000)`

Threshold de alerta: **80%** do valor calculado

## Uso

```hcl
module "cloudwatch_dashboard" {
  source = "./terraform-aws-clouddog-cw"
  
  aws_region = "us-east-1"
  # outras variáveis...
}
```

## Scripts Python
O módulo utiliza scripts Python para descoberta automática de recursos:
- `get_application_load_balancers.py`
- `get_network_load_balancers.py` 
- `get_rds.py`
- `get_target_groups.py`

## Pontos Importantes

1. **Separação T vs Não-T**: Instâncias tipo T têm widgets específicos para créditos
2. **Tag OS Obrigatória**: EC2 sem tag OS pode causar erros nas métricas
3. **Thresholds Dinâmicos**: Memória RDS e conexões calculadas automaticamente
4. **Widgets Responsivos**: Layout ajusta automaticamente baseado no número de recursos
5. **Compatibilidade**: Suporta AWS Provider 5.x
6. **CloudWatch Agent**: Necessário para métricas de memória e disco do EC2

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
```