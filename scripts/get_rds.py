import boto3
import hcl2
import json

# Lê a região do arquivo terraform.tfvars
with open("./terraform.tfvars", "r") as tfvars_file:
    tfvars = hcl2.load(tfvars_file)

region = tfvars.get("aws_region")

# Função para calcular Max Connections com base na memória da instância
def get_max_connections(db_instance):
    # Informações sobre a memória da instância para cada tipo de instância (em GB)
    instance_memory = {
        "db.t3.micro": 1,
        "db.t3.small": 2,
        "db.t3.medium": 4,
        "db.t3.large": 8,
        "db.t3.xlarge": 16,
        "db.t3.2xlarge": 32,
        "db.t4g.micro": 1,
        "db.t4g.small": 2,
        "db.t4g.medium": 4,
        "db.t4g.large": 8,
        "db.t4g.xlarge": 16,
        "db.t4g.2xlarge": 32,
        "db.m5.large": 8,
        "db.m5.xlarge": 16,
        "db.m5.2xlarge": 32,
        "db.m5.4xlarge": 64,
        "db.m5.8xlarge": 128,
        "db.m5.12xlarge": 192,
        "db.m5.16xlarge": 256,
        "db.m5.24xlarge": 384,
        "db.m6g.large": 8,
        "db.m6g.xlarge": 16,
        "db.m6g.2xlarge": 32,
        "db.m6g.4xlarge": 64,
        "db.m6g.8xlarge": 128,
        "db.m6g.12xlarge": 192,
        "db.m6g.16xlarge": 256,
        "db.r5.large": 16,
        "db.r5.xlarge": 32,
        "db.r5.2xlarge": 64,
        "db.r5.4xlarge": 128,
        "db.r5.8xlarge": 256,
        "db.r5.12xlarge": 384,
        "db.r5.16xlarge": 512,
        "db.r5.24xlarge": 768,
        "db.r6g.large": 16,
        "db.r6g.xlarge": 32,
        "db.r6g.2xlarge": 64,
        "db.r6g.4xlarge": 128,
        "db.r6g.8xlarge": 256,
        "db.r6g.12xlarge": 384,
        "db.r6g.16xlarge": 512,
        "db.x1.16xlarge": 976,
        "db.x1.32xlarge": 1952,
        "db.x2g.large": 16,
        "db.x2g.xlarge": 32,
        "db.x2g.2xlarge": 64,
        "db.x2g.4xlarge": 128,
        "db.x2g.8xlarge": 256,
        "db.x2g.12xlarge": 384,
        "db.x2g.16xlarge": 512,
        "db.z1d.large": 16,
        "db.z1d.xlarge": 32,
        "db.z1d.2xlarge": 64,
        "db.z1d.3xlarge": 96,
        "db.z1d.6xlarge": 192,
        "db.z1d.12xlarge": 384,
        "db.m7g.large": 16,
        "db.m7g.xlarge": 32,
        "db.m7g.2xlarge": 64,
        "db.m7g.4xlarge": 128,
        "db.m7g.8xlarge": 256,
        "db.m7g.12xlarge": 384,
        "db.m7g.16xlarge": 512,
        "db.r7g.large": 16,
        "db.r7g.xlarge": 32,
        "db.r7g.2xlarge": 64,
        "db.r7g.4xlarge": 128,
        "db.r7g.8xlarge": 256,
        "db.r7g.12xlarge": 384,
        "db.r7g.16xlarge": 512,
    }

    instance_type = db_instance['DBInstanceClass']
    
    # Se o tipo de instância não estiver no dicionário, assume 1 GB por padrão
    memory_gb = instance_memory.get(instance_type, 1)

    # Converte memória em GB para bytes
    db_memory_bytes = memory_gb * 1024 * 1024 * 1024  # Converte GB para bytes

    # Aplica a fórmula para calcular o max_connections
    max_connections = min(db_memory_bytes // 12582880, 12000)  # Aplica a fórmula

    return max_connections

def categorize_rds_instances():
    # Inicializa o cliente do boto3 para RDS
    rds_client = boto3.client('rds', region_name=region)

    # Listas para armazenar os diferentes tipos de RDS
    aurora_list = []
    rds_list = []
    aurora_serverless_list = []
    t_instance_list = []  # Lista para instâncias do tipo T (ID + tipo + Max Connections)

    try:
        # Descreve todos os clusters de banco de dados (necessário para Aurora)
        cluster_response = rds_client.describe_db_clusters()

        for cluster in cluster_response['DBClusters']:
            cluster_id = cluster['DBClusterIdentifier']
            engine = cluster['Engine']
            engine_mode = cluster.get('EngineMode', '')

            if "aurora" in engine:
                if engine_mode == "serverless":
                    aurora_serverless_list.append(cluster_id)
                else:
                    aurora_list.append(cluster_id)

        # Descreve todas as instâncias de banco de dados (para RDS normal)
        instance_response = rds_client.describe_db_instances()

        for db_instance in instance_response['DBInstances']:
            engine = db_instance['Engine']
            db_instance_id = db_instance['DBInstanceIdentifier']
            instance_type = db_instance['DBInstanceClass']

            if not db_instance.get('DBClusterIdentifier'):
                max_connections = get_max_connections(db_instance)
                t_instance_list.append({
                    "id": db_instance_id,
                    "type": instance_type,
                    "max_connections": max_connections
                })
                
                if 't' not in instance_type.lower():
                    rds_list.append(db_instance_id)

        return {
            "Aurora_list": ", ".join(aurora_list),
            "RDS": ", ".join(rds_list),
            "Aurora_serverless_list": ", ".join(aurora_serverless_list),
            "T_instances": t_instance_list
        }
    
    except Exception as e:
        return {"error": f"Erro ao listar as instâncias RDS: {str(e)}"}

if __name__ == "__main__":
    try:
        categorized_rds = categorize_rds_instances()
        categorized_rds["T_instances"] = json.dumps(categorized_rds["T_instances"], indent=2)
        print(json.dumps(categorized_rds))
    except Exception as e:
        print(json.dumps({"error": f"Erro no script: {str(e)}"}))