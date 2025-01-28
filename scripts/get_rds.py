import boto3
import hcl2
import json

# Lê a região do arquivo terraform.tfvars
with open("./terraform.tfvars", "r") as tfvars_file:
    tfvars = hcl2.load(tfvars_file)

region = tfvars.get("aws_region")

def categorize_rds_instances():
    # Inicializa o cliente do boto3 para RDS
    rds_client = boto3.client('rds', region_name=region)

    # Listas para armazenar os diferentes tipos de RDS
    aurora_list = []
    rds_list = []
    aurora_serverless_list = []

    try:
        # Descreve todos os clusters de banco de dados (necessário para Aurora)
        cluster_response = rds_client.describe_db_clusters()

        # Processa cada cluster
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

        # Processa cada instância
        for db_instance in instance_response['DBInstances']:
            engine = db_instance['Engine']
            db_instance_id = db_instance['DBInstanceIdentifier']

            # Verifica se a instância não está associada a um cluster (RDS normal)
            if not db_instance.get('DBClusterIdentifier'):
                rds_list.append(db_instance_id)

        # Retorna o resultado categorizado como um dicionário
        return {
            "Aurora_list": ", ".join(aurora_list),
            "RDS": ", ".join(rds_list),
            "Aurora_serverless_list": ", ".join(aurora_serverless_list)
        }

    except Exception as e:
        # Retorna o erro em formato JSON caso algo dê errado
        return {"error": f"Erro ao listar as instâncias RDS: {str(e)}"}

if __name__ == "__main__":
    # Obtem os resultados categorizados
    categorized_rds = categorize_rds_instances()

    # Garante que a saída esteja no formato JSON
    print(json.dumps(categorized_rds, indent=4))
