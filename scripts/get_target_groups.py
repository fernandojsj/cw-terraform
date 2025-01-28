import boto3
import json
import hcl2

# Lê a região do arquivo terraform.tfvars
with open("./terraform.tfvars", "r") as tfvars_file:
    tfvars = hcl2.load(tfvars_file)

region = tfvars.get("aws_region")


# Inicializa o cliente AWS para ELBv2
client = boto3.client('elbv2', region_name=region)

# Obtém a lista de ALBs
response = client.describe_load_balancers()

# Dicionário para armazenar os ALBs e seus target groups
output = {}

# Para cada ALB, obtém os target groups associados
for lb in response['LoadBalancers']:
    load_balancer_name = lb['LoadBalancerName']
    load_balancer_arn = lb['LoadBalancerArn']
    
    # Obtém os target groups associados ao ALB
    tg_response = client.describe_target_groups(LoadBalancerArn=load_balancer_arn)
    
    # Junta os ARNs dos target groups como uma string delimitada por vírgulas
    output[load_balancer_name] = ",".join(
        tg["TargetGroupArn"] for tg in tg_response['TargetGroups']
    )

# Retorna o dicionário como um JSON válido
print(json.dumps(output))
