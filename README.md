# AutoBunto
# 🚀 Ubuntu Autoinstall Config Wizard

Um assistente interativo em linha de comando para gerar arquivos de configuração (`user-data` e `meta-data`) para o instalador automatizado do Ubuntu (Subiquity).

## ✨ Funcionalidades

- **Híbrido**: Escolha entre automação total ou decidir o particionamento de disco e teclado durante a instalação.
- **Rede Flexível**: Configuração fácil para Ethernet ou Wi-Fi, com suporte a DHCP ou IP Estático.
- **Segurança**: Senhas criptografadas em hash SHA-512 (na versão Linux).
- **Multiplataforma**: Scripts disponíveis para **Bash (Linux/macOS)** e **Batch (Windows)**.
- **Pacotes Personalizados**: Instale seus apps favoritos (`git`, `vim`, `docker`, etc) automaticamente no primeiro boot.

## 🛠️ Como usar

### No Linux/macOS:
1. Dê permissão de execução:
   ```bash
   chmod +x GeradorConfigBoot.sh
2. Execute com o comando:
   ```bash
   ./GeradorConfigBoot.sh
