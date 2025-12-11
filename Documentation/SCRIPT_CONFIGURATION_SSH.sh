#!/bin/bash

# Script de configuration SSH pour accès au Mac mini depuis Cursor
# Date: 3 décembre 2025

echo "═══════════════════════════════════════════════════════════════"
echo "  Configuration SSH pour Accès Mac mini dans Cursor"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables
SSH_CONFIG_FILE="$HOME/.ssh/config"
SSH_DIR="$HOME/.ssh"
BACKUP_FILE="$SSH_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Fonction pour afficher les messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Vérifier si le dossier .ssh existe
if [ ! -d "$SSH_DIR" ]; then
    print_info "Création du dossier .ssh..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    print_success "Dossier .ssh créé"
fi

# Vérifier si une clé SSH existe
if [ ! -f "$SSH_DIR/id_ed25519" ] && [ ! -f "$SSH_DIR/id_rsa" ]; then
    print_warning "Aucune clé SSH trouvée"
    read -p "Voulez-vous générer une nouvelle clé SSH ? (o/n) : " generate_key
    
    if [[ $generate_key == "o" || $generate_key == "O" ]]; then
        read -p "Entrez votre email pour la clé SSH : " email
        if [ -z "$email" ]; then
            email="cursor@railskills"
        fi
        
        print_info "Génération de la clé SSH..."
        ssh-keygen -t ed25519 -C "$email" -f "$SSH_DIR/id_ed25519" -N ""
        
        if [ $? -eq 0 ]; then
            print_success "Clé SSH générée : $SSH_DIR/id_ed25519"
        else
            print_error "Erreur lors de la génération de la clé SSH"
            exit 1
        fi
    else
        print_error "Impossible de continuer sans clé SSH"
        exit 1
    fi
else
    if [ -f "$SSH_DIR/id_ed25519" ]; then
        print_success "Clé SSH trouvée : id_ed25519"
        KEY_FILE="$SSH_DIR/id_ed25519"
    else
        print_success "Clé SSH trouvée : id_rsa"
        KEY_FILE="$SSH_DIR/id_rsa"
    fi
fi

# Demander les informations de connexion
echo ""
print_info "Configuration de la connexion SSH au Mac mini"
echo ""

read -p "Adresse IP du Mac mini (ex: 192.168.1.XXX) : " macmini_ip
if [ -z "$macmini_ip" ]; then
    print_error "L'adresse IP est obligatoire"
    exit 1
fi

read -p "Nom d'utilisateur sur le Mac mini (défaut: sylvaingallon) : " macmini_user
if [ -z "$macmini_user" ]; then
    macmini_user="sylvaingallon"
fi

read -p "Nom d'hôte SSH (défaut: macmini-railskills) : " host_name
if [ -z "$host_name" ]; then
    host_name="macmini-railskills"
fi

# Créer une sauvegarde du fichier de configuration existant
if [ -f "$SSH_CONFIG_FILE" ]; then
    print_info "Sauvegarde de la configuration SSH existante..."
    cp "$SSH_CONFIG_FILE" "$BACKUP_FILE"
    print_success "Sauvegarde créée : $BACKUP_FILE"
fi

# Vérifier si l'hôte existe déjà
if grep -q "Host $host_name" "$SSH_CONFIG_FILE" 2>/dev/null; then
    print_warning "L'hôte '$host_name' existe déjà dans la configuration SSH"
    read -p "Voulez-vous le remplacer ? (o/n) : " replace_host
    
    if [[ $replace_host == "o" || $replace_host == "O" ]]; then
        # Supprimer l'ancienne configuration
        sed -i.bak "/^Host $host_name$/,/^$/d" "$SSH_CONFIG_FILE" 2>/dev/null
        print_info "Ancienne configuration supprimée"
    else
        print_info "Configuration annulée"
        exit 0
    fi
fi

# Ajouter la configuration SSH
print_info "Ajout de la configuration SSH..."

cat >> "$SSH_CONFIG_FILE" << EOF

# Configuration pour Mac mini RailSkills
# Ajouté le $(date)
Host $host_name
    HostName $macmini_ip
    User $macmini_user
    IdentityFile $KEY_FILE
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/control-%h-%p-%r
    ControlPersist 10m
    Compression yes
EOF

if [ $? -eq 0 ]; then
    print_success "Configuration SSH ajoutée"
else
    print_error "Erreur lors de l'ajout de la configuration"
    exit 1
fi

# Tester la connexion
echo ""
print_info "Test de la connexion SSH..."
echo ""

read -p "Voulez-vous tester la connexion maintenant ? (o/n) : " test_connection

if [[ $test_connection == "o" || $test_connection == "O" ]]; then
    print_info "Test de connexion SSH à $macmini_ip..."
    
    # Copier la clé publique si nécessaire
    if [ -f "$KEY_FILE.pub" ]; then
        print_info "Copie de la clé publique vers le Mac mini..."
        ssh-copy-id -i "$KEY_FILE.pub" "$macmini_user@$macmini_ip" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_success "Clé publique copiée"
        else
            print_warning "Impossible de copier automatiquement la clé publique"
            print_info "Vous devrez le faire manuellement :"
            echo "  ssh-copy-id -i $KEY_FILE.pub $macmini_user@$macmini_ip"
        fi
    fi
    
    # Test de connexion
    print_info "Test de connexion..."
    ssh -o ConnectTimeout=5 "$host_name" "echo 'Connexion SSH réussie !' && hostname && pwd" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Connexion SSH fonctionnelle !"
    else
        print_warning "La connexion SSH n'a pas fonctionné automatiquement"
        print_info "Vous devrez peut-être :"
        echo "  1. Vérifier que SSH est activé sur le Mac mini"
        echo "  2. Vérifier l'adresse IP"
        echo "  3. Copier manuellement la clé SSH"
        echo ""
        print_info "Commande pour copier la clé :"
        echo "  ssh-copy-id -i $KEY_FILE.pub $macmini_user@$macmini_ip"
    fi
fi

# Afficher les instructions pour Cursor
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Configuration Terminée"
echo "═══════════════════════════════════════════════════════════════"
echo ""
print_success "Configuration SSH ajoutée pour : $host_name"
echo ""
print_info "Prochaines étapes dans Cursor :"
echo ""
echo "1. Installer l'extension Remote-SSH dans Cursor"
echo "   - Ouvrir la palette : ⌘ + Shift + P"
echo "   - Taper : 'Extensions: Install Extensions'"
echo "   - Chercher : 'Remote - SSH'"
echo ""
echo "2. Se connecter au Mac mini"
echo "   - Palette : ⌘ + Shift + P"
echo "   - Taper : 'Remote-SSH: Connect to Host...'"
echo "   - Sélectionner : '$host_name'"
echo ""
echo "3. Ouvrir le dossier du projet web"
echo "   - Une fois connecté, ouvrir le dossier"
echo "   - Naviguer vers le projet RailSkills-Web"
echo ""
echo "═══════════════════════════════════════════════════════════════"

