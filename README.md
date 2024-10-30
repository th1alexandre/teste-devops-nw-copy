# Documentação do Projeto

Este documento descreve as ferramentas utilizadas para desenvolvimento/deploy do projeto bem como orienta sobre as etapas para realizar o deploy utilizando GitHub Actions (CI/CD) e Terraform (AWS)

## Ferramentas utilizadas

### 1. AWS

- VPC, Subnet, Internet Gateway e Route Tables
- EC2, Application Load Balancer e Security Groups
- Key Pair e "user data" para SSH e bootstrap da instância EC2
  - "user data" permite informar comandos a serem executados durante a inicialização da instância
  - bash scripts foram utilizados para provisionar as ferramentas e aplicações na instância EC2
- IAM para gerar acessos e permissões ao Terraform (IAM User, Access Key ID e Secret Access Key)

### 2. Python API

- Framework Flask
- [Poetry](https://python-poetry.org/) - packaging and dependency management
- Docker para conteinerização

### 3. Terraform

- Provisionamento de infraestrutura na AWS

### 4. GitHub Actions

- Pipelines CI/CD
- Build e Push de imagem da API para o Docker Hub
- Update de tag e release (utilizados para atualizar imagem no Docker Hub)
- Atualizar container rodando aplicação na infraestrutura AWS (EC2)

### 5. Outros

- Ubuntu (para desenvolvimento local e deploy na AWS)
- OpenSSH e OpenSSL para acesso remoto e gerar certificados para acesso SSH
- Git para versionamento do código da aplicação e infraestrutura (terraform)
- VirtualBox VMs (Para teste de scripts bash sem consumo de recursos EC2)
- curl (Testar endpoints da API e realizar download de ferramentas, e.g., Poetry)

## Passo a Passo para Deploy

### 1. Criar conta e repositório no Docker Hub

1.1 **Criar um usuário no Docker Hub**  
   - Acesse [Docker - Sign up](https://app.docker.com/signup) e crie uma conta.

1.2 **Criar um token para uso com o GitHub Actions**
   - Após criar sua conta, acesse https://app.docker.com/settings/personal-access-tokens e crie um token PAT com permissão READ, WRITE e DELETE.

1.3 **Criar um repositório**  
   - Acesse [Docker Hub](https://hub.docker.com/) e crie um repositório com o nome `teste-devops-nw`.
   - Nas configurações do repositório, mantenha-o com acesso público.

### 2. Configurar GitHub Secrets

- No repositório do GitHub, vá até **Settings** > **Secrets and variables** > **Actions** e adicione os seguintes segredos clicando em **New repository secret**:
  - `DOCKERHUB_NAMESPACE`: seu namespace no Docker Hub.
  - `DOCKERHUB_REPOSITORY`: o nome do repositório criado (neste caso, `teste-devops-nw`).
  - `DOCKERHUB_USERNAME`: seu nome de usuário no Docker Hub.
  - `DOCKERHUB_PASSWORD`: o token que você criou anteriormente.

### 3. Acionar pipeline CI/CD através de novo commit/push

- Navegue até o arquivo `/src/main.py` e faça as alterações desejadas.
- Realize o commit e faça o push das alterações. Isso acionará o CI/CD para buildar a imagem e enviá-la para o repositório do Docker Hub.

### 4. Login AWS CLI

- Obtenha através do console AWS (IAM) as credenciais `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` com as permissões necessárias para criar a infraestrutura.
  - Caso tenha dificuldades nessa etapa, consulte [este documento](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
- Faça login na cli aws utilizando o comando `aws configure` e as credenciais obtidas anteriormente.
- Selecione como região default `sa-east-1`. (Código Terraform inclui AZs dessa região, caso utilize outra região será necessário alterar código .tf)

### 5. Criar infraestrutura utilizando Terraform

- Acesse o arquivo `terraform/scripts/teste-devops-nw.sh` e altere o conteúdo da variável `DOCKERHUB_NAMESPACE` para adicionar seu namespace no Docker Hub.
- Abra um terminal na pasta raíz do projeto e navegue até a pasta `terraform/`, depois disso execute `terraform init` e `terraform apply` para criar a infraestrutura.
- Assim que a infraestrutura for criada anote os outputs referentes ao DNS do load balancer e IP da instância EC2
- Acesse a aplicação através do navegador utilizando http://<ALB_DNS>/ e http://<ALB_DNS>/health e verifique se a resposta condiz com o esperado em src/main.py

### 6. Configurar novos GitHub Secrets

- Após a criação da infraestrutura adicione os novos secrets contendo:
  - `EC2_HOST`: o IP da instância EC2 fornecido na etapa anterior.
  - `EC2_USER`: usuário para acesso SSH, neste caso `ubuntu`.
  - `EC2_SSH_PRIVATE_KEY`: SSH private key associada à instância. (enviada por e-mail)

### 7. Realizar Modificações na API

- Altere a mensagem exibida no path `/` (barra) no arquivo `/src/main.py`.
- Comite e realize o push das alterações.
- Após o push, aguarde a pipeline no GitHub Actions realizar o build e push da imagem para o repositório no Docker Hub contendo suas modificações na API.

### 8. Deploy das alterações

- Após o pipeline anterior finalizar o push da nova imagem, acesse a aba Actions no repositório GitHub e execute manualmente o pipeline `Manually update EC2 container`
- Esse workflow irá acessar via SSH a instância EC2, remover o container antigo, realizar o pull da nova imagem e iniciar o novo container contendo as novas alterações da API.
- Após a execução do pipeline finalizar, aguarde alguns instantes e acesse novamente http://<ALB_DNS>/ e verifique que a mensagem exibida está de acordo com o que foi modificado.

### 9. Destruir a infraestrutura

- Após finalizar os testes, destrua a infraestrutura executando `terraform destroy` em um terminal dentro da pasta /terraform
- Revoque a permissão das credenciais criadas anteriormente `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`

### 10. Recriando a infraestrutura

- Para recriar a infraestrutura, basta recomeçar a partir da etapa 4.

## Considerações Finais

### 1. Downtime ao atualizar container

- A forma como o container é atualizado na instância EC2 ao executar o pipeline `Manually update EC2 container` gera um pequeno downtime.
- Uma solução para isso seria utilizar nginx para balancear a carga entre o container velho e o novo
  - Primeiro, redirecionar as requests para o container velho.
  - Segundo, criar o novo container e aguardar até que o serviço esteja disponível (healthy).
  - Terceiro, redirecionar novas requests para o novo container.
  - Quarto, desprovisionar o container velho
  - Para um novo deployment basta repetir os passos anteriores
- Uma segunda alternativa seria utilizar Kubernetes ([EKS](https://aws.amazon.com/eks/)) para orquestrar os containers, que possui ferramentas nativas para rollout e rollback.
- A terceira alternativa (sugerida) seria utilizar [AWS ECS](https://aws.amazon.com/ecs/).

### 2. Update manual da instância EC2 (GitHub Actions `Manually update EC2 container`)

- Para praticidade do avaliador, foi mantido o trigger manual desse workflow.
- A atualização pode ser feita de forma automatizada, adicionando um workflow call para sempre que o pipeline de build/push da imagem for concluído, executar este pipeline de atualização do container contido na instância EC2.
  - Vale lembrar que para que isso seja possível a infraestrutura da AWS precisa estar previamente provisionada bem como os secrets do GitHub Actions configurados contendo as informações e credenciais para acesso SSH da instância EC2.

### 3. Domínio e conexão segura (HTTPS)

- Por segurança, seria correto configurar um certificado SSL válido para permitir conexões seguras (HTTPS)
- Visto que não há uma forma simples e rápida de permitir ao avaliador configurar os mesmos, foi deixado de lado essa configuração.
- Em um cenário onde seria necessário a configuração de certificado SSL para conexão HTTPS, siga essas etapas.
  - Primeiro, sendo necessário a compra de um domínio (Recomendação: [Cloudflare](https://www.cloudflare.com/pt-br/products/registrar/)).
  - Segundo, obter o certificado SSL utilizando [Let's Encrypt](https://letsencrypt.org/).
  - Terceiro, configurar renovação e configuração automática do certificado gerado na instância EC2.
  - Quarto, redirecionar todas as requisições HTTP para HTTPS (pode ser feito via nginx, Cloudflare possui [configuração automática](https://developers.cloudflare.com/ssl/edge-certificates/additional-options/always-use-https/) através de proxy de domínio).
  - Quinto, adicionar um A Record apontando o domínio para o IPv4 da instância EC2 (AAAA Record para IPv6).
  - Por último, informar o domínio aos clientes da aplicação.

### 4. Variáveis Terraform

- Para praticidade ao avaliador, as variáveis necessárias ao projeto foram adicionadas diretamente no código (main.tf).
- Como boa prática, seria melhor definir as variáveis necessárias (variables.tf) e configurá-las no arquivo `terraform.tfvars`.
- Arquivos `.tfvars` não devem ser adicionados ao versionamento de código (commitados no repositório) e por serem ignorados na configuração do `.gitignore` foi utilizado a abordagem de manter as variáveis de forma estática no arquivo `main.tf`.
- As variáveis permitem melhor reusabilidade do código, além de eventualmente conterem informações sensíveis (segredos) e por essa razão arquivos `.tfvars` não são commitados.

### 5. Terraform Backend

- É de alta recomendação utilizar um backend remoto para evitar a perca do estado da infraestrutura ao utilizar o backend local.
- Além disso, o uso de um backend remoto permite configurar [State Lock](https://developer.hashicorp.com/terraform/language/state/locking), o que possibilita a colaboração de outros DevOps Engineers em um mesmo projeto Terraform sem o risco de conflitos no manuseio da infraestrutura.
- Novamente, para praticidade do avaliador, foi deixado de lado a configuração pois iria exigir o provisionamento prévio da infraestrutura e posterior configuração via código visto que a configuração do `Terraform Backend` não permite o uso de variáveis.
- No caso de um projeto AWS, seria recomendado o uso do [S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3).

### 6. Repositório da Imagem Público

- O repositório da imagem foi deixado público para praticidade do avaliador.
- Em um ambiente de produção isso nunca deve acontecer, sendo mais adequado manter o repositório privado e adicionar as credenciais de acesso ao repositório na instância EC2, similar ao que foi feito na pipeline de Build e Push da Imagem no Docker Hub.
- Esse projeto utilizou Docker Hub por praticidade, considerando que o projeto utiliza a infraestrutura da AWS é recomendado utilizar o [ECR](https://aws.amazon.com/ecr/) como repositório de imagens.
