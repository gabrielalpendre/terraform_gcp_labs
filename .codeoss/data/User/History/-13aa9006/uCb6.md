# Script de Automação para o Laboratório de Terraform do Google Cloud

Este script automatiza os passos para o Laboratório de Terraform do Google Cloud (GSP345). Ele configura um ambiente Terraform, importa a infraestrutura existente, faz várias alterações e configura componentes de rede.

## Pré-requisitos

- Um projeto do Google Cloud.
- A CLI `gcloud` instalada e autenticada.
- `terraform` instalado.
- Duas instâncias de VM existentes no projeto.

## Como Executar

1.  Crie um arquivo de configuração chamado `lab.conf` com o seguinte conteúdo, substituindo os valores de exemplo:
    ```bash
    BUCKET="seu-nome-de-bucket-unico"
    INSTANCE="sua-instancia"
    VPC="sua-vpc"
    ZONE="us-central1-a"
    ```

2.  Torne o script executável:
    ```bash
    chmod +x abhishek.sh
    ```

3.  Execute o script:
    ```bash
    ./abhishek.sh
    ```

O script executará então todos os passos do laboratório automaticamente.

## Detalhamento do Script

O script é dividido em várias etapas, cada uma realizando um conjunto específico de operações do Terraform.

### 1. Configuração Inicial e Entrada do Usuário

- O script começa definindo saídas com código de cores para melhor legibilidade.
- Ele exibe uma mensagem de boas-vindas.
- Ele carrega as variáveis necessárias (`BUCKET`, `INSTANCE`, `VPC`, `ZONE`) do arquivo `lab.conf`.
- Ele configura a CLI `gcloud` com a zona especificada e determina a região.
- Ele cria a estrutura de arquivos Terraform necessária (`main.tf`, `variables.tf`, e módulos para `instances` e `storage`).

### 2. Importando Instâncias Existentes

- **Objetivo**: Trazer duas instâncias de VM pré-existentes para o gerenciamento do Terraform.
- **Plano do Terraform**:
  - `main.tf` é configurado para usar o módulo `instances`.
  - `modules/instances/instances.tf` define dois recursos `google_compute_instance` (`tf-instance-1`, `tf-instance-2`).
  - O script executa `terraform import` para associar os recursos de nuvem existentes com as definições de recursos do Terraform.
- **Aplicação do Terraform**:
  - `terraform apply` é executado para sincronizar o arquivo de estado com os recursos importados. Nenhuma alteração na infraestrutura é feita neste ponto.

### 3. Adicionando um Bucket GCS (Criar)

- **Objetivo**: Criar um novo bucket do Google Cloud Storage.
- **Plano do Terraform**:
  - Um módulo `storage` é adicionado ao `main.tf`.
  - `modules/storage/storage.tf` é criado com um recurso `google_storage_bucket` usando o nome do bucket fornecido pelo usuário.
- **Aplicação do Terraform**:
  - `terraform apply` executa o plano, que **cria** o novo bucket do GCS no seu projeto GCP.

### 4. Configurando o Backend Remoto do GCS

- **Objetivo**: Mover o arquivo de estado do Terraform da máquina local para o bucket GCS recém-criado para persistência e colaboração.
- **Plano do Terraform**:
  - O arquivo `main.tf` é atualizado com um bloco `backend "gcs"`, apontando para o bucket GCS.
  - O script executa `terraform init`, que detecta a nova configuração de backend.
- **Aplicação do Terraform**:
  - `terraform init` solicita a migração do estado. O script responde "yes" automaticamente, e o Terraform copia o arquivo `terraform.tfstate` para o bucket GCS.

### 5. Modificando e Adicionando Instâncias (Atualizar e Criar)

- **Objetivo**: Atualizar o tipo de máquina das instâncias existentes e criar uma nova.
- **Plano do Terraform**:
  - O arquivo `modules/instances/instances.tf` é modificado:
    - O `machine_type` para `tf-instance-1` e `tf-instance-2` é alterado de `n1-standard-1` para `e2-standard-2`.
    - Um novo recurso `google_compute_instance` é adicionado usando o nome da instância fornecido pelo usuário.
- **Aplicação do Terraform**:
  - `terraform apply` executa o plano, que atualiza as duas instâncias existentes e cria uma nova instância de VM.
- **Destruição pelo Terraform**: Nenhum recurso é destruído nesta etapa. As instâncias existentes são atualizadas no local porque `allow_stopping_for_update` está ativado.

### 6. Marcando um Recurso como "Tainted" (Destruir e Criar)

- **Objetivo**: Forçar o Terraform a destruir e recriar um recurso específico na próxima aplicação.
- **Plano do Terraform**:
  - O script executa `terraform taint` na instância recém-criada.
  - `terraform plan` agora mostrará que esta instância está agendada para substituição (1 para destruir, 1 para criar).
- **Aplicação do Terraform**:
  - `terraform apply` destrói a instância marcada como "tainted" e a cria novamente imediatamente.
- **Destruição pelo Terraform**: A instância recém-criada da etapa anterior é destruída por ter sido marcada como "tainted".

### 7. Removendo uma Instância (Destruir)

- **Objetivo**: Remover a terceira instância da infraestrutura.
- **Plano do Terraform**:
  - O bloco de recurso para a terceira instância é removido de `modules/instances/instances.tf`.
  - `terraform plan` mostrará que a instância está agendada para destruição.
- **Aplicação do Terraform**:
  - `terraform apply` destrói a instância que acabou de ser recriada.
- **Destruição pelo Terraform**: A instância que acabou de ser recriada é destruída, pois foi removida da configuração.

### 8. Criando uma Rede VPC (Criar)

- **Objetivo**: Adicionar uma VPC personalizada com duas sub-redes usando um módulo público do Terraform.
- **Plano do Terraform**:
  - `main.tf` é atualizado para incluir o módulo `terraform-google-modules/network/google`.
  - O módulo é configurado para criar uma VPC e duas sub-redes (`subnet-01` e `subnet-02`) com faixas de IP especificadas.
- **Aplicação do Terraform**:
  - Após inicializar o novo módulo com `terraform init`, `terraform apply` cria a VPC e suas sub-redes.
- **Destruição pelo Terraform**: Nenhum recurso é destruído nesta etapa.

### 9. Anexando Instâncias à Nova VPC (Destruir e Criar)

- **Objetivo**: Mover as duas instâncias de VM da rede `default` para as sub-redes da VPC personalizada recém-criada.
- **Plano do Terraform**:
  - O bloco `network_interface` em `modules/instances/instances.tf` para ambas as instâncias é atualizado.
  - `tf-instance-1` é atribuída à `subnet-01` da nova VPC.
  - `tf-instance-2` é atribuída à `subnet-02` da nova VPC.
  - Esta alteração requer que as instâncias sejam recriadas.
- **Aplicação do Terraform**:
  - `terraform apply` destrói as duas instâncias da rede padrão e as recria dentro das novas sub-redes da VPC personalizada.
- **Destruição pelo Terraform**: As duas instâncias originais (`tf-instance-1`, `tf-instance-2`) são destruídas porque alterar a `network_interface` é uma ação destrutiva. Elas são recriadas na nova VPC.

### 10. Adicionando uma Regra de Firewall (Criar)

- **Objetivo**: Criar uma regra de firewall para permitir tráfego HTTP para instâncias com tags.
- **Plano do Terraform**:
  - Um recurso `google_compute_firewall` é adicionado ao `main.tf`.
  - A regra é configurada para permitir tráfego TCP na porta 80 de qualquer origem (`0.0.0.0/0`) para instâncias com a tag `web` dentro da VPC personalizada.
- **Aplicação do Terraform**:
  - `terraform apply` cria a nova regra de firewall na VPC.
- **Destruição pelo Terraform**: Nenhum recurso é destruído nesta etapa.

### 11. Conclusão

- O script imprime uma mensagem de "Laboratório Concluído com Sucesso!".

---
*Este script é para fins educacionais e é baseado no guia do laboratório GSP345.*