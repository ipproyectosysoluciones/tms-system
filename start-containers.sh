#!/bin/bash

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar el menú
show_menu() {
    echo -e "${BLUE}=== Sistema de Gestión de Contenedores TMS ===${NC}"
    echo "1) Iniciar entorno de desarrollo"
    echo "2) Iniciar entorno de pruebas"
    echo "3) Iniciar entorno de producción"
    echo "4) Detener todos los contenedores"
    echo "5) Salir"
}

# Función para iniciar contenedores
start_containers() {
    local env=$1
    case $env in
        "dev")
            echo -e "${GREEN}Iniciando entorno de desarrollo...${NC}"
            docker-compose up -d
            ;;
        "test")
            echo -e "${GREEN}Iniciando entorno de pruebas...${NC}"
            docker-compose -f docker-compose.test.yml up -d
            ;;
        "prod")
            echo -e "${GREEN}Iniciando entorno de producción...${NC}"
            if [ ! -f .env ]; then
                echo -e "${RED}Error: Archivo .env no encontrado${NC}"
                echo "Por favor, cree un archivo .env con las variables necesarias para producción:"
                echo "MYSQL_ROOT_PASSWORD=your_root_password"
                echo "MYSQL_PASSWORD=your_password"
                return 1
            fi
            docker-compose -f docker-compose.prod.yml up -d
            ;;
    esac
}

# Función para detener contenedores
stop_containers() {
    echo -e "${RED}Deteniendo todos los contenedores...${NC}"
    docker-compose down
    docker-compose -f docker-compose.test.yml down
    docker-compose -f docker-compose.prod.yml down
}

# Bucle principal
while true; do
    show_menu
    read -p "Seleccione una opción (1-5): " choice

    case $choice in
        1)
            start_containers "dev"
            ;;
        2)
            start_containers "test"
            ;;
        3)
            start_containers "prod"
            ;;
        4)
            stop_containers
            ;;
        5)
            echo -e "${BLUE}¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida. Por favor, seleccione una opción válida (1-5).${NC}"
            ;;
    esac

    echo
    read -p "Presione Enter para continuar..."
    clear
done