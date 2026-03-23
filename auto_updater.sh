#!/bin/bash

# ==========================================================
# ILLIMITAR - SERVIÇO DE ATUALIZAÇÃO EM SEGUNDO PLANO
# ==========================================================

# 1. Link direto (RAW) para o seu arquivo de versão no Git
URL_CHECK="https://SEU_GIT_AQUI/raw/main/versao_pdv.txt"

# 2. Busca as informações silenciosamente no fundo
REMOTE_INFO=$(curl -s "$URL_CHECK")
REMOTE_VER=$(echo "$REMOTE_INFO" | grep "VERSAO=" | cut -d= -f2 | tr -d '\r')
REMOTE_URL=$(echo "$REMOTE_INFO" | grep "URL=" | cut -d= -f2 | tr -d '\r')

# 3. Descobre a versão instalada na máquina
LOCAL_VER=$(dpkg-query -W -f='${Version}' pdv 2>/dev/null)

# Se estiver sem internet ou o arquivo falhar, aborta silenciosamente
[ -z "$REMOTE_VER" ] && exit 0
[ -z "$LOCAL_VER" ] && exit 0

# 4. Compara as versões. Se a local for menor (lt - less than) que a remota, atualiza!
if dpkg --compare-versions "$LOCAL_VER" "lt" "$REMOTE_VER"; then
    
    # Inicia a Interface Gráfica com Barra de Progresso (Zenity)
    (
        echo "10"
        echo "# 🚀 Identificada nova atualização do PDV!\n\nVersão Atual: $LOCAL_VER\nNova Versão:  $REMOTE_VER\n\nBaixando os arquivos..."
        
        # Baixa o pacote para a pasta temporária
        wget --no-check-certificate -qO /tmp/pdv_update.deb "$REMOTE_URL"
        
        echo "60"
        echo "# 📦 Instalando a nova versão...\nPor favor, não desligue o computador."
        
        # Instala usando a permissão especial de root (sem pedir senha)
        sudo dpkg -i /tmp/pdv_update.deb > /dev/null 2>&1
        
        echo "90"
        echo "# 🧹 Limpando arquivos temporários..."
        rm -f /tmp/pdv_update.deb
        
        echo "100"
        echo "# ✅ Atualização concluída com sucesso!"
        sleep 3
        
    ) | zenity --progress \
               --title="ILLIMITAR Soluções - Atualizador Automático" \
               --text="Iniciando verificação..." \
               --percentage=0 \
               --auto-close \
               --no-cancel \
               --width=450

    # Opcional: Após atualizar, já abre o PDV sozinho para o caixa começar a trabalhar
    /opt/pdv/pdv &
fi
