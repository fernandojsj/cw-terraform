import boto3
import hcl2
import json

# Lê a região do arquivo terraform.tfvars
with open("./terraform.tfvars", "r") as tfvars_file:
    tfvars = hcl2.load(tfvars_file)

region = tfvars.get("aws_region")

def categorize_aurora_clusters():
    rds_client = boto3.client('rds', region_name=region)
    
    aurora_provisioned = []
    aurora_serverless_v1 = []
    aurora_serverless_v2 = []
    
    try:
        cluster_response = rds_client.describe_db_clusters()
        
        for cluster in cluster_response['DBClusters']:
            if "aurora" in cluster['Engine']:
                # Verifica as tags do cluster Aurora
                tags_response = rds_client.list_tags_for_resource(ResourceName=cluster['DBClusterArn'])
                
                has_monitoring_tag = False
                for tag in tags_response['TagList']:
                    if tag['Key'] == 'Monitoring' and tag['Value'] == 'True':
                        has_monitoring_tag = True
                        break
                
                if has_monitoring_tag:
                    cluster_id = cluster['DBClusterIdentifier']
                    engine = cluster['Engine']
                    engine_mode = cluster.get('EngineMode', 'provisioned')
                    
                    cluster_info = {
                        "id": cluster_id,
                        "engine": engine,
                        "engine_mode": engine_mode
                    }
                    
                    if engine_mode == "serverless":
                        aurora_serverless_v1.append(cluster_info)
                    elif engine_mode == "provisioned" and cluster.get('ServerlessV2ScalingConfiguration'):
                        aurora_serverless_v2.append(cluster_info)
                    else:
                        aurora_provisioned.append(cluster_info)
        
        return {
            "aurora_provisioned": json.dumps(aurora_provisioned),
            "aurora_serverless_v1": json.dumps(aurora_serverless_v1),
            "aurora_serverless_v2": json.dumps(aurora_serverless_v2)
        }
    
    except Exception as e:
        return {"error": f"Erro ao listar clusters Aurora: {str(e)}"}

if __name__ == "__main__":
    try:
        result = categorize_aurora_clusters()
        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({"error": f"Erro no script: {str(e)}"}))