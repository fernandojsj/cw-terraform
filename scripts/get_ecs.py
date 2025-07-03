import boto3
import hcl2
import json

# Lê a região do arquivo terraform.tfvars
with open("./terraform.tfvars", "r") as tfvars_file:
    tfvars = hcl2.load(tfvars_file)

region = tfvars.get("aws_region")

def categorize_ecs_clusters():
    ecs_with_insights = []
    ecs_without_insights = []
    
    try:
        ecs_client = boto3.client('ecs', region_name=region)
        
        # Get all clusters
        clusters_response = ecs_client.list_clusters()
        cluster_arns = clusters_response.get('clusterArns', [])
        
        if not cluster_arns:
            return {
                'ecs_with_insights': json.dumps(ecs_with_insights),
                'ecs_without_insights': json.dumps(ecs_without_insights)
            }
        
        # Get cluster details
        clusters_detail = ecs_client.describe_clusters(
            clusters=cluster_arns,
            include=['SETTINGS', 'TAGS']
        )
        
        for cluster in clusters_detail['clusters']:
            # Verifica as tags do cluster ECS
            has_monitoring_tag = False
            for tag in cluster.get('tags', []):
                if tag['key'] == 'Monitoring' and tag['value'] == 'True':
                    has_monitoring_tag = True
                    break
            
            if has_monitoring_tag:
                cluster_name = cluster['clusterName']
                
                # Check if Container Insights is enabled
                insights_enabled = False
                for setting in cluster.get('settings', []):
                    if setting['name'] == 'containerInsights' and setting['value'] == 'enabled':
                        insights_enabled = True
                        break
                
                # Get services for this cluster
                services_response = ecs_client.list_services(cluster=cluster_name)
                service_arns = services_response.get('serviceArns', [])
                
                services = []
                if service_arns:
                    services_detail = ecs_client.describe_services(
                        cluster=cluster_name,
                        services=service_arns
                    )
                    
                    for service in services_detail['services']:
                        services.append({
                            'name': service['serviceName'],
                            'arn': service['serviceArn']
                        })
                
                cluster_data = {
                    'name': cluster_name,
                    'arn': cluster['clusterArn'],
                    'services': services
                }
                
                if insights_enabled:
                    ecs_with_insights.append(cluster_data)
                else:
                    ecs_without_insights.append(cluster_data)
        
        return {
            'ecs_with_insights': json.dumps(ecs_with_insights),
            'ecs_without_insights': json.dumps(ecs_without_insights)
        }
        
    except Exception as e:
        # Return empty lists instead of error for consistency with other scripts
        return {
            'ecs_with_insights': json.dumps(ecs_with_insights),
            'ecs_without_insights': json.dumps(ecs_without_insights)
        }

if __name__ == "__main__":
    try:
        result = categorize_ecs_clusters()
        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({
            'ecs_with_insights': '[]',
            'ecs_without_insights': '[]'
        }))