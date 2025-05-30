# Dockerfile pour OnlyFeed Frontend (Flutter Web)

# Étape 1: Builder - Image Flutter pour compiler
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Variables d'environnement pour Flutter
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="$FLUTTER_ROOT/bin:$PATH"

# Définir le répertoire de travail
WORKDIR /app

# Activer Flutter Web (au cas où)
RUN flutter config --enable-web

# Copier les fichiers de dépendances
COPY pubspec.yaml pubspec.lock ./

# Télécharger les dépendances Flutter
RUN flutter pub get

# Copier tout le code source
COPY . .

# Build pour le web en mode release
RUN flutter build web --release

# Étape 2: Runtime - Serveur web Nginx pour servir les fichiers
FROM nginx:alpine

# Supprimer la configuration par défaut de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copier les fichiers buildés depuis l'étape builder
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copier la configuration Nginx personnalisée
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Variables d'environnement
ENV NGINX_HOST=localhost
ENV NGINX_PORT=80

# Exposer le port
EXPOSE 80

# Commande de santé
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Commande pour lancer Nginx
CMD ["nginx", "-g", "daemon off;"]