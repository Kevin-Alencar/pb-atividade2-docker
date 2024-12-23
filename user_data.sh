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
