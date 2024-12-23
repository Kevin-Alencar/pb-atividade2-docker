# Deploy de uma aplicação WordPress usando Docker na AWS
<div>
  Este projeto tem como objetivo realizar o deploy de uma aplicação WordPress utilizando Docker em um ambiente na AWS. A solução conta com duas instâncias EC2 para o conteiner de aplicação, um banco de dados AWS RDS MySQL, um serviço AWS EFS para armazenamento de arquivos estáticos, Load Balancer para gerenciar o tráfego e o Auto Scaling para proporcionar escalabilidade para a aplicação.
- Ponto adicional para o trabalho que utilizar a instalação via script de Start Instance (user_data.sh)
</div>

# Arquitetura do Projeto

  <img src="https://github.com/user-attachments/assets/67f5ff17-0220-48a0-8e3a-bd49fc57e876" alt="Descrição da imagem">

### Instâncias EC2:

- São servidores virtuais que hospedam os contêineres Docker executando a aplicação WordPress.
- Garantem flexibilidade e escalabilidade para o ambiente.

### Banco de Dados (RDS MySQL):

- Serviço gerenciado pela AWS que oferece um banco de dados relacional altamente disponível e escalável.
- Armazena os dados dinâmicos da aplicação WordPress, como usuários, posts e configurações.

### Elastic File System (EFS):

- Sistema de arquivos elástico e compartilhado que permite o armazenamento persistente de arquivos estáticos, como imagens e plugins do WordPress.
- Pode ser montado em múltiplas instâncias EC2 simultaneamente, garantindo consistência de dados.

### Load Balancer (ELB):

- Serviço que distribui automaticamente o tráfego de entrada entre as instâncias EC2.
- Aumenta a disponibilidade e melhora a experiência do usuário, garantindo que o tráfego seja redirecionado para servidores saudáveis.

### AutoScaling

- Mecanismo que ajusta automaticamente o número de instâncias EC2 para atender à demanda de tráfego ou carga de trabalho.
- Garante alta disponibilidade e otimização de custos, escalando os recursos de forma dinâmica conforme necessário.

## Pré-Requisitos

Antes de iniciar, assegure-se de que os seguintes recursos estão configurados:
- Conta AWS com permissões para criar instâncias EC2, RDS, EFS e Load Balancer.
  
## 1° Passo: Entre na AWS e comece criando uma VPC com duas zonas de disponibilidade, duas sub-redes Privadas e duas sub-redes Públicas
### Nesta etapa iremos criar nossa VPC e configura-la com os seguintes aspectos
- Selecione "VPC e muito mais"
- Nomeie a VPC
- Escolha duas zonas de disponibilidade
- Escolha duas sub-redes privadas e duas sub-redes públicas
- Escolha criar um gateway NAT por AZ
- Escolha criar gateway da internet
  
  ![image](https://github.com/user-attachments/assets/373134ce-46a6-4845-aaf2-914020f78791)
  
## 2° Passo: Crie os grupos de segurança público e privado com os seguintes procolos
### Para o grupo de segurança Público:
- Entrada 
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  |     HTTP     |    TCP   |    80      |        0.0.0.0/0            |
  |     HTTPS    |    TCP   |    443     |        0.0.0.0/0            |
  |     SSH      |    TCP   |    22      |        0.0.0.0/0            |
- Saída
  | Tipo          | Protocolo|  Porta     |      Tipo de Origem         |
  |---------------|----------|------------|-----------------------------|
  | Todo tráfego  |   Todos  |   Tudo     |        0.0.0.0/0            |
  
### Para o grupo de segurança Privado:
- Entrada 
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  | MySql/Aurora |    TCP   |   3306     |        0.0.0.0/0            |
  |     HTTP     |    TCP   |    80      |     grup. seg. público      |
  |     HTTPS    |    TCP   |    443     |     grup. seg. público      |
  |     SSH      |    TCP   |    22      |        0.0.0.0/0            |
  |     NFS      |    TCP   |   2049     |        0.0.0.0/0            |
- Saída
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  | Todo tráfego |   Todos  |   Todos    |        0.0.0.0/0            |

  ## 3° Passo: Crie um Elastic File System (EFS):
- Pesquise pelo serviço EFS na AWS
- Dê um nome ao seu EFS
- Crie-o
  
  ## 4° Passo: Crie um banco de dados RDS MySql:
### A criação do RDS precisa contemplar o seguintes tópicos:
- Antes de criar, crie um grupo de sub-redes de banco de dados, escolha sua VPC, escolha suas zonas de disponibilidade e escolha as sub-redes privadas de cada AZ
- Escolha criação padrão
- Tipo de mecanismo: MySql
- Modelos: escolha o nível gratuito
- Faça a identificação do seu DB com nome, login e senha
- Configuração da instância: db.t3.micro
- Conectividade: Não se conectar EC2, pois iremos colocar posteriormente
- Acesso público: não
- Escolha o grupo de sub-redes de banco de dados criado anteriormente
- Escolha o grupo de segurança privado
- Vá em detalhes adicionais e nomeie seu banco de dados e guarde esse nome que será necessário
- Coloque as Tags necessárias.
- Clique em criar.
    
## 5° Passo: Crie duas Instâncias EC2 (uma em cada AZ)
### Nesta etapa vamos criar duas intâncias EC2 com as seguintes configurações:
- Tags de permissão (Se necessário)
- Distribuição Amazon Linux 2023
- Tipo de instância: t2.micro
- Crie e salve seu Par de Chaves
- Em configuração de rede, vá em editar e escolha sua VPC e a sub-rede privada da sua zona (se for a segunda EC2 escolha uma AZ diferente da primeira EC2 criada)
- Desabilitar a opção de atribuir IP Público automaticamente
- Selecionar seu grupo de segurança privado criado anteriormente
- Em detalhe avançados, vamos colocar nosso script de incialização que atualizará a máquina, instalará o docker, docker-compose e montagem do EFS:
<div> 
  
```  
#!/bin/bash 
 
sudo yum update -y 
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
newgrp docker
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo mkdir /home/ec2-user/wordpress
cat <<EOF > /home/ec2-user/wordpress/docker-compose.yml
services:
 
  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: <aqui coloque o endpoint do seu RDS>:3306
      WORDPRESS_DB_USER: <seu user>
      WORDPRESS_DB_PASSWORD: <sua senha>
      WORDPRESS_DB_NAME: <aqui coloque aquele nome que colocamos nos detalhes adicionais do RDS(revise o passo 4, tópico 11)>
    volumes:
      - /mnt/efs:/var/www/html
EOF
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-082b0295d71cc0635.efs.us-east-1.amazonaws.com:/ /mnt/efs
docker-compose -f /home/ec2-user/wordpress/docker-compose.yml up -d
```

</div>

## 6° Passo: Crie um Classic Load Balancer:
### Característica do Classic Load Balance:
- Voltado para a Internet
- Escolha a VPC criada e as Zonas de Disponibilidade com subnets públicas
- ATENÇÃO: Escolha o grupo de segurança Público

- Configurar as verificações de integridade

  | Protocolo ping | Porta ping |     Caminho de ping         |
  |----------------|------------|-----------------------------|
  |     HTTP       |    80      |  /wp-admin/install.php      |       
  
## 7° passo: Crie um grupo de Auto Scaling:
- No painel EC2, clique em Grupos Auto Scaling
- Crie um grupo de execução onde colocará os características para escalablidade das EC2
- Coloque todos os dados idênticos ao das EC2 (Tags, Grupo de seguraça privado, par de chaves, distribuição, script)  EXCETO os dados de sub-rede, veja:
  
![image](https://github.com/user-attachments/assets/6c87466d-58dc-4106-a332-81837ecb5373)

- Com esse grupo criado, volta a tela do Auto Scaling e prossiga selecionando-o
- Escolher as opções de execução de instância: VPC criada e agora escolha as sub-redes privadas de cada zona
- Integrar com outros serviços: anexe o Classic Load balancer já criado
- Prossiga normalmente as simples etapas e crie seu Grupo Auto Scaling
- Agora adicionamos escalabilidade ao nosso projeto
   
## 8° passo: Acesse o wordpress
- Cole o DNS do Load Balancer no navegador
  ![image](https://github.com/user-attachments/assets/d1327d9d-ecdc-464e-b870-675464114908)
  Tela de login do Wordpress

Agora, sua aplicação está rodando com disponibilidade!!!

### Integrantes da dupla
- Nome: Kevin Alencar Costa
- Nome: Tales Santos de Souza
