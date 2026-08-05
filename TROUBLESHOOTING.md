# Troubleshooting

Este documento utiliza uma abordagem investigativa: hipótese, validação, interpretação e correção.

## Coleta inicial

Execute:

```bash
echo "===== REDE ====="
ip -br address
ip route

echo
echo "===== SERVIÇOS ====="
systemctl is-active apache2 smbd
systemctl --failed

echo
echo "===== PORTAS ====="
sudo ss -lntp | grep -E ':(80|445)\b' || true

echo
echo "===== APACHE ====="
sudo apache2ctl configtest
sudo apache2ctl -S

echo
echo "===== SAMBA ====="
sudo testparm -s

echo
echo "===== ARQUIVOS ====="
sudo find /var/www/tv -maxdepth 1 -type f -printf '%M %u:%g %s %p\n'
sudo find /srv/tv -maxdepth 1 -type f -printf '%M %u:%g %s %p\n'
```

## Página retorna 404

### Hipótese 1: URL incorreta

Se o `DocumentRoot` é `/var/www/tv`, normalmente a URL é:

```text
http://10.0.2.16/
```

e não:

```text
http://10.0.2.16/tv/
```

Valide:

```bash
curl -v http://127.0.0.1/
curl -v http://127.0.0.1/tv/
```

### Hipótese 2: VirtualHost incorreto

```bash
sudo apache2ctl -S
sudo cat /etc/apache2/sites-enabled/tv.conf
```

O `DocumentRoot` deve apontar para:

```text
/var/www/tv
```

### Hipótese 3: arquivo inexistente ou vazio

```bash
ls -lah /var/www/tv/
wc -c /var/www/tv/index.html
```

Interpretação:

- `No such file`: arquivo não foi instalado.
- `0` ou `1` byte: arquivo está vazio.
- tamanho normal: prossiga para permissões e logs.

### Correção

```bash
sudo install -o root -g www-data -m 0644 \
  web/index.html /var/www/tv/index.html

sudo apache2ctl configtest
sudo systemctl reload apache2
```

## Página abre, mas não mostra imagens

### Hipótese 1: endpoint PHP falhando

```bash
curl -v http://127.0.0.1/listar-arquivos.php
```

A resposta deve ser JSON.

Confira erros:

```bash
sudo tail -n 100 /var/log/apache2/tv-rh-error.log
sudo journalctl -u apache2 -n 100 --no-pager
```

### Hipótese 2: PHP não está instalado ou habilitado

```bash
php -v
apache2ctl -M | grep php
dpkg -l | grep -E 'php|libapache2-mod-php'
```

Correção:

```bash
sudo apt install -y php libapache2-mod-php
sudo systemctl restart apache2
```

### Hipótese 3: alias `/fotos/` incorreto

```bash
grep -RniE 'Alias|Directory' /etc/apache2/sites-enabled/
curl -I http://127.0.0.1/fotos/NOME_DA_IMAGEM.jpg
```

O alias recomendado:

```apache
Alias /fotos/ /srv/tv/
```

### Hipótese 4: permissões

```bash
namei -l /srv/tv
sudo -u www-data test -r /srv/tv/NOME_DA_IMAGEM.jpg \
  && echo "Leitura OK" \
  || echo "Sem leitura"
```

Correção:

```bash
sudo chown -R tvuser:tvuser /srv/tv
sudo find /srv/tv -type d -exec chmod 0755 {} \;
sudo find /srv/tv -type f -exec chmod 0644 {} \;
```

## Samba não abre no Windows

### Hipótese 1: serviço parado

```bash
systemctl status smbd --no-pager
sudo journalctl -u smbd -n 100 --no-pager
```

Correção:

```bash
sudo systemctl enable --now smbd
```

### Hipótese 2: configuração inválida

```bash
sudo testparm -s
```

Corrija qualquer erro antes de reiniciar:

```bash
sudo systemctl restart smbd
```

### Hipótese 3: porta bloqueada

No servidor:

```bash
sudo ss -lntp | grep ':445'
sudo ufw status verbose
```

No Windows PowerShell:

```powershell
Test-NetConnection 10.0.2.16 -Port 445
```

Interpretação:

- `TcpTestSucceeded: True`: rede e porta estão acessíveis.
- `False`: investigar rota, ACL, firewall ou serviço.

### Hipótese 4: credenciais antigas do Windows

```cmd
net use
net use \\10.0.2.16\TV /delete
cmdkey /list
```

Reconecte:

```cmd
net use \\10.0.2.16\TV /user:tvuser *
```

### Hipótese 5: usuário Samba ausente

```bash
id tvuser
sudo pdbedit -L | grep '^tvuser:'
```

Correção:

```bash
sudo smbpasswd -a tvuser
sudo smbpasswd -e tvuser
```

## Acesso negado ao copiar imagens

Valide permissões:

```bash
ls -ld /srv/tv
getfacl /srv/tv
```

Teste como `tvuser`:

```bash
sudo -u tvuser touch /srv/tv/.teste-escrita
sudo -u tvuser rm /srv/tv/.teste-escrita
```

Correção:

```bash
sudo chown -R tvuser:tvuser /srv/tv
sudo chmod 0755 /srv/tv
```

## Alteração no config.txt não foi aplicada

Confira o conteúdo:

```bash
cat -n /srv/tv/config.txt
```

Formato esperado:

```ini
TEMPO_ENTRE_IMAGENS = 5
```

Teste o endpoint:

```bash
curl -sS http://127.0.0.1/listar-arquivos.php
```

Verifique se `config.tempo` mudou no JSON.

Possíveis causas:

- linha digitada incorretamente;
- valor fora de 1 a 300;
- endpoint PHP não lê `/srv/tv/config.txt`;
- cache do navegador;
- página não atualiza a configuração;
- arquivo sem permissão de leitura.

## Imagem específica não aparece

```bash
file "/srv/tv/NOME_DO_ARQUIVO"
stat "/srv/tv/NOME_DO_ARQUIVO"
```

Teste via HTTP:

```bash
curl -I "http://127.0.0.1/fotos/NOME_DO_ARQUIVO"
```

Verifique:

- extensão permitida;
- nome sem caracteres problemáticos;
- MIME type correto;
- arquivo não corrompido;
- tamanho suportado pela TV.

Converta para JPG ou PNG quando necessário.

## Serviço não inicia

### Apache

```bash
sudo apache2ctl configtest
sudo journalctl -u apache2 -n 100 --no-pager
```

### Samba

```bash
sudo testparm -s
sudo journalctl -u smbd -n 100 --no-pager
```

Não reinicie repetidamente antes de corrigir o erro apontado.

## Disco cheio

```bash
df -hT
sudo du -xhd1 /srv /var | sort -h
sudo find /srv/tv -type f -printf '%s %p\n' | sort -nr | head -20
```

Remova somente conteúdos autorizados pelo RH.

## Logs

Apache:

```bash
sudo tail -f /var/log/apache2/tv-rh-access.log
sudo tail -f /var/log/apache2/tv-rh-error.log
```

Samba:

```bash
sudo journalctl -u smbd -f
sudo ls -lah /var/log/samba/
```

Sistema:

```bash
sudo journalctl -p warning..alert --since today
```

## Diagnóstico consolidado

```bash
echo "===== DATA ====="
date

echo "===== HOST ====="
hostnamectl

echo "===== REDE ====="
ip -br address
ip route

echo "===== DNS ====="
resolvectl status

echo "===== SERVIÇOS ====="
systemctl status apache2 smbd --no-pager

echo "===== PORTAS ====="
sudo ss -lntp | grep -E ':(80|445)\b' || true

echo "===== APACHE CONFIG ====="
sudo apache2ctl configtest
sudo apache2ctl -S

echo "===== SAMBA CONFIG ====="
sudo testparm -s

echo "===== ARQUIVOS WEB ====="
sudo find /var/www/tv -maxdepth 1 -type f -printf '%M %u:%g %s %p\n'

echo "===== CONTEÚDO ====="
sudo find /srv/tv -maxdepth 1 -type f -printf '%M %u:%g %s %p\n'

echo "===== TESTE HTTP ====="
curl -v http://127.0.0.1/ 2>&1 | head -40

echo "===== TESTE PHP ====="
curl -v http://127.0.0.1/listar-arquivos.php 2>&1 | head -60

echo "===== LOG APACHE ====="
sudo journalctl -u apache2 -n 50 --no-pager

echo "===== LOG SAMBA ====="
sudo journalctl -u smbd -n 50 --no-pager
```
