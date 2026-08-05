# Manual do Usuário — TV RH

Este manual é destinado ao time responsável por publicar os conteúdos exibidos na TV corporativa.

## Como funciona

A TV mostra automaticamente as imagens existentes na pasta compartilhada.

Para alterar o conteúdo, não é necessário acessar o servidor, editar a página ou reiniciar a TV. Basta adicionar ou remover imagens pela pasta de rede.

## Acessar a pasta

No Windows:

1. Abra o Explorador de Arquivos.
2. Clique na barra de endereços.
3. Digite:

```text
\\10.0.2.16\TV
```

4. Pressione `Enter`.
5. Informe as credenciais fornecidas pela TI.

```text
Usuário: tvuser
Senha: fornecida pela TI
```

O endereço pode ser diferente em outra unidade. A TI deve informar o IP ou nome correto.

## Adicionar imagens

1. Abra a pasta compartilhada.
2. Copie ou arraste as imagens para dentro da pasta.
3. Aguarde até 1 minuto.
4. A TV atualizará o conteúdo automaticamente.

Formatos previstos:

```text
JPG
JPEG
PNG
GIF
WEBP
BMP
SVG
```

Para maior compatibilidade com navegadores de Smart TV, prefira `JPG` ou `PNG`.

## Remover imagens

1. Abra a pasta compartilhada.
2. Selecione a imagem.
3. Pressione `Delete`.
4. Aguarde até 1 minuto para a atualização.

## Definir a ordem

Os arquivos são normalmente exibidos em ordem alfabética.

Use números no início do nome:

```text
01_boas-vindas.jpg
02_comunicado-beneficios.png
03_aniversariantes.jpg
04_evento-interno.png
```

Evite:

- caracteres especiais;
- nomes extremamente longos;
- arquivos diferentes com o mesmo nome;
- acentos quando a TV apresentar incompatibilidade.

## Alterar o tempo entre imagens

Na pasta compartilhada, localize:

```text
config.txt
```

Abra com o Bloco de Notas e altere:

```ini
TEMPO_ENTRE_IMAGENS = 5
```

Exemplos:

```ini
# Cinco segundos
TEMPO_ENTRE_IMAGENS = 5

# Trinta segundos
TEMPO_ENTRE_IMAGENS = 30

# Um minuto
TEMPO_ENTRE_IMAGENS = 60
```

Valores previstos:

```text
Mínimo: 1 segundo
Máximo: 300 segundos
```

Não remova o nome `TEMPO_ENTRE_IMAGENS`.

## Recomendações para as artes

Para uma TV Full HD em modo paisagem:

```text
Resolução: 1920 x 1080 pixels
Proporção: 16:9
Orientação: paisagem
Formato recomendado: JPG ou PNG
```

Boas práticas:

- use letras grandes;
- mantenha contraste entre texto e fundo;
- evite textos extensos;
- mantenha margens de segurança;
- revise datas, horários e contatos;
- compacte imagens muito grandes;
- evite GIFs pesados.

## Conteúdo não atualizou

Primeiro:

1. Aguarde 1 minuto.
2. Verifique se o arquivo terminou de copiar.
3. Confirme que ele é JPG ou PNG.
4. Atualize a página da TV, quando houver acesso ao controle.
5. Informe à TI o nome exato do arquivo.

## Pasta não abriu

Verifique:

- se está conectado à rede corporativa;
- se digitou duas barras invertidas no início;
- se utilizou o endereço informado pela TI;
- se as credenciais estão corretas;
- se já existe outra conexão ao servidor com credenciais diferentes.

Para remover conexões antigas, a TI pode executar no Windows:

```cmd
net use
net use \\10.0.2.16\TV /delete
```

## Cuidados

- Não altere nem exclua o arquivo `config.txt`.
- Não crie subpastas sem autorização da TI.
- Não copie documentos, planilhas ou vídeos sem validação.
- Não compartilhe a senha do usuário Samba fora do grupo autorizado.
- Não desligue a TV ou altere o endereço configurado no navegador.

## Suporte

Ao abrir um chamado, informe:

```text
Unidade:
Horário do problema:
Endereço da TV:
Nome do arquivo:
Mensagem de erro:
A pasta de rede abre? Sim/Não
A página da TV abre? Sim/Não
```
