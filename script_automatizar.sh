#!/bin/bash

# Atualiza a lista de pacotes e instala atualizações disponíveis
sudo apt-get update -y
sudo apt-get upgrade -y

# Instala pacotes necessários: Nginx (servidor web), Vim (editor de texto) e UFW (firewall)
sudo apt-get install -y nginx vim ufw

# Inicia o serviço do Nginx e o habilita para iniciar automaticamente no boot
sudo systemctl start nginx
sudo systemctl enable nginx

# Ativa o firewall UFW e permite conexões HTTP para o Nginx
sudo ufw enable
ufw allow 'nginx HTTP'

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
DISCORD_WH="COLOQUE_AQUI_O_LINK_DO_WEBHOOK"  # Webhook do Discord para alertas
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
sudo mkdir -p "$LOG_DIR"

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

# Define permissões de execução para o script de monitoramento
sudo chmod +x "$SCRIPT_FILE"

# Criação do serviço systemd para monitoramento do Nginx
cat << EOF | sudo tee "$SYSTEMD_FILE" > /dev/null
[Unit]
Description=Monitoramento do serviço nginx
After=network.target

[Service]
ExecStart=/usr/bin/monitoramento_nginx/site_onoff.sh
Restart=always
RestartSec=5
User=nobody
Group=nogroup
StandardOutput=append:/var/log/monitoramento_nginx/status.log
StandardError=append:/var/log/monitoramento_nginx/status.log

[Install]
WantedBy=multi-user.target
EOF

# Recarrega o systemd para reconhecer o novo serviço, habilita e inicia o monitoramento
sudo systemctl daemon-reload
sudo systemctl enable monitoramento_nginx.service
sudo systemctl start monitoramento_nginx.service