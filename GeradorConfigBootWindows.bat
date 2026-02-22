@echo off
setlocal enabledelayedexpansion
title Ubuntu Autoinstall Wizard (Windows Version)

:INICIO
set "menu=0"
set "HOSTNAME="
set "USERNAME="
set "PASSWORD="
set "KEYBOARD=br"
set "TIMEZONE=America/Sao_Paulo"
set "OPT_REDE="
set "INTERACTIVE_LIST="
set "PACKAGES_BLOCK="
set "DISK_BLOCK=  storage: {layout: {name: lvm}}"

:MENU_LOOP
cls
echo =======================================================
echo           UBUNTU AUTOINSTALL CONFIG GENERATOR
echo =======================================================
if "%menu%"=="0" goto INTERFACE0
if "%menu%"=="1" goto INTERFACE1
if "%menu%"=="2" goto INTERFACE2
if "%menu%"=="3" goto INTERFACE3
if "%menu%"=="4" goto INTERFACE4
if "%menu%"=="5" goto INTERFACE5
if "%menu%"=="6" goto INTERFACE6
if "%menu%"=="7" goto INTERFACE7
if "%menu%"=="8" goto REVISAR
goto REVISAR

:INTERFACE0
set /p "HOSTNAME=1. Digite o Hostname: "
call :CONFIRM
goto MENU_LOOP

:INTERFACE1
set /p "USERNAME=2. Digite o Nome do Usuario: "
call :CONFIRM
goto MENU_LOOP

:INTERFACE2
echo 3. Digite a Senha (sera exibida no prompt):
set /p "PASSWORD="
call :CONFIRM
goto MENU_LOOP

:INTERFACE3
echo.
echo --- Configuracao de Teclado ---
echo 1) br (Padrao)
echo 2) Escolher manualmente na instalacao
set /p "opt_k="
if "%opt_k%"=="2" (
    set "KEYBOARD=br"
    set "INTERACTIVE_LIST=!INTERACTIVE_LIST! - identity"
) else (
    set /p "KEYBOARD=Digite o layout (ex: br): "
)
call :CONFIRM
goto MENU_LOOP

:INTERFACE4
set /p "TIMEZONE=5. Fuso Horario (ex: America/Sao_Paulo): "
call :CONFIRM
goto MENU_LOOP

:INTERFACE5
echo.
echo --- Configuracao de Rede ---
echo 1) Ethernet (Cabo) ^| 2) Wi-Fi
set /p "OPT_REDE=Escolha: "
set /p "q_st=Deseja IP Estatico? (s/n): "

if /i "%q_st%"=="s" (
    set /p "v_ip=   IP/CIDR: "
    set /p "v_gw=   Gateway: "
    set /p "v_dns=   DNS: "
    set "IP_DETAIL=addresses: [!v_ip!], routes: [{to: default, via: !v_gw!}], nameservers: {addresses: [!v_dns!]}"
) else (
    set "IP_DETAIL=dhcp4: true"
)

if "%OPT_REDE%"=="1" (
    set "REDE_BLOCK=      ethernets: { eth0: { match: { name: 'en*' }, !IP_DETAIL!, optional: true } }"
) else (
    set /p "w_s=   SSID: "
    set /p "w_p=   Senha: "
    set "REDE_BLOCK=      ethernets: { eth_auto: { match: { name: 'en*' }, dhcp4: true, optional: true } }, wifis: { wifi0: { match: { name: 'w*' }, access-points: { '!w_s!': { password: '!w_p!' } }, !IP_DETAIL! } }"
)
call :CONFIRM
goto MENU_LOOP

:INTERFACE6
set /p "pkgs=Digite os pacotes (ex: vim git): "
if not "%pkgs%"=="" (
    set "PACKAGES_BLOCK=  packages: [%pkgs: =,%]"
)
call :CONFIRM
goto MENU_LOOP

:INTERFACE7
echo.
echo --- Configuracao de Disco ---
echo 1) Automatico (LVM)
echo 2) Manual na Instalacao
set /p "opt_d=Opcao: "
if "%opt_d%"=="2" (
    set "DISK_BLOCK="
    set "INTERACTIVE_LIST=!INTERACTIVE_LIST! - storage"
) else (
    set "DISK_BLOCK=  storage: {layout: {name: lvm}}"
)
call :CONFIRM
goto MENU_LOOP

:REVISAR
cls
echo =======================================================
echo               REVISAO DAS CONFIGURACOES
echo =======================================================
echo 0. Hostname: %HOSTNAME%
echo 1. Usuario:  %USERNAME%
echo 3. Teclado:  %KEYBOARD%
echo 7. Disco:    %DISK_BLOCK%
echo =======================================================
echo Pressione ENTER para gravar ou o numero para alterar.
set /p "escolha=> "
if "%escolha%"=="" goto GRAVAR
set "menu=%escolha%"
goto MENU_LOOP

:GRAVAR
echo Gerando arquivos...
set "I_FINAL=  interactive-sections: []"
if not "%INTERACTIVE_LIST%"=="" (
    set "I_FINAL=  interactive-sections: [%INTERACTIVE_LIST: -=-%]"
    set "I_FINAL=!I_FINAL: -=-!"
    set "I_FINAL=!I_FINAL: =,!"
)

(
echo #cloud-config
echo autoinstall:
echo   version: 1
echo %I_FINAL%
if not "%PACKAGES_BLOCK%"=="" echo %PACKAGES_BLOCK%
if not "%DISK_BLOCK%"=="" echo %DISK_BLOCK%
echo   user-data:
echo     hostname: %HOSTNAME%
echo     username: %USERNAME%
echo     password: %PASSWORD%
echo   localization: {layout: %KEYBOARD%}
echo   timezone: %TIMEZONE%
echo   network:
echo     network:
echo       version: 2
echo %REDE_BLOCK%
) > user-data

type nul > meta-data
echo ✅ Arquivos 'user-data' e 'meta-data' gerados com sucesso!
pause
exit

:CONFIRM
set /p "c=Confirma? (S)im, (N)ao para repetir, (V)oltar: "
if /i "%c%"=="s" set /almenu+=1
if /i "%c%"=="v" set /almenu-=1
exit /b