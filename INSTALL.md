# 📘 Manual de Instalação - TV RH Automático

## 🎯 Objetivo

Configurar um servidor Ubuntu 24.04 LTS para exibir imagens em looping em uma TV Smart, com:

- 📁 Pasta compartilhada via Samba para o RH
- 🌐 Página web acessível via navegador
- ⏱️ Controle de velocidade via arquivo de texto
- 📡 Atualização automática (60 segundos)

---

## 📋 Pré-requisitos

| Item | Especificação |
|------|---------------|
| **Servidor** | VM ou hardware com Ubuntu Server 24.04 LTS |
| **CPU** | 2 vCPUs (mínimo 1) |
| **RAM** | 4 GB (mínimo 2 GB) |
| **HD** | 40 GB (mínimo 20 GB) |
| **Rede** | IP Fixo na rede interna |
| **TV** | Smart TV com navegador ou Chromecast/Mi Stick |

---

## 🔧 Passo 1: Criar a VM / Servidor

### 1.1 Configurações da VM

| Recurso | Configuração |
|---------|--------------|
| **Sistema Operacional** | Ubuntu Server 24.04 LTS |
| **Hostname** | `tv-server` |
| **Usuário** | `admin` (ou outro de sua preferência) |
| **SSH** | Habilitar OpenSSH Server |

### 1.2 Configurar IP Fixo

Descubra o nome da placa de rede:

bash
ip a

Edite o arquivo de configuração:
sudo nano /etc/netplan/01-netcfg.yaml

network:
  version: 2
  ethernets:
    enp0s3:   # Substitua pelo nome da sua placa
      dhcp4: false
      addresses:
        - 10.0.2.16/24    # IP FIXO (altere conforme sua rede)
      routes:
        - to: default
          via: 10.0.2.1   # Gateway da rede
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4

sudo netplan apply

🚀 Passo 2: Instalar Pacotes
Execute os comandos abaixo UM POR UM:

# Atualiza o sistema
sudo apt update
sudo apt upgrade -y

# Instala os pacotes necessários
sudo apt install -y \
    samba \
    samba-common \
    smbclient \
    apache2 \
    php \
    libapache2-mod-php \
    net-tools \
    htop \
    nano \
    curl \
    wget \
    unzip

🗂️ Passo 3: Criar Estrutura de Pastas
# Cria as pastas
sudo mkdir -p /srv/tv
sudo mkdir -p /var/www/tv

# Ajusta permissões da pasta de fotos
sudo chown -R nobody:nogroup /srv/tv
sudo chmod -R 777 /srv/tv

# Ajusta permissões da pasta web
sudo chown -R www-data:www-data /var/www/tv
sudo chmod -R 755 /var/www/tv

4.1 Editar configuração do Samba
# Faz backup do arquivo original
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Edita a configuração
sudo nano /etc/samba/smb.conf

Adicione ao final do arquivo:

[TV]
   comment = Pastas das Fotos da TV
   path = /srv/tv
   browseable = yes
   read only = no
   guest ok = no
   valid users = tvuser
   create mask = 0755
   directory mask = 0755
   force user = tvuser
   force group = tvuser
   public = no

# Cria o usuário no Linux
sudo useradd -m -s /bin/bash tvuser

# Define a senha (escolha uma forte)
sudo passwd tvuser

# Adiciona o usuário ao Samba
sudo smbpasswd -a tvuser

# Habilita o usuário
sudo smbpasswd -e tvuser

# Ajusta permissões da pasta
sudo chown -R tvuser:tvuser /srv/tv
sudo chmod -R 755 /srv/tv

4.3 Reiniciar o Samba
sudo systemctl restart smbd
sudo systemctl restart nmbd
sudo systemctl enable smbd


🌐 Passo 5: Configurar Apache (Servidor Web)
5.1 Criar configuração do site
# Remove a configuração padrão (opcional)
sudo a2dissite 000-default.conf

# Cria o arquivo de configuração
sudo nano /etc/apache2/sites-available/tv.conf

Conteúdo do arquivo:
<VirtualHost *:80>
    ServerName 10.0.2.16
    DocumentRoot /var/www/tv
    
    <Directory /var/www/tv>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    Alias /fotos /srv/tv
    <Directory /srv/tv>
        Options Indexes
        Require all granted
    </Directory>
</VirtualHost>

5.2 Ativar site e configurar ServerName
# Ativa o site
sudo a2ensite tv.conf

# Corrige o aviso do ServerName
sudo nano /etc/apache2/apache2.conf

Adicione ao final do arquivo:
ServerName 10.0.2.16

5.3 Reiniciar Apache
sudo systemctl restart apache2
sudo systemctl enable apache2

# Verifica se está funcionando
sudo apache2ctl configtest

🐘 Passo 6: Criar os Arquivos da Página
6.1 Criar listar-arquivos.php
sudo nano /var/www/tv/listar-arquivos.php

<?php
// ============================================================
// LISTA TODAS AS IMAGENS E LÊ A CONFIGURAÇÃO DA PASTA
// ============================================================

$pasta = '/srv/tv';

// ============================================================
// 1. LÊ O ARQUIVO DE CONFIGURAÇÃO (config.txt)
// ============================================================
function lerConfiguracao($pasta) {
    $arquivoConfig = $pasta . '/config.txt';
    $config = [
        'tempo' => 5
    ];

    if (file_exists($arquivoConfig)) {
        $linhas = file($arquivoConfig, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($linhas as $linha) {
            $linha = trim($linha);
            if (empty($linha) || strpos($linha, '#') === 0) {
                continue;
            }

            if (preg_match('/TEMPO_ENTRE_IMAGENS\s*=\s*(\d+)/i', $linha, $matches)) {
                $tempo = intval($matches[1]);
                if ($tempo >= 1 && $tempo <= 300) {
                    $config['tempo'] = $tempo;
                }
            }
        }
    }

    return $config;
}

// ============================================================
// 2. LISTA AS IMAGENS
// ============================================================
function listarImagens($pasta) {
    if (!is_dir($pasta)) {
        return [];
    }

    $arquivos = scandir($pasta);
    $arquivos = array_diff($arquivos, array('.', '..'));

    $extensoes_validas = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
    $imagens = array_values(array_filter($arquivos, function($arquivo) use ($extensoes_validas) {
        if ($arquivo === 'config.txt') {
            return false;
        }
        $ext = strtolower(pathinfo($arquivo, PATHINFO_EXTENSION));
        return in_array($ext, $extensoes_validas);
    }));

    sort($imagens);
    return $imagens;
}

// ============================================================
// 3. MONTA A RESPOSTA
// ============================================================
$config = lerConfiguracao($pasta);
$imagens = listarImagens($pasta);

$resposta = [
    'imagens' => $imagens,
    'config' => [
        'tempo' => $config['tempo']
    ]
];

header('Content-Type: application/json');
header('Cache-Control: no-cache, must-revalidate');
echo json_encode($resposta);
?>

6.2 Criar index.html (Página da TV)
sudo nano /var/www/tv/index.html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📺 TV RH - Painel de Notícias</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            background: #000000;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            overflow: hidden;
            font-family: 'Segoe UI', Arial, sans-serif;
        }

        #container {
            width: 100vw;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            position: relative;
        }

        #container img {
            max-width: 100vw;
            max-height: 100vh;
            width: auto;
            height: auto;
            object-fit: contain;
            animation: fadeIn 1s ease-in-out;
        }

        @keyframes fadeIn {
            0% {
                opacity: 0;
                transform: scale(0.95);
            }
            100% {
                opacity: 1;
                transform: scale(1);
            }
        }

        .sem-imagem {
            color: #ffffff;
            font-size: 28px;
            text-align: center;
            padding: 40px;
            background: rgba(0,0,0,0.8);
            border-radius: 20px;
            border: 2px dashed #444;
        }

        .sem-imagem .icone {
            font-size: 80px;
            display: block;
            margin-bottom: 20px;
        }

        .sem-imagem .sub {
            font-size: 16px;
            color: #888;
            margin-top: 10px;
        }

        #rodape {
            position: fixed;
            bottom: 20px;
            right: 30px;
            color: rgba(255, 255, 255, 0.25);
            font-size: 13px;
            font-family: 'Courier New', monospace;
            background: rgba(0, 0, 0, 0.7);
            padding: 6px 16px;
            border-radius: 20px;
            border: 1px solid rgba(255,255,255,0.05);
            z-index: 999;
            user-select: none;
            pointer-events: none;
        }

        #contador {
            position: fixed;
            bottom: 20px;
            left: 30px;
            color: rgba(255, 255, 255, 0.15);
            font-size: 13px;
            font-family: 'Courier New', monospace;
            background: rgba(0, 0, 0, 0.5);
            padding: 6px 16px;
            border-radius: 20px;
            z-index: 999;
            user-select: none;
            pointer-events: none;
        }

        .loading {
            color: #ffffff;
            font-size: 24px;
            text-align: center;
        }

        .loading .spinner {
            display: inline-block;
            width: 50px;
            height: 50px;
            border: 4px solid rgba(255,255,255,0.1);
            border-top: 4px solid #ffffff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-bottom: 20px;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>

    <div id="container">
        <div class="loading">
            <div class="spinner"></div>
            <p>Carregando imagens... 📺</p>
        </div>
    </div>

    <div id="rodape">⏱️ <span id="tempo-config">--</span>s • 🔄 Atualizado: <span id="hora-atual">--:--:--</span></div>
    <div id="contador"><span id="indice-atual">0</span> / <span id="total-imagens">0</span></div>

    <script>
        // ===========================================================
        // CONFIGURAÇÕES
        // ===========================================================
        const CONFIG = {
            intervalo: 5000,
            recarregarLista: 60000,
            urlListar: '/listar-arquivos.php',
            urlImagens: '/fotos/'
        };

        // ===========================================================
        // VARIÁVEIS
        // ===========================================================
        let imagens = [];
        let indice = 0;
        let intervaloSlides = null;
        const container = document.getElementById('container');

        // ===========================================================
        // FUNÇÕES
        // ===========================================================
        function mostrarMensagem(icone, titulo, subtitulo = '') {
            container.innerHTML = `
                <div class="sem-imagem">
                    <span class="icone">${icone}</span>
                    ${titulo}
                    ${subtitulo ? `<div class="sub">${subtitulo}</div>` : ''}
                </div>
            `;
            document.getElementById('indice-atual').textContent = '0';
            document.getElementById('total-imagens').textContent = '0';
        }

        function mostrarLoading() {
            container.innerHTML = `
                <div class="loading">
                    <div class="spinner"></div>
                    <p>Carregando imagens... 📺</p>
                </div>
            `;
        }

        function exibirImagem(url) {
            const img = document.createElement('img');
            img.src = url;
            img.alt = 'Notícia RH';
            img.onerror = function() {
                console.warn('Erro ao carregar:', url);
                avancarImagem();
            };
            img.onload = function() {
                document.getElementById('indice-atual').textContent = indice + 1;
            };
            
            container.innerHTML = '';
            container.appendChild(img);
        }

        function avancarImagem() {
            if (imagens.length === 0) {
                mostrarMensagem('📸', 'Nenhuma foto na pasta ainda!', 
                    'Jogue as imagens em \\\\10.0.2.16\\TV');
                return;
            }

            if (indice >= imagens.length) {
                indice = 0;
            }

            const url = CONFIG.urlImagens + imagens[indice];
            exibirImagem(url);
            document.getElementById('total-imagens').textContent = imagens.length;
            indice = (indice + 1) % imagens.length;
        }

        function carregarListaImagens() {
            mostrarLoading();

            fetch(CONFIG.urlListar)
                .then(response => {
                    if (!response.ok) {
                        throw new Error('Erro HTTP: ' + response.status);
                    }
                    return response.json();
                })
                .then(data => {
                    if (!data.imagens || !Array.isArray(data.imagens)) {
                        throw new Error('Resposta inválida do servidor');
                    }

                    if (data.config && data.config.tempo) {
                        const novoTempo = data.config.tempo * 1000;
                        if (novoTempo >= 1000 && novoTempo <= 300000) {
                            CONFIG.intervalo = novoTempo;
                            document.getElementById('tempo-config').textContent = data.config.tempo;
                            console.log(`⏱️ Tempo configurado: ${data.config.tempo} segundos`);
                        }
                    }

                    imagens = data.imagens;
                    console.log(`📸 ${imagens.length} imagens carregadas`);

                    if (imagens.length === 0) {
                        mostrarMensagem('📸', 'Nenhuma foto na pasta ainda!', 
                            'Jogue as imagens em \\\\10.0.2.16\\TV');
                        return;
                    }

                    indice = 0;
                    if (intervaloSlides) {
                        clearInterval(intervaloSlides);
                    }
                    
                    avancarImagem();
                    intervaloSlides = setInterval(avancarImagem, CONFIG.intervalo);
                    atualizarHora();

                })
                .catch(error => {
                    console.error('❌ Erro ao carregar imagens:', error);
                    mostrarMensagem('⚠️', 'Erro ao conectar com o servidor', 
                        'Verifique se o PHP está funcionando');
                });
        }

        function atualizarHora() {
            const agora = new Date();
            const hora = String(agora.getHours()).padStart(2, '0');
            const minuto = String(agora.getMinutes()).padStart(2, '0');
            const segundo = String(agora.getSeconds()).padStart(2, '0');
            document.getElementById('hora-atual').textContent = `${hora}:${minuto}:${segundo}`;
        }

        // ===========================================================
        // INICIALIZAÇÃO
        // ===========================================================
        carregarListaImagens();
        setInterval(carregarListaImagens, CONFIG.recarregarLista);
        setInterval(atualizarHora, 1000);

        setTimeout(() => {
            location.reload();
        }, 3600000);

        console.log('✅ TV RH iniciada com sucesso!');
    </script>

</body>
</html>

6.3 Criar arquivo de configuração padrão
sudo nano /srv/tv/config.txt
# ============================================================
# CONFIGURAÇÃO DA TV RH
# ============================================================
#
# TEMPO_ENTRE_IMAGENS = [segundos]
#
# Valores permitidos: de 1 a 300 segundos
# ============================================================

TEMPO_ENTRE_IMAGENS = 5

6.4 Ajustar permissões
sudo chown tvuser:tvuser /srv/tv/config.txt
sudo chmod 664 /srv/tv/config.txt

🧪 Passo 7: Testar Instalação
# Testa o servidor web
curl http://10.0.2.16/

# Testa o PHP (deve retornar um JSON)
curl http://10.0.2.16/listar-arquivos.php

# Verifica se o Apache está rodando
sudo systemctl status apache2

# Verifica se o Samba está rodando
sudo systemctl status smbd

✅ Passo 8: Verificação Final
Teste	Como testar	Resultado esperado
Samba	No Windows: \\10.0.2.16\TV	Pede usuário/senha e abre a pasta
Apache	Navegador: http://10.0.2.16/	Mostra a página da TV
PHP	Navegador: http://10.0.2.16/listar-arquivos.php	Mostra JSON com imagens
Config	Editar config.txt e aguardar	TV muda o tempo das imagens




