# TV RH Automático

Sistema interno para exibição automática de comunicados e imagens corporativas em uma Smart TV, utilizando um servidor Ubuntu, Apache, PHP e Samba.

O projeto foi pensado para permitir que o time de RH publique conteúdos sem precisar editar páginas web ou executar comandos no servidor.

## Objetivo

O fluxo operacional esperado é:

```text
Computador do RH
      |
      |  SMB: \\SERVIDOR\TV
      v
Pasta /srv/tv no servidor Ubuntu
      |
      |  Apache + PHP
      v
Navegador da Smart TV
```

O RH copia ou remove imagens pela pasta compartilhada. A página aberta na TV consulta periodicamente o servidor e atualiza o slideshow automaticamente.

## Funcionalidades previstas

- Exibição de imagens em looping.
- Compartilhamento autenticado via Samba.
- Atualização automática da lista de imagens.
- Controle do intervalo entre imagens pelo arquivo `config.txt`.
- Acesso pela rede interna, sem dependência de serviços externos.
- Compatibilidade planejada com JPG, JPEG, PNG, GIF, WEBP, BMP e SVG.
- Página preparada para uso em tela cheia.

## Tecnologias

- Ubuntu Server 24.04 LTS
- Apache HTTP Server 2.4
- PHP 8.x
- Samba 4.x
- HTML, CSS e JavaScript
- Smart TV com navegador web

## Estrutura do repositório

```text
tv-rh-automatico/
├── config/
│   └── config.txt
├── samba/
│   └── smb.conf
├── scripts/
│   └── setup.sh
├── web/
│   ├── index.html
│   └── listar-arquivos.php
├── ARCHITECTURE.md
├── CHANGELOG.md
├── INSTALL.md
├── README.md
├── TROUBLESHOOTING.md
└── USER_MANUAL.md
```

## Estado atual do repositório

> [!WARNING]
> No estado consultado em 5 de agosto de 2026, o arquivo `web/index.html` aparece no GitHub com apenas 1 byte. Antes de considerar a aplicação pronta para produção, valide também o conteúdo de `web/listar-arquivos.php`.

A documentação deste pacote descreve a arquitetura pretendida e o procedimento correto de instalação, mas os arquivos da aplicação web precisam conter a implementação completa.

## Requisitos mínimos

| Recurso | Mínimo | Recomendado |
|---|---:|---:|
| CPU | 1 vCPU | 2 vCPUs |
| Memória | 2 GB | 4 GB |
| Disco | 20 GB | 40 GB |
| Sistema | Ubuntu Server 24.04 LTS | Ubuntu Server 24.04 LTS |
| Rede | IP fixo ou reserva DHCP | IP fixo |
| TV | Navegador web | Navegador com modo tela cheia |

## Instalação

Consulte o arquivo [INSTALL.md](INSTALL.md).

Resumo:

```bash
sudo apt update
sudo apt install -y git

git clone https://github.com/kemmukifo/tv-rh-automatico.git
cd tv-rh-automatico

chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

> O script atual contém o IP `10.0.2.16` fixado em diferentes trechos. Revise o script antes de executá-lo em outra unidade ou rede.

## Operação pelo RH

Consulte o arquivo [USER_MANUAL.md](USER_MANUAL.md).

Fluxo básico:

1. Acessar `\\IP_DO_SERVIDOR\TV`.
2. Informar o usuário Samba.
3. Copiar ou remover as imagens.
4. Aguardar a atualização automática da TV.

## Documentação

- [Instalação](INSTALL.md)
- [Manual do usuário](USER_MANUAL.md)
- [Arquitetura](ARCHITECTURE.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Histórico de alterações](CHANGELOG.md)

## Segurança

- Não publique senhas no repositório.
- Use uma senha forte e exclusiva para o usuário Samba.
- Restrinja as portas 80/TCP e 445/TCP às redes internas necessárias.
- Não exponha o compartilhamento Samba diretamente à internet.
- Mantenha Ubuntu, Apache, PHP e Samba atualizados.
- Em ambientes corporativos, prefira uma VLAN dedicada ou regras de firewall específicas para a TV.

## Autor

**Kleber Eduardo Maximo**  
GitHub: `kemmukifo`

## Licença

Este repositório ainda não possui uma licença explicitamente definida. Antes de distribuir ou reutilizar o projeto fora da organização, adicione um arquivo `LICENSE`.
