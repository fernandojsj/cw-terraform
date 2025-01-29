import boto3
import json
import hcl2

# Lê a região do arquivo terraform.tfvars
with open("./terraform.tfvars", "r") as tfvars_file:
    tfvars = hcl2.load(tfvars_file)

region = tfvars.get("aws_region")

# Inicializa o cliente AWS para ELBv2
client = boto3.client('elbv2', region_name=region)

# Obtém a lista de load balancers
response = client.describe_load_balancers()

# Filtra apenas os Network Load Balancers (ALBs)
load_balancers = [
    lb['LoadBalancerName']
    for lb in response['LoadBalancers']
    if lb['Type'] == 'network'  # Filtra ALBs
]

# Transforma a lista em um mapa de strings
map_output = {lb: lb for lb in load_balancers}

# Converte o mapa para uma string JSON formatada
map_output_json = json.dumps(map_output)

print(map_output_json)
