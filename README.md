# 🖥️ TV RH Automático

Sistema corporativo para exibição de imagens em looping em TVs, com compartilhamento de arquivos via Samba e controle de velocidade via arquivo de configuração.

## 🎯 Objetivo

Permitir que o time de RH gerencie imagens exibidas na TV sem precisar de conhecimento técnico.

## 🚀 Funcionalidades

- 📸 Exibição de imagens em looping
- 📁 Pasta compartilhada para o RH (Samba)
- ⏱️ Controle de velocidade via `config.txt`
- 🌐 Acesso via navegador
- 📡 Atualização automática (1 minuto)

## 📚 Manuais

- [Manual de Instalação](INSTALL.md)
- [Manual do Usuário](USER_MANUAL.md)

## 🛠️ Tecnologias

- **Ubuntu Server 24.04 LTS**
- **Apache 2.4**
- **PHP 8.x**
- **Samba 4.x**
- **HTML + CSS + JavaScript**

## 📦 Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `web/index.html` | Página principal da TV |
| `web/listar-arquivos.php` | Endpoint que lista imagens e retorna configuração |
| `samba/smb.conf` | Configuração do Samba |
| `config/config.txt` | Arquivo de configuração padrão |

## 🔧 Como usar

1. Clone este repositório
2. Execute `scripts/setup.sh` (ou siga o [Manual de Instalação](INSTALL.md))
3. Acesse a pasta `\\10.0.2.16\TV` e coloque imagens
4. Abra `http://10.0.2.16/` na TV

---

📝 **Autor:** [Seu Nome]  
📅 **Data:** Agosto 2026
