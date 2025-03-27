# Servidor Web com Monitoramento 
### Desenvolver e testar habilidades em Linux, AWS e automação de processos através da configuração de um ambiente de servidor web monitorado. 
## Sobre
Este projeto visa configurar uma instância EC2 na AWS (Amazon Web Service), subindo um site no servidor Nginx. Devemos criar um script de monitoramento deste site em um ambiente Linux, que faça a verificação se o site está disponível a cada um minuto, deve-se criar um arquivo LOG para armazenar a execução do script, e em caso de falha do serviço devemos enviar uma notificação por algum canal (Discord, Telegram ou Slack).

## Ferramentas utilizadas
* AWS
* Nginx
* Linux

## Etapa 1: Confuiguração do ambiente
Para configurar o ambiente na AWS vamos seguir as seguintes etapas:
* 1.1 - Criar uma VPC
* 1.2 - Criar um Security Group
* 1.3 - Criar e subir a instância EC2
* 1.4 - Acessar o ambiente criado

### 1.1.1 Abra o console e pesquise por VPC na aba de pesquisa

<img src="/images/VPC_SecurityGroup.png"></img>

### 1.1.2 No menu ao lado esquerdo clique em "Your VPCs", depois em "Create VPC" na parte superior direita

<img src="/images/Criar_VPC1.png"></img>

### 1.1.3 Nas consigurações selecione:
* "VPC and more"
* "Auto-generete" (escolha um nome para o seu grupo)
* IPv4 deixe como "10.0.0.0/16"
* "No IPv6 CIDR block"
* Availability Zones "2"
* Number of public subnets "2"
* Number of private subnets "2"
* NAT gateways "None"
* VPC endpoints "S3 Gateway"
* "Enable DNS hostnames"
* "Enable DNS resolution"
* Clique em "Create VPC"

<img src="/images/Criar_VPC2.png"></img>
<img src="/images/Criar_VPC3.png"></img>
<img src="/images/Criar_VPC4.png"></img>

### 1.2.1 Abra o console e pesquise por VPC na aba de pesquisa

<img src="/images/VPC_SecurityGroup.png"></img>

### 1.2.2 No menu ao lado esquerdo clique em "Security groups", depois em "Create security group" na parte superior direita

<img src="/images/Criar_security_group1.png"></img>

### 1.2.3 Nas consigurações selecione:
* Security group name (Dê um nome para seu security group)
* Description (Descrição)
* VPC (Selecione a VPC criada)
* Inbound rules
    * Crie um tipo "SSH", com Source "My IP"
    * Crie um tipo "HTTP", com Source "My IP"
* Outbound rules
    * Crie um tipo "All traffic", com Source "Anywhere-IPv4"
* Clique em "Create security group"

<img src="/images/Criar_security_group2.png"></img>
<img src="/images/Criar_security_group3.png"></img>

### 1.3.1 Abra o console e pesquise por EC@ na aba de pesquisa

<img src="/images/EC2.png"></img>

### 1.3.2 No menu ao lado esquerdo clique em "Instances", depois em "Launch instances" na parte superior direita

<img src="/images/EC2_1.png"></img>

### 1.3.3 Nas consigurações selecione:
* Tags para identificação
* O sistema a ser utilizado
* O tipo de instância (utilizei t2.micro)
* Crie e selecione sua Key pair
    * Key pair name (Escolha um nome)
    * "RSA"
    * ".pem"
    * Clique em "Create Key pair"
* Em Network settings
    * Selecione a VPC criada
    * Selecione um subnet publica
    * Auto-assign public IP - "Enable"
    * Selecione o Security group criado
    * Clique em "Launch instance"

<img src="/images/EC2_2.png"></img>
<img src="/images/EC2_3.png"></img>
<img src="/images/EC2_4.png"></img>
<img src="/images/EC2_5.png"></img>
<img src="/images/EC2_6.png"></img>

### 1.4.1 



## Etapa 2: Como instalar e confugurar o servidor web

## Etapa 3: Como funciona o script de monitoramento

## Etapa 4: Como testar e validar a solução

## Agradecimento 
Obrigado pela atenção! 