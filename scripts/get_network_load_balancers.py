import boto3
import json
import hcl2

# Lê a região do arquivo terraform.tfvars
with open("./terraform.tfvars", "r") as tfvars_file:
    tfvars = hcl2.load(tfvars_file)

region = tfvars.get("aws_region")

# Inicializa o cliente AWS para ELBv2
client = boto3.client('elbv2', region_name=region)

try:
    # Obtém a lista de load balancers
    response = client.describe_load_balancers()

    # Filtra apenas os Network Load Balancers (NLBs) com tag Monitoring = True
    load_balancers = {}
    for lb in response['LoadBalancers']:
        if lb['Type'] == 'network':
            # Verifica as tags do load balancer
            tags_response = client.describe_tags(ResourceArns=[lb['LoadBalancerArn']])
            
            for tag_desc in tags_response['TagDescriptions']:
                for tag in tag_desc['Tags']:
                    if tag['Key'] == 'Monitoring' and tag['Value'] == 'True':
                        load_balancers[lb['LoadBalancerName']] = lb['LoadBalancerName']
                        break

    print(json.dumps(load_balancers))
except Exception as e:
    print(json.dumps({}))