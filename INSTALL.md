# Manual de Instalação

Este documento descreve a instalação do TV RH Automático em Ubuntu Server 24.04 LTS.

## 1. Arquitetura da instalação

A instalação utiliza:

- `/srv/tv`: imagens e arquivo `config.txt`.
- `/var/www/tv`: aplicação web.
- Samba: acesso do RH à pasta.
- Apache e PHP: publicação da página e listagem das imagens.
- Smart TV: acesso pelo navegador.

## 2. Pré-requisitos

- Ubuntu Server 24.04 LTS instalado.
- Endereço IP fixo ou reserva DHCP.
- Acesso administrativo com `sudo`.
- Conectividade entre:
  - computador do RH e servidor na porta 445/TCP;
  - Smart TV e servidor na porta 80/TCP.
- DNS interno opcional, mas recomendado.

## 3. Identificar a configuração de rede

Execute:

```bash
ip -br address
ip route
resolvectl status
```

Anote:

```text
Interface:
Endereço IP:
Prefixo:
Gateway:
Servidores DNS:
```

Não copie diretamente os valores `10.0.2.16`, `10.0.2.1`, `8.8.8.8` ou `8.8.4.4` sem confirmar que são adequados à rede de destino.

## 4. Configurar IP estático

Em Ubuntu Server 24.04, identifique primeiro o arquivo Netplan:

```bash
ls -la /etc/netplan/
```

Faça backup:

```bash
sudo cp -a /etc/netplan /etc/netplan.backup.$(date +%Y%m%d-%H%M%S)
```

Exemplo:

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 10.0.2.16/24
      routes:
        - to: default
          via: 10.0.2.1
      nameservers:
        addresses:
          - 10.0.2.10
          - 10.0.2.11
```

Valide e aplique com segurança:

```bash
sudo netplan generate
sudo netplan try
```

Após confirmar:

```bash
sudo netplan apply
```

Validação:

```bash
ip -br address
ip route
ping -c 4 10.0.2.1
getent hosts github.com
```

## 5. Instalar Git e baixar o projeto

```bash
sudo apt update
sudo apt install -y git
```

Clone o repositório:

```bash
cd /opt
sudo git clone https://github.com/kemmukifo/tv-rh-automatico.git
sudo chown -R "$USER":"$USER" /opt/tv-rh-automatico
cd /opt/tv-rh-automatico
```

Confira a estrutura:

```bash
find . -maxdepth 3 -type f | sort
```

## 6. Revisar o projeto antes da instalação

Verifique se os arquivos web não estão vazios:

```bash
wc -c web/index.html web/listar-arquivos.php
sed -n '1,40p' web/index.html
sed -n '1,80p' web/listar-arquivos.php
```

O `index.html` deve possuir conteúdo HTML completo. Um arquivo com 0 ou 1 byte não é funcional.

Verifique IPs fixos no projeto:

```bash
grep -RniF '10.0.2.16' .
```

Substitua o IP quando necessário:

```bash
NOVO_IP="10.0.2.16"

sed -i "s/10\.0\.2\.16/${NOVO_IP}/g" scripts/setup.sh
sed -i "s/10\.0\.2\.16/${NOVO_IP}/g" README.md INSTALL.md USER_MANUAL.md
```

Revise o resultado:

```bash
grep -RniF "${NOVO_IP}" .
```

## 7. Instalação manual recomendada

A instalação manual é preferível enquanto o `setup.sh` não for idempotente e parametrizado.

### 7.1 Instalar pacotes

```bash
sudo apt update
sudo apt upgrade -y

sudo apt install -y \
  apache2 \
  curl \
  git \
  htop \
  libapache2-mod-php \
  nano \
  net-tools \
  php \
  samba \
  samba-common \
  smbclient \
  unzip \
  wget
```

### 7.2 Criar as pastas

```bash
sudo mkdir -p /srv/tv
sudo mkdir -p /var/www/tv
```

### 7.3 Criar o usuário do Samba

```bash
if ! id tvuser >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash tvuser
fi

sudo passwd tvuser
sudo smbpasswd -a tvuser
sudo smbpasswd -e tvuser
```

### 7.4 Configurar permissões

```bash
sudo chown -R tvuser:tvuser /srv/tv
sudo find /srv/tv -type d -exec chmod 0755 {} \;
sudo find /srv/tv -type f -exec chmod 0644 {} \;
```

A aplicação web será administrada pelo `root` e lida pelo Apache:

```bash
sudo chown -R root:www-data /var/www/tv
sudo find /var/www/tv -type d -exec chmod 0755 {} \;
sudo find /var/www/tv -type f -exec chmod 0644 {} \;
```

## 8. Configurar o Samba

Faça backup:

```bash
sudo cp -a /etc/samba/smb.conf \
  /etc/samba/smb.conf.backup.$(date +%Y%m%d-%H%M%S)
```

Adicione ao final de `/etc/samba/smb.conf`:

```ini
[TV]
    comment = Imagens da TV RH
    path = /srv/tv
    browseable = yes
    read only = no
    guest ok = no
    valid users = tvuser
    force user = tvuser
    force group = tvuser
    create mask = 0644
    force create mode = 0644
    directory mask = 0755
    force directory mode = 0755
```

Valide:

```bash
sudo testparm -s
```

Reinicie:

```bash
sudo systemctl enable --now smbd
sudo systemctl restart smbd
```

Teste local:

```bash
smbclient //localhost/TV -U tvuser
```

Dentro do prompt do Samba:

```text
ls
put arquivo-teste.txt
del arquivo-teste.txt
quit
```

## 9. Instalar a aplicação web

Antes de copiar, confirme que os arquivos possuem conteúdo:

```bash
test -s web/index.html || {
  echo "ERRO: web/index.html está vazio."
  exit 1
}

test -s web/listar-arquivos.php || {
  echo "ERRO: web/listar-arquivos.php está vazio."
  exit 1
}
```

Copie:

```bash
sudo install -o root -g www-data -m 0644 \
  web/index.html /var/www/tv/index.html

sudo install -o root -g www-data -m 0644 \
  web/listar-arquivos.php /var/www/tv/listar-arquivos.php

sudo install -o tvuser -g tvuser -m 0664 \
  config/config.txt /srv/tv/config.txt
```

## 10. Configurar o Apache

Crie `/etc/apache2/sites-available/tv.conf`:

```apache
<VirtualHost *:80>
    ServerName 10.0.2.16
    DocumentRoot /var/www/tv

    <Directory /var/www/tv>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    Alias /fotos/ /srv/tv/

    <Directory /srv/tv>
        Options -Indexes
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/tv-rh-error.log
    CustomLog ${APACHE_LOG_DIR}/tv-rh-access.log combined
</VirtualHost>
```

Substitua `10.0.2.16` pelo IP ou nome DNS real.

Ative o site:

```bash
sudo a2dissite 000-default.conf
sudo a2ensite tv.conf
sudo apache2ctl configtest
sudo systemctl enable --now apache2
sudo systemctl reload apache2
```

Valide os VirtualHosts:

```bash
sudo apache2ctl -S
```

## 11. Configurar firewall

Caso o UFW esteja ativo:

```bash
sudo ufw status verbose
```

Exemplo restringindo à rede `10.0.2.0/24`:

```bash
sudo ufw allow from 10.0.2.0/24 to any port 80 proto tcp
sudo ufw allow from 10.0.2.0/24 to any port 445 proto tcp
sudo ufw reload
```

Não exponha a porta 445/TCP à internet.

## 12. Testes finais

### Apache

```bash
curl -I http://127.0.0.1/
curl -sS http://127.0.0.1/ | head
```

### PHP

```bash
curl -sS http://127.0.0.1/listar-arquivos.php
```

A resposta esperada deve ser JSON válido.

Validação com PHP:

```bash
curl -sS http://127.0.0.1/listar-arquivos.php | php -r '
$data = json_decode(stream_get_contents(STDIN), true);
if (json_last_error() !== JSON_ERROR_NONE) {
    fwrite(STDERR, "JSON inválido\n");
    exit(1);
}
echo "JSON válido\n";
'
```

### Serviços

```bash
systemctl is-active apache2
systemctl is-active smbd
systemctl is-enabled apache2
systemctl is-enabled smbd
```

### Portas

```bash
sudo ss -lntp | grep -E ':(80|445)\b'
```

### Samba pelo Windows

No Explorador de Arquivos:

```text
\\10.0.2.16\TV
```

Credenciais:

```text
Usuário: tvuser
Senha: definida durante a instalação
```

### Smart TV

No navegador da TV:

```text
http://10.0.2.16/
```

## 13. Instalação pelo script

Execute apenas depois de revisar o conteúdo:

```bash
cd /opt/tv-rh-automatico
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

Limitações atuais do script:

- usa o IP `10.0.2.16` de forma fixa;
- adiciona configurações ao `smb.conf`, podendo duplicá-las;
- adiciona `ServerName` ao `apache2.conf` em cada execução;
- executa `apt upgrade -y`;
- exige interação para definir senhas;
- pressupõe execução a partir da raiz do repositório;
- não valida se os arquivos web estão vazios antes da cópia.

## 14. Pós-instalação

Crie uma imagem de teste:

```bash
ls -la /srv/tv
```

Copie uma imagem pela pasta Samba e valide:

```bash
find /srv/tv -maxdepth 1 -type f -printf '%f\n'
curl -sS http://127.0.0.1/listar-arquivos.php
```

Consulte [TROUBLESHOOTING.md](TROUBLESHOOTING.md) em caso de falha.
