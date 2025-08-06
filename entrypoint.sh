#!/bin/sh
cat << 'EOF' > /var/www/html/.htaccess
RewriteEngine On

# Append ".html" extension if the file exists
RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI}.html -f
RewriteRule !\.\w{2,4}$ %{REQUEST_URI}.html [L]

# Otherwise append ".php" extension if the file exists
RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI}.php -f
RewriteRule !\.\w{2,4}$ %{REQUEST_URI}.php [L]
EOF

exec apache2-foreground
