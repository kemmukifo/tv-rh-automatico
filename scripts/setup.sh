#!/bin/bash
# ============================================================
# SCRIPT DE INSTALAÇÃO AUTOMÁTICA - TV RH
# ============================================================

set -e

echo "🚀 Iniciando instalação da TV RH Automático..."
echo ""

# 1. Atualiza sistema
echo "📦 Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# 2. Instala pacotes
echo "📦 Instalando pacotes..."
sudo apt install -y samba samba-common smbclient apache2 php libapache2-mod-php net-tools htop nano curl wget unzip

# 3. Cria pastas
echo "📁 Criando pastas..."
sudo mkdir -p /srv/tv /var/www/tv
sudo chown -R www-data:www-data /var/www/tv
sudo chmod -R 755 /var/www/tv

# 4. Cria usuário Samba
echo "👤 Criando usuário tvuser..."
sudo useradd -m -s /bin/bash tvuser || true
echo "Defina a senha para o usuário tvuser:"
sudo passwd tvuser
sudo smbpasswd -a tvuser
sudo smbpasswd -e tvuser

# 5. Configura Samba
echo "🔧 Configurando Samba..."
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
cat << 'EOF' | sudo tee -a /etc/samba/smb.conf

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
EOF

sudo systemctl restart smbd
sudo systemctl enable smbd

# 6. Configura Apache
echo "🌐 Configurando Apache..."
sudo a2dissite 000-default.conf || true
cat << 'EOF' | sudo tee /etc/apache2/sites-available/tv.conf
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
EOF

echo "ServerName 10.0.2.16" | sudo tee -a /etc/apache2/apache2.conf
sudo a2ensite tv.conf
sudo systemctl restart apache2
sudo systemctl enable apache2

# 7. Cria arquivos web
echo "📄 Criando arquivos da página..."
cp web/index.html /var/www/tv/
cp web/listar-arquivos.php /var/www/tv/
sudo chown -R www-data:www-data /var/www/tv

# 8. Cria config.txt padrão
echo "⚙️ Criando config.txt..."
cp config/config.txt /srv/tv/
sudo chown tvuser:tvuser /srv/tv/config.txt
sudo chmod 664 /srv/tv/config.txt

# 9. Ajusta permissões da pasta de fotos
echo "🔐 Ajustando permissões..."
sudo chown -R tvuser:tvuser /srv/tv
sudo chmod -R 755 /srv/tv

echo ""
echo "✅ INSTALAÇÃO CONCLUÍDA!"
echo ""
echo "📝 INFORMAÇÕES:"
echo "   IP do servidor: 10.0.2.16"
echo "   Pasta compartilhada: \\\\10.0.2.16\\TV"
echo "   Usuário: tvuser"
echo "   Senha: (a que você definiu)"
echo "   URL da TV: http://10.0.2.16/"
echo ""
echo "📖 Consulte o USER_MANUAL.md para instruções de uso."
