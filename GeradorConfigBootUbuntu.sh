#!/bin/bash
clear
echo "======================================================="
echo "            GERADOR DE CONFIGURAÇÃO BOOT (YAML)        "
echo "======================================================="
echo ""

# Determinando variáveis globais
HOSTNAME=""
USERNAME=""
PASSWORD=""
KEYBOARD=""
TIMEZONE=""
REDE_BLOCK=""
PROXY_BLOCK=""
PKGS_INPUT=""
PACKAGES_BLOCK=""
OPT_REDE=""
DISK_BLOCK=""
INTERACTIVE_LIST=""
menu=0

# Função de Confirmação e tratamento de erro
confirm(){
    local confirmacao=""
    echo ""
    read -n 1 -p "Voce confirma essas informações?(S)im, (N)ão para repetir ou (V)oltar " confirmacao
    echo ""

    if [[ "$confirmacao" == "S" || "$confirmacao" == "s" ]]; then
        ((menu++))
    elif [[ "$confirmacao" == "V" || "$confirmacao" == "v" ]]; then
        if [ $menu -gt 0 ]; then
            ((menu--))
        fi
    elif [[ "$confirmacao" == "N" || "$confirmacao" == "n" ]]; then
        echo "Repetindo etapa..."
    else
        echo "Opção inválida, repetindo operação!"
    fi
}

# Funções de chamada de menu
INTERFACE0(){
    read -p "1. Digite o nome da máquina (minusculas e hifens): " HOSTNAME
    confirm
}

INTERFACE1(){
    read -p "2. Digite o nome do usuário padrão: " USERNAME
    confirm
}

INTERFACE2(){
    read -s -p "3. Digite a senha do Usuário: " PASSWORD
    echo "" 
    confirm
}

INTERFACE3(){
    echo -e "\n--- Configuração de Teclado ---"
    echo "1) Definir agora (ex: br)"
    echo "2) Escolher manualmente na instalação"
    read -p "Opção: " OPT_KBD
    if [ "$OPT_KBD" == "2" ]; then
        KEYBOARD="br" # Fallback
        # Adiciona identidade à lista interativa (onde fica o teclado)
        [[ "$INTERACTIVE_LIST" != *"- identity"* ]] && INTERACTIVE_LIST="$INTERACTIVE_LIST\n    - identity"
    else
        read -p "4. Digite o Layout do Teclado (ex: br): " KEYBOARD
    fi
    confirm
}

INTERFACE4(){
    read -p "5. Fuso Horário (ex: America/Sao_Paulo): " TIMEZONE
    confirm
}

INTERFACE5(){
    echo -e "\n--- Configuração de Interface ---"
    echo "1) Ethernet (Cabo)"
    echo "2) Wi-Fi (Sem fio)"
    read -p "Escolha a interface: " OPT_REDE

    echo -e "\n--- Configuração de IP ---"
    read -p "Deseja IP Estático? (s/n): " QUER_STATIC
    
    if [ "$QUER_STATIC" == "s" ]; then
        read -p "   IP/CIDR (ex: 192.168.1.100/24): " VAR_IP
        read -p "   Gateway: " VAR_GW
        read -p "   DNS (ex: 8.8.8.8, 1.1.1.1): " VAR_DNS
        IP_DETAIL="addresses: [$VAR_IP]
          routes:
            - to: default
              via: $VAR_GW
          nameservers:
            addresses: [$VAR_DNS]"
    else
        IP_DETAIL="dhcp4: true"
    fi

    if [ "$OPT_REDE" == "1" ]; then
        REDE_BLOCK="      ethernets:
        eth0:
          match:
            name: \"en*\"
          $IP_DETAIL
          optional: true"
    else
        read -p "   SSID do Wi-Fi: " W_SSID
        read -p "   Senha do Wi-Fi: " W_PASS
        REDE_BLOCK="      ethernets:
        eth_auto:
          match:
            name: \"en*\"
          dhcp4: true
          optional: true
      wifis:
        wifi0:
          match:
            name: \"w*\"
          access-points:
            \"$W_SSID\":
              password: \"$W_PASS\"
          $IP_DETAIL"
    fi

    echo -e "\n--- Configuração de Proxy ---"
    read -p "Deseja configurar Proxy? (s/n): " QUER_PROXY
    if [ "$QUER_PROXY" == "s" ]; then
        read -p "   URL do Proxy: " P_URL
        PROXY_BLOCK="  proxy:
    http: $P_URL
    https: $P_URL"
    else
        PROXY_BLOCK=""
    fi
    confirm
}

INTERFACE6(){
    echo -e "\n--- Pacotes Extras ---"
    read -p "Digite os pacotes (ex: vim git htop): " PKGS_INPUT

    if [[ -z "$PKGS_INPUT" ]]; then
        PACKAGES_BLOCK=""
    else
        PKGS_READY=$(echo $PKGS_INPUT | sed 's/ /, /g')
        PACKAGES_BLOCK="  packages: [$PKGS_READY]"
    fi
    confirm
}

INTERFACE7(){
    echo -e "\n--- Configuração de Disco ---"
    echo "1) Apagar tudo automaticamente (LVM)"
    echo "2) Escolher disco manualmente na instalação"
    read -p "Opção: " OPT_DSK
    if [ "$OPT_DSK" == "2" ]; then
        DISK_BLOCK=""
        # Adiciona storage à lista interativa
        [[ "$INTERACTIVE_LIST" != *"- storage"* ]] && INTERACTIVE_LIST="$INTERACTIVE_LIST\n    - storage"
    else
        DISK_BLOCK="  storage:
    layout:
      name: lvm"
    fi
    confirm
}

GRAVAR(){
    clear
    echo "Gerando arquivo YAML..."
    
    # Monta a seção de interatividade
    if [ -z "$INTERACTIVE_LIST" ]; then
        INTERACTIVE_FINAL="  interactive-sections: []"
    else
        INTERACTIVE_FINAL="  interactive-sections:$INTERACTIVE_LIST"
    fi

    cat <<EOF > user-data
#cloud-config
autoinstall:
  version: 1
$INTERACTIVE_FINAL
$PROXY_BLOCK
$PACKAGES_BLOCK
$DISK_BLOCK
  user-data:
    hostname: $HOSTNAME
    username: $USERNAME
    password: $(echo "$PASSWORD" | openssl passwd -6 -stdin)
  localization:
    layout: $KEYBOARD
  timezone: $TIMEZONE
  network:
    network:
      version: 2
$REDE_BLOCK
EOF
    touch meta-data
    echo "✅ Arquivo 'user-data' e 'meta-data' gerados!"
    exit 0
}

REVISAR(){
    while true; do
        clear
        echo "======================================================="
        echo "               REVISÃO DAS CONFIGURAÇÕES                "
        echo "======================================================="
        echo "0. Hostname:      $HOSTNAME"
        echo "1. Usuário:       $USERNAME"
        echo "2. Senha:         (Definida)"
        echo "3. Teclado:       $KEYBOARD $([[ "$INTERACTIVE_LIST" == *"- identity"* ]] && echo "(MANUAL)")"
        echo "4. Fuso Horário:  $TIMEZONE"
        echo "5. Rede/Proxy:    ${OPT_REDE:-Não configurado}"
        echo "6. Apps Extras:   ${PKGS_INPUT:-Nenhum}"
        echo "7. Disco:         $([[ "$INTERACTIVE_LIST" == *"- storage"* ]] && echo "MANUAL" || echo "AUTOMÁTICO")"
        echo "======================================================="
        echo "Digite o número (0-7) para alterar ou [ENTER] para gravar:"
        read -p "> " escolha

        if [[ -z "$escolha" ]]; then
            GRAVAR
        elif [[ "$escolha" =~ ^[0-7]$ ]]; then
            # Reseta a lista interativa ao editar para evitar duplicatas ou lixo
            INTERACTIVE_LIST=""
            "INTERFACE$escolha"
        else
            echo "Opção inválida!"
            sleep 1
        fi
    done
}

# --- Ciclo de Execução Principal ---
for (( ; menu < 8; ))
do
    if (( menu < 0 )); then menu=0; fi
    "INTERFACE$menu"
done
REVISAR
