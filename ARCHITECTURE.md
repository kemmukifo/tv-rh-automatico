# Arquitetura

## Visão geral

O TV RH Automático utiliza uma arquitetura simples, interna e sem banco de dados.

```text
┌─────────────────────┐
│ Computador do RH    │
│ Windows             │
└──────────┬──────────┘
           │ SMB / TCP 445
           │ \\servidor\TV
           v
┌───────────────────────────────────────┐
│ Ubuntu Server                         │
│                                       │
│  Samba                                │
│  └── /srv/tv                          │
│      ├── config.txt                   │
│      └── imagens                      │
│                                       │
│  Apache + PHP                         │
│  ├── /var/www/tv/index.html           │
│  ├── /var/www/tv/listar-arquivos.php  │
│  └── Alias /fotos/ -> /srv/tv/        │
└───────────────────┬───────────────────┘
                    │ HTTP / TCP 80
                    v
          ┌─────────────────────┐
          │ Smart TV            │
          │ Navegador em loop   │
          └─────────────────────┘
```

## Componentes

### Samba

Responsável por disponibilizar `/srv/tv` como compartilhamento de rede.

Compartilhamento:

```text
\\IP_DO_SERVIDOR\TV
```

Usuário local e Samba:

```text
tvuser
```

### Apache

Publica a aplicação na porta 80/TCP.

DocumentRoot:

```text
/var/www/tv
```

Alias de imagens:

```text
/fotos/ -> /srv/tv/
```

### PHP

O endpoint `listar-arquivos.php` deve:

1. ler o conteúdo de `/srv/tv`;
2. ignorar diretórios e o arquivo `config.txt`;
3. filtrar extensões permitidas;
4. ordenar a lista;
5. ler `TEMPO_ENTRE_IMAGENS`;
6. retornar JSON;
7. desabilitar cache da resposta.

Resposta esperada:

```json
{
  "imagens": [
    "01_aviso.jpg",
    "02_evento.png"
  ],
  "config": {
    "tempo": 5
  }
}
```

### Front-end

O arquivo `index.html` deve:

1. consultar `/listar-arquivos.php`;
2. carregar imagens por `/fotos/NOME_DO_ARQUIVO`;
3. respeitar o intervalo retornado;
4. atualizar a lista periodicamente;
5. tratar arquivos inválidos;
6. exibir uma mensagem quando não houver conteúdo;
7. operar em tela cheia.

## Fluxo de dados

```text
RH copia imagem
      |
      v
Samba grava em /srv/tv
      |
      v
PHP lista os arquivos
      |
      v
JavaScript recebe JSON
      |
      v
Navegador da TV carrega /fotos/arquivo.jpg
```

## Portas

| Porta | Protocolo | Origem | Destino | Função |
|---:|---|---|---|---|
| 22 | TCP | Administração | Servidor | SSH |
| 80 | TCP | Smart TV e administração | Servidor | Página web |
| 445 | TCP | Computadores autorizados | Servidor | Samba |
| 137-139 | TCP/UDP | Opcional | Servidor | Descoberta SMB legada |

Em redes modernas, o acesso direto por IP normalmente utiliza a porta 445.

## Armazenamento

O projeto não utiliza banco de dados.

Os dados persistentes são:

```text
/srv/tv/config.txt
/srv/tv/*.jpg
/srv/tv/*.png
...
```

A aplicação web fica em:

```text
/var/www/tv
```

## Disponibilidade

Os serviços devem estar habilitados no boot:

```bash
sudo systemctl enable apache2
sudo systemctl enable smbd
```

Verificação:

```bash
systemctl is-active apache2 smbd
```

## Backup

Conteúdo que deve entrar no backup:

```text
/srv/tv
/etc/samba/smb.conf
/etc/apache2/sites-available/tv.conf
/var/www/tv
```

Exemplo:

```bash
sudo tar -czf "/var/backups/tv-rh-$(date +%Y%m%d).tar.gz" \
  /srv/tv \
  /etc/samba/smb.conf \
  /etc/apache2/sites-available/tv.conf \
  /var/www/tv
```

## Segurança

Principais controles:

- autenticação obrigatória no Samba;
- acesso limitado às redes internas;
- ausência de escrita pelo usuário do Apache em `/srv/tv`;
- diretórios sem listagem automática;
- arquivos de configuração sem senhas;
- atualizações regulares;
- logs do Apache disponíveis para auditoria;
- backup periódico.

## Pontos de melhoria

- parametrizar IP, usuário e caminhos no `setup.sh`;
- tornar o instalador idempotente;
- adicionar validações automáticas;
- criar healthcheck HTTP;
- adicionar suporte opcional a HTTPS;
- restringir MIME types no endpoint;
- registrar alterações de conteúdo;
- criar monitoramento por Zabbix ou Uptime Kuma;
- adicionar CI para validar shell, PHP e Markdown;
- suportar múltiplas TVs ou unidades por configuração.
