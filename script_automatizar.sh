#!/bin/bash

# Atualiza a lista de pacotes e instala atualizações disponíveis
sudo apt-get update -y && sudo apt-get upgrade -y

# Instala pacotes necessários: Nginx (servidor web), Vim (editor de texto) e UFW (firewall)
sudo apt-get install -y nginx vim ufw curl

# Inicia o serviço do Nginx e habilita para iniciar automaticamente no boot
sudo systemctl enable --now nginx

# Configuração do Firewall (UFW)
sudo ufw allow 22/tcp         # Permite SSH para evitar perda de conexão
sudo ufw allow 80             # Permite tráfego HTTP (porta 80)
sudo ufw allow 443            # Permite tráfego HTTPS (caso use SSL)
sudo ufw --force enable       # Ativa o firewall sem pedir confirmação'

# Diretório e arquivo do serviço systemd
SYSTEMD_DIR="/etc/systemd/system"
SYSTEMD_FILE="$SYSTEMD_DIR/monitoramento_nginx.service"

# Diretório e arquivo do script de monitoramento
SCRIPT_DIR="/usr/bin/monitoramento_nginx"
SCRIPT_FILE="$SCRIPT_DIR/site_onoff.sh"

# Cria o diretório do systemd caso não exista e define permissões
sudo mkdir -p "$SYSTEMD_DIR"
sudo chmod +x "$SYSTEMD_DIR"

# Cria o diretório do script caso não exista e define permissões
sudo mkdir -p "$SCRIPT_DIR"
sudo chmod +x "$SCRIPT_DIR"

# Cria o script de monitoramento do Nginx
cat << 'EOF' | sudo tee "$SCRIPT_FILE" > /dev/null
#!/bin/bash

# Definição de variáveis principais
URL="http://localhost"  # URL do servidor a ser monitorado
LOG_DIR="/var/log/monitoramento_nginx"  # Diretório para armazenar os logs
LOG_FILE="$LOG_DIR/status.log"  # Arquivo de log onde os eventos serão registrados
SERVICE="nginx"  # Nome do serviço a ser monitorado
DISCORD_WH="https://discord.com/api/webhooks/1354699626762076343/QQO0mqB9zjpyoPZgc_7-UNs3S6y1ZeR7pC0-wtBpD7JwL4KkCCDZpwCxU0oafIoZysoj"  # Webhook do Discord para alertas
CONT=0  # Variável de controle para evitar notificações repetidas

# Definição das mensagens enviadas ao Discord
MSG_OFFLINE="🚨 Alerta! O servidor está offline! 🔴"
MSG_ONLINE="✅ Servidor voltou ao ar! 🟢"
MSG_RESET="🔄 Reiniciando servidor ..."

# Configuração do fuso horário para São Paulo
sudo timedatectl set-timezone America/Sao_Paulo

# Função para enviar mensagens ao Discord
send_discord_message() {
    local MENSAGEM="$1"
    
    # Envia a mensagem via webhook do Discord
    curl -s -o /dev/null -X POST -H "Content-Type: application/json" \
         -d "{\"content\": \"$MENSAGEM\"}" \
         "$DISCORD_WH"
}

# Garante que o diretório de logs exista
mkdir -p "$LOG_DIR"
chmod +x "$LOG_DIR"
mkdir -p "$LOG_FILE"
chmod +x "$LOG_FILE"

# Aguarda um tempo inicial antes de iniciar o monitoramento
sleep 10

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
done
EOF

sleep 2

# Define a página HTML para o site
SITE_HTML="/var/www/html/index.nginx-debian.html"

# Criação do conteúdo HTML para exibição no servidor
cat << EOF | sudo tee "$SITE_HTML" > /dev/null
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Projeto DevSecOps - Marcos Moreira</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
            color: #333;
        }
        header {
            background-color: #005792;
            color: white;
            text-align: center;
            padding: 20px;
        }
        .container {
            width: 80%;
            margin: auto;
            padding: 20px;
            background: white;
            box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
            border-radius: 10px;
        }
        h2 {
            color: #005792;
        }
        ul {
            line-height: 1.6;
        }
        footer {
            text-align: center;
            padding: 20px;
            background: #333;
            color: white;
            margin-top: 20px;
        }
        a {
            color: #005792;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <header>
        <h1>Projeto DevSecOps - Configuração de Servidor Web</h1>
    </header>
    <div class="container">
        <h2>Sobre o Projeto</h2>
        <p>Este projeto tem como objetivo praticar a configuração de servidores web e automação no ambiente Linux e AWS. A proposta é implementar um servidor Nginx em uma instância EC2, garantindo monitoramento contínuo e notificações em caso de falhas.</p>
        <h2>Etapas do Projeto</h2>
        <h3>1. Configuração do Ambiente</h3>
        <ul>
            <li>Criar uma VPC na AWS com 2 sub-redes públicas e 2 privadas.</li>
            <li>Configurar uma instância EC2 com Ubuntu ou Amazon Linux.</li>
            <li>Associar um Security Group permitindo tráfego HTTP e SSH.</li>
        </ul>

        <h3>2. Configuração do Servidor Web</h3>
        <ul>
            <li>Instalar e configurar o Nginx na instância EC2.</li>
            <li>Criar uma página HTML para exibição no servidor.</li>
        </ul>

        <h3>3. Monitoramento e Notificações</h3>
        <ul>
            <li>Criar um script para verificar a disponibilidade do site a cada 1 minuto.</li>
            <li>Registrar logs da execução do script.</li>
            <li>Enviar notificações para Discord, Telegram ou Slack em caso de falhas.</li>
        </ul>
        <h3>4. Testes e Documentação</h3>
        <ul>
            <li>Testar o ambiente e validar a configuração.</li>
            <li>Documentar o processo e disponibilizar no GitHub.</li>
        </ul>

        <h2>Mais Informações</h2>
        <p>A documentação completa esta disponível no meu repositório do GitHub. <br> Acesse: <a href="https://github.com/hmindiano/MonitoramentoWeb-DevSecOps-Compass/" target="_blank">GitHub Marcos Moreira</a></p>
    </div>
    <footer>
        <p>Desenvolvido por Marcos Moreira | Estudante de ADS - Fatec Mogi Mirim | Projeto para estágio Compass.UOL</p>
    </footer>
</body>
</html>
EOF

sleep 2

# Define permissões de execução para o script de monitoramento
sudo chmod +x "$SCRIPT_FILE"

# Criação do serviço systemd para monitoramento do Nginx
cat << EOF | sudo tee "$SYSTEMD_FILE" > /dev/null
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

# Define que a saída padrão será registrada no journal do sistema
StandardOutput=journal

# Define que os erros do serviço serão registrados no journal do sistema
StandardError=journal

[Install]
# Garante que o serviço será iniciado no modo multiusuário, o que é comum em servidores
WantedBy=multi-user.target
EOF

# Recarrega o systemd para reconhecer o novo serviço, habilita e inicia o monitoramento
sudo systemctl daemon-reload
sudo systemctl enable monitoramento_nginx.service
sudo systemctl start monitoramento_nginx.service