# Deploy de uma aplicação WordPress usando Docker na AWS
<div>
  Este projeto tem como objetivo realizar o deploy de uma aplicação WordPress utilizando Docker em um ambiente na AWS. A solução conta com duas instâncias EC2 para o conteiner de aplicação, um banco de dados AWS RDS MySQL, um serviço AWS EFS para armazenamento de arquivos estáticos e um Load Balancer para gerenciar o tráfego.
- Ponto adicional para o trabalho que utilizar a instalação via script de Start Instance (user_data.sh)
</div>

![image](https://github.com/user-attachments/assets/67f5ff17-0220-48a0-8e3a-bd49fc57e876) 

# Arquitetura do Projeto
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
## Nesta etapa iremos criar nossa VPC e configura-la com os seguintes aspectos
- Selecione "VPC e muito mais"
- Nomeie a VPC
- Escolha duas zonas de disponibilidade
- Escolha duas sub-redes privadas e duas sub-redes públicas
- Escolha criar um gateway NAT por AZ
- Escolha criar gateway da internet

  ![image](https://github.com/user-attachments/assets/373134ce-46a6-4845-aaf2-914020f78791)

## 2° Passo: Crie oo grupos de segurança para o EC2, RDS MySql, EFS e Load Balance com os seguintes procolos
### Para o EC2:
- Entrada 
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  |     HTTP     |    TCP   |    80      |    G.S do Load Balancer     |
  |     HTTPS    |    TCP   |    443     |    G.S do Load Balancer     |
  |     NFS      |    TCP   |   2049     |        G.S do EFS           |
  |     SSH      |    TCP   |    22      |        0.0.0.0/0            |
- Saída
  | Tipo          | Protocolo|  Porta     |      Tipo de Origem         |
  |---------------|----------|------------|-----------------------------|
  |     NFS       |    TCP   |   2049     |        G.S do EFS           |
### Para o RDS MySql:
- Entrada 
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  | MySql/Aurora |    TCP   |   3306     | Grupo de Segurança da EC2   |
- Saída
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  | Todo tráfego |   Todos  |   Todos    |        0.0.0.0/0            |
### Para o EFS:
- Entrada
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  |    NFS       |    TCP   |   2049     |  Grupo de Segurança da EC2  |
- Saída 
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  | Todo tráfego |   Todos  |   Tudo     |        0.0.0.0/0            |

### Para o LoadBalancer:
- Entrada
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  |     HTTP     |    TCP   |    80      |         0.0.0.0/0           |
  |     HTTPS    |    TCP   |    443     |         0.0.0.0/0           |
- Saída
  | Tipo         | Protocolo|  Porta     |      Tipo de Origem         |
  |--------------|----------|------------|-----------------------------|
  | Todo tráfego |   TCP    |   Tudo     | Grupo de Segurança da EC2   |
    
## 3° Passo: Crie uma Instância EC2 
## Nesta etapa vamos criar uma intância EC2 com as seguintes configurações:
- Tags de permissão (Se necessário)
- Distribuição Amazon Linux 2023
- Tipo de instância: t2.micro
- Crie e salve seu Par de Chaves (escolha de preferência tipo rsa)
- Em configuração de rede, vá em editar e escolha sua VPC e a sub-rede privada
- Desabilitar a opção de atribuir IP Público automaticamente
- Selecionar seu grupo de segurança da EC2 criado anteriormente
- Em detalhe avançados, vamos colocar nosso script de incialização que instalará o docker, docker-compose e os pacotes de montagem:
<div>
  
```  
#!/bin/bash

sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo chkconfig docker on
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo mv /usr/local/bin/docker-compose /bin/docker-compose
sudo mkdir /home/ec2-user/wordpress
sudo mkdir /mnt/efs
sudo chmod 777 /mnt/efs
```

</div>

## 4° Passo: Crie um banco de dados RDS MySql:
## A criação do RDS precisa contemplar o seguintes tópicos:
- Escolha criação padrão
- Tipo de mecanismo: MySql
- Modelos: escolha o nível gratuito
- Faça a identificação do seu DB com nome, login e senha
- Configuração da instância: db.t3.micro
- Conectividade: Conectar-se a um recurso de computação do EC2
- Escolha sua EC2 criada anteriormente
- Acesso público: não
- Escolha o grupo de segurança específico para o RDS que criamos antes
- Vá em detalhes adicionais e nomeie seu banco de dados e guarde esse nome que será necessário
- Clique em criar.
- Então, após criar a EC2 e o RDS, conecte os dois:

  ![image](https://github.com/user-attachments/assets/1e6bbe71-3b9e-4b55-acd6-4282673e538a)
- Conecte-se ao terminal de sua instância:
- Para isso precisamos certificar que podemos nos conectar na instância e ela ter acesso à internet para realizar seus comandos, portanto:
- Crie um endpoint EC2 Connect para poder acessar o terminal da sua instância
- Feito isso, volte para a conexão

## 5° Passo: Crie um Elastic File System (EFS):
- Pesquise pelo serviço EFS na AWS
- Dê um nome ao seu EFS
- Clique em personalizar
- Na primeira etapa, apenas clique próximo
- Na segunda etapa, tire os grupos de segurança default e coloque o do EFS criado anteriormente 
- Na próxima etapa, apenas conclua em criar efs
- Criado o EFS, clique nele e vá em anexar
- Dentre as opções, escolha a montagem via cliente NFS e cole essa comando no terminal, porém substitua "efs" pelo diretório já criado "/mnt/efs"  
  sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0fe36ac0f07bfc20e.efs.us-east-1.amazonaws.com:/ efs
  exemplo:
  sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0fe36ac0f07bfc20e.efs.us-east-1.amazonaws.com:/ /mnt/efs
-Para testar a montagem, execute o comando df -h que monstrar=a o que foi montado no disco:

![image](https://github.com/user-attachments/assets/e40eb136-4dde-4623-a5db-02606c76d9d2)

-Perceba que foi montado com sucesso
- Agora para automatizar essa montagem, vamos editar o "fstab" com o comando sudo nano /etc/fstab adicionando uma linha com o comando:
  fs-0fe36ac0f07bfc20e.efs.us-east-1.amazonaws.com:/    /mnt/efs    nfs4    defaults,_netdev,rw    0   0
  porém, esse DNS deve ser alterado pelo que corresponde ao seu EFS
  - Salve o arquivo nano apertando Ctrl+o, Enter e Ctrl+x
  - Feito isso, excecute o comando sudo umount /mnt/efs (desmontar o EFS) e depois sudo mount -a (montar o EFS agora com as alterações que fizemos)
  - Agora, para iniciar o container do WordPress, é necessário criar um arquivo docker-compose.yml no diretório wordpress contendo as instruções abaixo:

```
services:
  wordpress:
    image: wordpress:latest
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: endpoint do rds
      WORDPRESS_DB_USER: seu user
      WORDPRESS_DB_PASSWORD: sua senha
      WORDPRESS_DB_NAME: nome do banco (não da instância RDS)
    volumes:
      - wordpress:/var/www/html

volumes:
  wordpress:

 ```

- Feito isso, estará pronto para usar o docker-compose com o comando docker-compose up -d e depois docker ps para verificar o conteiner inicializado:

  ![image](https://github.com/user-attachments/assets/9c31199a-260e-4233-8261-b6ebe4157ce9)

- Para testar o banco de dados no conteiner excecute: docker exec -it <ID_DO_CONTAINER_WORDPRESS> /bin/bash
- Dentro do container WordPress execute: apt-get update -y e depois apt-get install default-mysql-client -y
## 6° Passo: Crie um Load Balancer:
## Característica do Load Balance:
- Voltado para a Internet
- Escolha a VPC criada e as Zonas de Disponibilidade com subnets públicas
- Escolha o grupo de segurança do Load balancer
- Configurar os Listeners
  
  | Protocolo do Listener | Protocolo do Listener |  Protocolo da Intância | Porta da Instância |
  |-----------------------|-----------------------|------------------------|--------------------|
  |        HTTP           |         80            |         HTTP           |       80           |

-Configurar as verificações de integridade

  | Protocolo ping | Porta ping | Caminho de ping |
  |----------------|------------|-----------------|
  |     HTTP       |    80      |     HTTP        |       
  
## 7° passo: Crie um grupo de Auto Scaling:
## Características do Auto Scaling:



## Integrantes da dupla
Nome: Kevin Alencar Costa
Contato: kevin.costa.pb@compass.com.br
Nome: Tales Santos de Souza
Contato: 

---
