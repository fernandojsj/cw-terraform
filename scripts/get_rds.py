import boto3
import hcl2
import json

# Lê a região do arquivo terraform.tfvars
with open("./terraform.tfvars", "r") as tfvars_file:
    tfvars = hcl2.load(tfvars_file)

region = tfvars.get("aws_region")

def get_max_connections(db_instance):
    instance_memory = {
        "db.t3.micro": 1,"db.t3.small": 2, "db.t3.medium": 4,"db.t3.large": 8,"db.t3.xlarge": 16,
        "db.t3.2xlarge": 32,"db.t4g.micro": 1,"db.t4g.small": 2, "db.t4g.medium": 4,"db.t4g.large": 8,
        "db.t4g.xlarge": 16, "db.t4g.2xlarge": 32,"db.m5.large": 8,"db.m5.xlarge": 16, "db.m5.2xlarge": 32,
        "db.m5.4xlarge": 64,"db.m5.8xlarge": 128, "db.m5.12xlarge": 192,"db.m5.16xlarge": 256,
        "db.m5.24xlarge": 384, "db.m6g.large": 8,"db.m6g.xlarge": 16, "db.m6g.2xlarge": 32,
        "db.m6g.4xlarge": 64,"db.m6g.8xlarge": 128, "db.m6g.12xlarge": 192,"db.m6g.16xlarge": 256,
        "db.r5.large": 16,"db.r5.xlarge": 32, "db.r5.2xlarge": 64,"db.r5.4xlarge": 128,
        "db.r5.8xlarge": 256, "db.r5.12xlarge": 384,"db.r5.16xlarge": 512, "db.r5.24xlarge": 768,
        "db.r6g.large": 16,"db.r6g.xlarge": 32, "db.r6g.2xlarge": 64,"db.r6g.4xlarge": 128,
        "db.r6g.8xlarge": 256, "db.r6g.12xlarge": 384,"db.r6g.16xlarge": 512, "db.x1.16xlarge": 976,
        "db.x1.32xlarge": 1952, "db.x2g.large": 16,"db.x2g.xlarge": 32, "db.x2g.2xlarge": 64,
        "db.x2g.4xlarge": 128,"db.x2g.8xlarge": 256, "db.x2g.12xlarge": 384,"db.x2g.16xlarge": 512,
        "db.z1d.large": 16,"db.z1d.xlarge": 32, "db.z1d.2xlarge": 64,"db.z1d.3xlarge": 96,
        "db.z1d.6xlarge": 192, "db.z1d.12xlarge": 384,"db.m7g.large": 16,"db.m7g.xlarge": 32,
        "db.m7g.2xlarge": 64, "db.m7g.4xlarge": 128,"db.m7g.8xlarge": 256, "db.m7g.12xlarge": 384,
        "db.m7g.16xlarge": 512, "db.r7g.large": 16,"db.r7g.xlarge": 32, "db.r7g.2xlarge": 64,
        "db.r7g.4xlarge": 128,"db.r7g.8xlarge": 256, "db.r7g.12xlarge": 384, "db.r7g.16xlarge": 512,
    }

    instance_type = db_instance['DBInstanceClass']
    memory_gb = instance_memory.get(instance_type, 1)
    db_memory_bytes = memory_gb * 1024 * 1024 * 1024
    max_connections = min(db_memory_bytes // 12582880, 12000)
    return max_connections

def categorize_rds_instances():
    rds_client = boto3.client('rds', region_name=region)
    
    rds_list = []
    t_instance_list = []

    try:
        instance_response = rds_client.describe_db_instances()

        for db_instance in instance_response['DBInstances']:
            if not db_instance.get('DBClusterIdentifier'):
                # Verifica as tags da instância RDS
                tags_response = rds_client.list_tags_for_resource(ResourceName=db_instance['DBInstanceArn'])
                
                has_monitoring_tag = False
                for tag in tags_response['TagList']:
                    if tag['Key'] == 'Monitoring' and tag['Value'] == 'True':
                        has_monitoring_tag = True
                        break
                
                if has_monitoring_tag:
                    db_instance_id = db_instance['DBInstanceIdentifier']
                    instance_type = db_instance['DBInstanceClass']
                    allocated_storage = db_instance['AllocatedStorage']
                    max_connections = get_max_connections(db_instance)
                    
                    instance_info = {
                        "id": db_instance_id,
                        "type": instance_type,
                        "max_connections": max_connections,
                        "allocated_storage_gb": allocated_storage
                    }
                    
                    if 't' in instance_type.lower():
                        t_instance_list.append(instance_info)
                    else:
                        rds_list.append(instance_info)

        return {
            "RDS": json.dumps(rds_list),
            "T_instances": json.dumps(t_instance_list)
        }
    
    except Exception as e:
        return {"error": f"Erro ao listar as instâncias RDS: {str(e)}"}

if __name__ == "__main__":
    try:
        result = categorize_rds_instances()
        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({"error": f"Erro no script: {str(e)}"}))