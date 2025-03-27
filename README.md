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


### 1.4.1 Utilizando o Git Bash (pelo windows)
* Será necessário saber o IP público da sua instância
    * Você pode obte-lo na tela de instâncias
    * Pesquise por EC2
    * No menu esquerdo selecione "Instances"
    * Selecione a instância criada e veja o IP em "Details"

<img src="/images/Pegando IPv4.png"></img>


Na criação da "Key pair" o sistema já faz o download dela, no caso do windows ela vai para o diretório padrão de downloads, mas você pode move-la se preferir. (É necessário ter o Git instalado)
* Na pasta onde se encontra a sua chave clique com o botão direito e selecione "Open Git Bash here"
* Com o terminal do Git aberto digite o seguinte código (alterando o nome da chave e o ip)
```bash
ssh -i NOME_DA_CHAVE ubuntu@MEU_IP
```
* É necessário digitar "yes" para confirmar a conexão
Pronto, agora você ja está acessando a sua instância através do terminal do GIT

<img src="/images/Acesso_1.png"></img>
<img src="/images/Acesso_2.png"></img>
<img src="/images/Acesso_3.png"></img>


## Etapa 2: Como instalar e configurar o servidor web
* Instalar e iniciar servidor Nginx
    * Digite os Seguintes comandos no terminal

```bash
# Atualiza a lista de pacotes e instala atualizações disponíveis
sudo apt-get update -y && sudo apt-get upgrade -y

# Instala pacotes necessários: Nginx (servidor web), Vim (editor de texto) e UFW (firewall)
sudo apt-get install -y nginx vim ufw curl

# Inicia o serviço do Nginx e habilita para iniciar automaticamente no boot
sudo systemctl enable --now nginx

# Configuração do Firewall (UFW)
sudo ufw allow 22/tcp         # Permite SSH para evitar perda de conexão
sudo ufw allow 80/tcp         # Permite tráfego HTTP (porta 80)
sudo ufw allow 443/tcp        # Permite tráfego HTTPS (caso use SSL)
sudo ufw --force enable       # Ativa o firewall sem pedir confirmação
```

A página padrão que o servidor Nginx acessa está em
```bash
/var/www/html/index.nginx-debian.html
```
E você pode altera-la utilizando um editor de texto (vim), pelo comando
```bash
sudo vi index.nginx-debian.html
```
<img src="/images/Nginx1.png"></img>

É possível vizualizar a página pelo navegador utilizando o IPv4 público da EC2
<img src="/images/Nginx2.png"></img>


## Etapa 3: Como funciona o script de monitoramento
Agora que o servidor está configurado, vamos criar um script de monitoramento para verificar se o site está acessível. Caso o serviço falhe, ele registrará no log e enviará uma notificação via Discord, Telegram ou Slack.
* 3.1 Criando o script de monitoramento (o script completo e comentado está em "script_monitoramento_web.sh")
    * Para criação do script vamos utilizar um editor de texto (vim), escolha o nome do script e salve ele como ".sh" para que possa ser executado. O script deve ser iniciado na primeira linha com o comando "#!/bin/bash"
* 3.2 Criando um serviço no systemd
    * Aqui criamos um serviço que faz com que nosso script sempre inicie com a máquina/servidor, e o reinicie caso fique desativado.

### 3.1.1 Criação Webhook Discord
* Em um servidor do Discord crie um canal de texto (dê um nome)
* Clique com o botão direito do mouse no canal e selecione editar canal
    * Clique em "Integrações" e depois em "Criar webhook"
    * Dê um nome para seu bot, defina em quais canais ele ira operar, salve a URL e clique em "Salvar alterações"

    <img src="/images/Webhook1.png"></img>
    <img src="/images/Webhook2.png"></img>
    <img src="/images/Webhook3.png"></img>


### 3.1.2 Crie variáveis para controle, para falicitar acesso a links e a diretórios

```bash
# Definição de variáveis
URL="http://localhost"  # URL do servidor a ser monitorado (modifique se necessário)
LOG_DIR="/var/log/monitoramento_nginx"  # Diretório para armazenar os logs do monitoramento
LOG_FILE="$LOG_DIR/status.log"  # Arquivo de log onde os eventos serão registrados
SERVICE="nginx"  # Nome do serviço a ser monitorado
DISCORD_WH="COLOQUE_AQUI_O_LINK_DO_WEBHOOK"  # Webhook do Discord para alertas
CONT=0  # Variável de controle para evitar notificações repetidas
```


### 3.1.3 Crie uma função para enviar notificações
* Enviar mensagens pelo Discord utilizando o link do webhook
* criar variáveis para as mensagens

```bash
# Função para enviar mensagens ao Discord
send_discord_message() {
    local MENSAGEM="$1"
    
    # Envia a mensagem via webhook do Discord
    curl -s -o /dev/null -X POST -H "Content-Type: application/json" \
         -d "{\"content\": \"$MENSAGEM\"}" \
         "$DISCORD_WH"
}
MSG_OFFLINE="🚨 Alerta! O servidor está offline! 🔴"
```

### 3.1.4 Loop para verificação contínua
Uma parte do código para ficar monitoranto contínuamente o serviço/site, temos:
* Variáveis para salvar código de resposta do site e tempo atual
* Operadores condicionais para fazer o controle do script
* Comandos para registrar em LOG
* Comandos para reiniciar sistema e mandar mensagens para o Discord

```bash
# Loop infinito para monitoramento contínuo
while true; do
    # Faz uma requisição ao servidor e captura o código de resposta HTTP
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

    # Obtém a data e hora atuais para registro no log
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Verifica se o site está online
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "$TIMESTAMP - OK - Site está disponível" >> "$LOG_FILE"
        
        # Se for a primeira vez que o site está online desde o início do script, envia uma notificação
        if [ "$CONT" -eq 0 ]; then
            send_discord_message "🟢 Servidor Online"
            ((CONT++))
        fi
    else
        echo "$TIMESTAMP - ERRO - Site indisponível (Código do erro: $HTTP_CODE)" >> "$LOG_FILE"
        send_discord_message "$MSG_OFFLINE"

        # Loop para tentar reiniciar o serviço até que ele esteja ativo novamente
        while ! systemctl is-active --quiet "$SERVICE"; do
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

            # Tenta reiniciar o serviço
            sudo systemctl restart "$SERVICE"
            echo "$TIMESTAMP - Reiniciando o serviço $SERVICE" >> "$LOG_FILE"
            send_discord_message "$MSG_RESET"

            # Aguarda 5 segundos antes de verificar novamente se o serviço foi reiniciado
            sleep 5

            # Verifica se o serviço foi reiniciado com sucesso
            if systemctl is-active --quiet "$SERVICE"; then
                echo "$TIMESTAMP - Serviço $SERVICE reiniciado com sucesso" >> "$LOG_FILE"
                send_discord_message "$MSG_ONLINE"
            else
                echo "$TIMESTAMP - Falha ao reiniciar o serviço $SERVICE" >> "$LOG_FILE"
            fi
        done
    fi

    # Aguarda 60 segundos antes da próxima verificação
    sleep 60
```


### 3.1.5 Outros comandos
* Configura fuso horário
```bash
sudo timedatectl set-timezone America/Sao_Paulo
```

* Salva hora e data atual
```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
```

* Garante que o diretório para logs exista
```bash
sudo mkdir -p "$LOG_DIR"
```

Após a criação do script utilize o seguinte comando para que ele possa ser executado.

```bash
sudo chmod +x "NOME_DO_SCRIPT"
```

### 3.2.1 Local de criação
* Deve-se criar no seguinte diretório:
```bash
/etc/systemd/system
```
Dentro desse diretótio crie um arquivo com o editor de texto e salve com o nome terminando em ".service"

### 3.2.2
* Código para criação do serviço

```bash
[Unit]
# Descrição do serviço: Define o objetivo do serviço de monitoramento do nginx
Description=Monitoramento do serviço nginx

# Garante que o serviço só inicie após a rede estar disponível
After=network.target

[Service]
# Caminho para o script de monitoramento que será executado
ExecStart=/usr/bin/monitoramento_nginx/site_onoff.sh

# Define que o serviço deve ser reiniciado automaticamente caso pare
Restart=always

# Tempo de espera antes de tentar reiniciar o serviço
RestartSec=5

# Define que a saída padrão será registrada no journal do sistema
StandardOutput=journal

# Define que os erros do serviço serão registrados no journal do sistema
StandardError=journal

[Install]
# Garante que o serviço será iniciado no modo multiusuário, o que é comum em servidores
WantedBy=multi-user.target
```

Após a criação, utilize os seguintes comandos para recarregar o systemd, reconhecer o novo serviço, habilitar e iniciar o monitoramento.

```bash
sudo systemctl daemon-reload
sudo systemctl enable monitoramento_nginx.service
sudo systemctl start monitoramento_nginx.service
```


## Etapa 4: Como testar e validar a solução
Podemos testar o script de quatro formas:
* 4.1 Verificar se o site está online utilizando o IPv4 público da sua EC2
    * Digite o IP no navegador

<img src="/images/Teste_site.png"></img>


* 4.2 Verificar o arquivo de LOG para ver se está sendo armazenado

<img src="/images/LOG1.png"></img>


* 4.3 Desativar o serviço Nginx manualmente e verificar se o script reinicia ele automaticamente e grava no arquivo LOG

<img src="/images/LOG2.png"></img>


* 4.4 Verificar se o webhook está ativo

<img src="/images/Alert_Bot1.png"></img>
<img src="/images/Alert_Bot2.png"></img>


## Etapa Bônus: Utilizar User Data para inicializar scripts, HTML e Nginx junto com a máquina
O User Data na AWS permite a execução automática de scripts na primeira inicialização de uma instância EC2, facilitando a instalação de pacotes e configuração de serviços.
Todos os comandos manuais que fizemos foi colocado em apenas um arquivo **(script_automatizar.sh)**, o arquivo foi editado para que possa realizar todos os comandos e criar os diretórios e scripts que foram feitos manualmente.
Para utilizar o User Data basta apenas adicionar o arquivo de execução na hora da criação de instância, segue assim:
* Na criação da instância expanda a aba "Advances details"
* No final da página em "User data-optional" escolha adicional seu arquivo eu escrever o código diretamente (no caso estou adicionando o arquivo script_automatizar.sh - mudando apenas o link do webhook). Clique em "Launch instance"

<img src="/images/Bonus.png"></img>
<img src="/images/Bonus2.png"></img>



## Conclusão 
Esse projeto foi uma ótima experiência para aprofundar meus conhecimentos em Linux e dar os primeiros passos com AWS. Ao longo do processo, fui explorando desde comandos essenciais no Linux até a configuração de ferramentas de monitoramento para garantir que o servidor estivesse seguro e funcionando bem. Além disso, tive meu primeiro contato com a AWS, o que abriu minha visão para o potencial da computação em nuvem e como ela pode facilitar a escalabilidade e a gestão de infraestrutura.
Mais do que executar tarefas, aprendi a raciocinar sobre os problemas, buscar soluções eficientes e aprimorar minha capacidade de adaptação. Esse processo reforçou minha vontade de continuar evoluindo na área, sempre buscando aprofundar meu conhecimento e me tornar um profissional mais preparado para os desafios do mercado.

## Agradecimento 
Agradeço à equipe da Compass.UOL pela oportunidade de estágio, pelo suporte e pelo ambiente propício ao desenvolvimento deste projeto. Sou grato também aos meus colegas e mentores pelo conhecimento compartilhado, pelas trocas de experiências e pelo incentivo constante. Por fim, um agradecimento especial à minha família e amigos, pelo apoio incondicional, por acreditarem em mim e por estarem sempre ao meu lado, seja me motivando, ajudando nas dificuldades ou garantindo que eu não passasse fome.