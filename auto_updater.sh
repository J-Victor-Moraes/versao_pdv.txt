#!/bin/bash

# ==========================================================
# ILLIMITAR - GATEKEEPER E ATUALIZADOR DO PDV
# ==========================================================

SENHA_ROOT="user@15"
URL_CHECK="https://raw.githubusercontent.com/J-Victor-Moraes/versao_pdv.txt/main/versao_pdv.txt"

REMOTE_INFO=$(curl -s "$URL_CHECK")
REMOTE_VER=$(echo "$REMOTE_INFO" | grep "^VERSAO=" | cut -d= -f2- | tr -d '\r"')
REMOTE_URL=$(echo "$REMOTE_INFO" | grep "^URL=" | cut -d= -f2- | tr -d '\r"')

LOCAL_VER=$(dpkg-query -W -f='${Version}' pdv 2>/dev/null)

# Se estiver sem internet ou der erro na leitura, ABRE O PDV e encerra o script.
if [ -z "$REMOTE_VER" ] || [ -z "$LOCAL_VER" ]; then
    /opt/pdv/pdv > /dev/null 2>&1 &
    exit 0
fi

# Se a versão local for menor, inicia o processo de atualização
if dpkg --compare-versions "$LOCAL_VER" "lt" "$REMOTE_VER"; then
    (
        echo "10"
        echo "# 🚀 Identificada nova atualização do PDV!\n\nVersão Atual: $LOCAL_VER\nNova Versão:  $REMOTE_VER\n\nBaixando os arquivos..."
        wget --no-check-certificate -qO /tmp/pdv_update.deb "$REMOTE_URL"
        
        echo "40"
        echo "# 🔒 Realizando backup e instalando..."
        
        echo "$SENHA_ROOT" | sudo -S bash -c '
            [ -f /opt/pdv/pdv.ini ] && cp /opt/pdv/pdv.ini /home/user/pdv.ini.bak
            [ -f /usr/lib/CONFITLS.INI ] && cp /usr/lib/CONFITLS.INI /home/user/CONFITLS.INI.bak
            
            dpkg -i /tmp/pdv_update.deb > /dev/null 2>&1
            apt-get install -f -y > /dev/null 2>&1
            
            mkdir -p /opt/pdv
            [ -f /home/user/pdv.ini.bak ] && cp /home/user/pdv.ini.bak /opt/pdv/pdv.ini
            [ -f /home/user/CONFITLS.INI.bak ] && cp /home/user/CONFITLS.INI.bak /usr/lib/CONFITLS.INI
            
            chmod 666 /opt/pdv/pdv.ini 2>/dev/null
            chmod 666 /usr/lib/CONFITLS.INI 2>/dev/null
        ' 2>/dev/null
        
        echo "90"
        echo "# 🧹 Limpando arquivos temporários..."
        rm -f /tmp/pdv_update.deb /home/user/pdv.ini.bak /home/user/CONFITLS.INI.bak
        
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
fi

# Ao final de tudo (seja porque atualizou, ou porque a versão já era a mais recente), ABRE O PDV:
/opt/pdv/pdv > /dev/null 2>&1 &
exit 0
