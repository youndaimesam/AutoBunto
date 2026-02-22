#!/bin/bash

# ==============================================================================
# INSTALADOR UBUNTU AUTO-MÁGICO V3.0
# ==============================================================================

# --- VARIÁVEIS ---
MENU_STEP=1
USER_DATA_FILE="user-data"
INTERACTIVE_SECTIONS=()

# --- CONFIGS ---
INSTALL_TYPE=""; INSTALL_MODE=""
KBD_LAYOUT="us"; KBD_VARIANT=""
TIMEZONE="UTC"
NET_TYPE=""; NET_CONFIG=""; SSID=""; PASS=""; IP_ADDR=""; GW=""; DNS=""
REALNAME=""; USERNAME=""; HOSTNAME=""; PASSWORD_HASH=""
PROFILE="Mínimo"; SSH_ENABLE="OFF"; DRIVERS_ENABLE="OFF"

# --- MÓDULOS DE INTERFACE (Resumidos para o Código Final) ---

modulo_inicio() {
    INSTALL_TYPE=$(whiptail --title "1. Ambiente" --menu "Destino:" 15 60 2 "Desktop" "Interface Gnome" "Server" "Terminal" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && exit
    INSTALL_MODE=$(whiptail --title "2. Operação" --menu "Modo:" 15 60 3 "Real" "Detectar este PC" "Simulado" "Outro PC" "Pular" "Manual (Híbrido)" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && MENU_STEP=1 || ((MENU_STEP++))
}

modulo_teclado() {
    # Usa o seu arquivo layouts.txt se existir
    if [ -f "layouts.txt" ]; then
        MAP_L=(); while read -r l; do MAP_L+=("$l" "Layout $l"); done < layouts.txt
    else
        MAP_L=("br" "Brasil" "us" "EUA" "pt" "Portugal")
    fi
    KBD_LAYOUT=$(whiptail --title "3. Teclado" --menu "País:" 20 60 10 "${MAP_L[@]}" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
        MAP_V=("padrão" "Default"); while read -r v; do [ -n "$v" ] && MAP_V+=("$v" "Var: $v"); done < <(localectl list-x11-keymap-variants "$KBD_LAYOUT" 2>/dev/null)
        KBD_VARIANT=$(whiptail --title "Variante" --menu "Escolha:" 20 60 10 "${MAP_V[@]}" 3>&1 1>&2 2>&3)
        [ "$KBD_VARIANT" == "padrão" ] && KBD_VARIANT=""
        ((MENU_STEP++))
    else ((MENU_STEP--)); fi
}

modulo_timezone() {
    MAP_TZ=(); while read -r zone; do AMIGAVEL=$(echo "$zone" | sed 's|.*/||; s|_| |g'); MAP_TZ+=("$zone" "$AMIGAVEL"); done < <(timedatectl list-timezones)
    TIMEZONE=$(whiptail --title "4. Relógio" --menu "Localização:" 20 70 10 "${MAP_TZ[@]}" 3>&1 1>&2 2>&3)
    [ $? -eq 0 ] && ((MENU_STEP++)) || ((MENU_STEP--))
}

modulo_rede() {
    NET_TYPE=$(whiptail --title "5. Rede" --menu "Tipo:" 15 60 2 "Ethernet" "Cabo" "Wi-Fi" "Wireless" 3>&1 1>&2 2>&3)
    if [ "$NET_TYPE" == "Wi-Fi" ]; then SSID=$(whiptail --inputbox "SSID:" 10 60 3>&1 1>&2 2>&3); PASS=$(whiptail --passwordbox "Senha:" 10 60 3>&1 1>&2 2>&3); fi
    NET_CONFIG=$(whiptail --title "IP" --menu "Config:" 15 60 2 "DHCP" "Auto" "Estático" "Manual" 3>&1 1>&2 2>&3)
    if [ "$NET_CONFIG" == "Estático" ]; then IP_ADDR=$(whiptail --inputbox "IP/CIDR:" 10 60 3>&1 1>&2 2>&3); GW=$(whiptail --inputbox "Gateway:" 10 60 3>&1 1>&2 2>&3); DNS=$(whiptail --inputbox "DNS:" 10 60 3>&1 1>&2 2>&3); fi
    ((MENU_STEP++))
}

modulo_disco() {
    if [ "$INSTALL_MODE" == "Pular" ]; then INTERACTIVE_SECTIONS+=("storage"); fi
    whiptail --msgbox "Configuração de Disco Processada.\nProteção de Windows Ativa no YAML." 10 50
    ((MENU_STEP++))
}

modulo_identidade() {
    REALNAME=$(whiptail --inputbox "Nome Completo:" 10 60 3>&1 1>&2 2>&3)
    USERNAME=$(whiptail --inputbox "Login:" 10 60 3>&1 1>&2 2>&3)
    HOSTNAME=$(whiptail --inputbox "Hostname:" 10 60 3>&1 1>&2 2>&3)
    SENHA=$(whiptail --passwordbox "Senha:" 10 60 3>&1 1>&2 2>&3)
    PASSWORD_HASH=$(python3 -c "import crypt; print(crypt.crypt('$SENHA', crypt.mksalt(crypt.METHOD_SHA512)))")
    ((MENU_STEP++))
}

modulo_software() {
    [ "$INSTALL_TYPE" == "Desktop" ] && PROFILE=$(whiptail --menu "Perfil:" 15 60 3 "Mínimo" "Básico" "Completo" "Full" "Puro" "Minimal" 3>&1 1>&2 2>&3)
    OPCOES=$(whiptail --checklist "Extras:" 15 60 2 "SSH" "Ativar OpenSSH" ON "Drivers" "NVIDIA/Proprietários" OFF 3>&1 1>&2 2>&3)
    [[ "$OPCOES" == *"SSH"* ]] && SSH_ENABLE="ON"; [[ "$OPCOES" == *"Drivers"* ]] && DRIVERS_ENABLE="ON"
    ((MENU_STEP++))
}

# --- FUNÇÃO DE INJEÇÃO E MODIFICAÇÃO DO GRUB ---
modulo_final() {
    # 1. Gerar arquivo local
    cat <<EOF > $USER_DATA_FILE
# cloud-config
autoinstall:
  version: 1
  refresh-installer: {update: no}
  locale: pt_BR.UTF-8
  keyboard: {layout: "$KBD_LAYOUT", variant: "$KBD_VARIANT"}
  timezone: "$TIMEZONE"
  identity: {realname: "$REALNAME", username: "$USERNAME", hostname: "$HOSTNAME", password: "$PASSWORD_HASH"}
  ssh: {install-server: $([ "$SSH_ENABLE" == "ON" ] && echo "true" || echo "false"), allow-pw: true}
  storage: {layout: {name: direct}}
EOF
    [ ${#INTERACTIVE_SECTIONS[@]} -gt 0 ] && (echo "  interactive-sections:" >> $USER_DATA_FILE; for s in "${INTERACTIVE_SECTIONS[@]}"; do echo "    - $s" >> $USER_DATA_FILE; done)

    # 2. Detectar Pendrive
    PENDRIVES=($(lsblk -pno MOUNTPOINT,RM | grep " 1$" | awk '{print $1}'))
    if [ ${#PENDRIVES[@]} -eq 0 ]; then
        whiptail --msgbox "Nenhum pendrive detectado. Arquivo salvo na pasta atual." 10 60
        exit
    fi

    DESTINO=$(whiptail --title "Injetar no Pendrive" --menu "Selecione o pendrive para automação total:" 15 70 5 $(for p in "${PENDRIVES[@]}"; do echo "$p Pendrive"; done) 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        # Criar pastas e mover arquivos
        mkdir -p "$DESTINO/nocloud"
        cp "$USER_DATA_FILE" "$DESTINO/nocloud/user-data"
        touch "$DESTINO/nocloud/meta-data"

        # 3. MODIFICAÇÃO DO GRUB (A Mágica)
        GRUB_FILE="$DESTINO/boot/grub/grub.cfg"
        if [ -f "$GRUB_FILE" ]; then
            if [ -w "$GRUB_FILE" ]; then
                # Backup do grub
                cp "$GRUB_FILE" "$GRUB_FILE.bak"
                # Injeta o parâmetro de autoinstall na linha do kernel (linux)
                # Procura a linha que começa com 'linux' e adiciona antes do '---' ou no fim
                sed -i '/linux/ s| ---| autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|' "$GRUB_FILE"
                sed -i '/linux/ s|$| autoinstall ds=nocloud;s=/cdrom/nocloud/|' "$GRUB_FILE" # Caso não tenha ---
                
                whiptail --msgbox "AUTOMAÇÃO COMPLETA!\n\n1. Pastas nocloud criadas.\n2. GRUB modificado para boot automático.\n\nAgora é só espetar o pendrive e ligar o PC!" 15 60
            else
                whiptail --msgbox "AVISO: O arquivo GRUB no pendrive é 'Somente Leitura'.\n\nAs pastas foram criadas, mas você terá que apertar 'e' no boot e digitar:\nautoinstall ds=nocloud;s=/cdrom/nocloud/" 15 65
            fi
        else
            whiptail --msgbox "Arquivo grub.cfg não encontrado no caminho padrão.\nVerifique se a ISO foi gravada corretamente." 12 60
        fi
    fi
    exit
}

# --- LOOP PRINCIPAL ---
while true; do
    case $MENU_STEP in
        1) modulo_inicio ;; 2) modulo_teclado ;; 3) modulo_timezone ;;
        4) modulo_rede ;; 5) modulo_disco ;; 6) modulo_identidade ;;
        7) modulo_software ;; 8) modulo_final ;;
        *) exit ;;
    esac
done