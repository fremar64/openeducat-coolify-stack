# --- Dockerfile pour Odoo 18 + OpenEduCat ---
FROM odoo:18

# Mainteneur
LABEL maintainer="CEREDIS admin@ceredis.net"

# Installer dépendances système & Python supplémentaires
USER root
RUN apt-get update && apt-get install -y \
    git \
    wget \
    nano \
    postgresql-client \
    python3-pip \
    python3-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libtiff5-dev \
    libjpeg-turbo8-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev \
    && rm -rf /var/lib/apt/lists/*

# Installer les dépendances Python spécifiques à OpenEduCat
RUN pip install --no-cache-dir --break-system-packages \
    openpyxl \
    xlrd \
    xlwt \
    pandas \
    psycopg2-binary \
    reportlab \
    requests \
    num2words

# Créer le répertoire des modules personnalisés
RUN mkdir -p /mnt/extra-addons
WORKDIR /mnt/extra-addons

# Script d’installation OpenEduCat
COPY install_openeducat.sh /usr/local/bin/install_openeducat.sh
RUN sed -i 's/\r$//' /usr/local/bin/install_openeducat.sh \
    && chmod +x /usr/local/bin/install_openeducat.sh \
    && /usr/local/bin/install_openeducat.sh

# Copier le script d'initialisation OpenEduCat
COPY init_openeducat.sh /usr/local/bin/init_openeducat.sh
RUN sed -i 's/\r$//' /usr/local/bin/init_openeducat.sh \
    && chmod +x /usr/local/bin/init_openeducat.sh

# Revenir à l’utilisateur odoo
USER odoo

# Exposer le port standard
EXPOSE 8069

CMD ["odoo"]
