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
## 2° Passo: Crie oo grupos de segurança para o EC2, RDS MySql, EFS e Load Balance com os seguintes procolos
### Para o EC2:

  | Tipo         | Protocolo|  Porta     | Tipo de Origem   | Tipo        |
  |--------------|----------|------------|------------------|-------------|
  | SSH          | TCP      |   22       | Qualquer lugar   | 0.0.0.0/0   |
  | HTTP         | TCP      |   80       | Qualquer Lugar   | 0.0.0.0/0   |
### Para o RDS MySql:

  | Tipo         | Protocolo|  Porta     | Tipo de Origem   | Tipo        |
  |--------------|----------|------------|------------------|-------------|
  | MySql/Aurora | TCP      |   3306     | Qualquer lugar   | 0.0.0.0/0   |
### Para o EFS:

  | Tipo         | Protocolo|  Porta     | Tipo de Origem   | Tipo        |
  |--------------|----------|------------|------------------|-------------|
  | NFS          | TCP      |   2049     | Qualquer lugar   | 0.0.0.0/0   |
### Para o LoadBalancer:

  | Tipo         | Protocolo|  Porta     | Tipo de Origem   | Tipo        |
  |--------------|----------|------------|------------------|-------------|
  | HTTP          | TCP     |   80       | Qualquer lugar   | 0.0.0.0/0   |
  | HTTPS         | TCP     |   443      | Qualquer Lugar   | 0.0.0.0/0   |

## 3° Passo: Crie uma Instância EC2 
### Características da EC2:
- Tags de permissão
- Distribuição: Amazon Linux
- Tipo: t2.micro
- aplicar o grupo de segurança criado para a EC2
- colocar o seguinte script user_data.sh no campo determinado em detalhes avançados
  
## 4° Passo: Crie um banco de dados RDS MySql:
## Características do RDS:

## 5° Passo: Crie um Elastic File System (EFS):
## Características do EFS:

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
