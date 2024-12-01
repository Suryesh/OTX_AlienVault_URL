#!/bin/bash

# Banner
echo -e "\033[1;31m"
cat << "EOF"

 █████╗ ██╗     ██╗███████╗███╗   ██╗    ██╗   ██╗██████╗ ██╗     ███████╗
██╔══██╗██║     ██║██╔════╝████╗  ██║    ██║   ██║██╔══██╗██║     ██╔════╝
███████║██║     ██║█████╗  ██╔██╗ ██║    ██║   ██║██████╔╝██║     ███████╗
██╔══██║██║     ██║██╔══╝  ██║╚██╗██║    ██║   ██║██╔══██╗██║     ╚════██║
██║  ██║███████╗██║███████╗██║ ╚████║    ╚██████╔╝██║  ██║███████╗███████║
╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚═╝  ╚═══╝     ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
                                          Built by Suryesh, V: 0.3

EOF
echo -e "\033[0m"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Update check function
check_for_updates() {
    repo_url="https://raw.githubusercontent.com/Suryesh/OTX_AlienVault_URL/main/alien.sh"
    local_script="$(realpath "$0")"

    echo -e "\033[1;34m[INFO]\033[0m Checking for updates..."
    latest_script=$(curl -s "$repo_url")

    if [[ -z "$latest_script" ]]; then
        echo -e "\033[1;31m[ERROR]\033[0m Unable to fetch the latest script. Check your internet connection."
        return
    fi

    if [[ "$latest_script" != "$(cat "$local_script")" ]]; then
        echo -e "\033[1;34m[INFO]\033[0m A new version of the script is available."
        echo -n "Do you want to update? (y/n): "
        read -r update_choice
        if [[ "$update_choice" == "y" ]]; then
            echo "$latest_script" > "$local_script"
            chmod +x "$local_script"
            echo -e "\033[1;32m[INFO]\033[0m Script updated successfully. Restarting..."
            exec "$local_script" "$@"
        else
            echo -e "\033[1;34m[INFO]\033[0m Update skipped. Continuing with the current version."
        fi
    else
        echo -e "\033[1;34m[INFO]\033[0m You are using the latest version of the script."
    fi
}

check_for_updates "$@"

# Function to check dependencies
check_dependencies() {
    local dependencies=("curl" "jq")
    local missing=()

    echo -e "${BLUE}[INFO] Checking dependencies...${NC}"
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[ERROR] Missing dependencies: ${missing[*]}.${NC}"
        echo -e "${BLUE}[INFO] Please install the missing dependencies and try again.${NC}"
        exit 1
    fi

    echo -e "${GREEN}[INFO] All dependencies are installed.${NC}"
}

process_domain() {
    local domain=$1
    local output_dir="logs_otx/$domain"
    local output_file="$output_dir/urls.txt"
    local base_url="https://otx.alienvault.com/api/v1/indicators/domain/$domain/url_list?limit=500&page="
    local page=1
    local found_urls=0

    mkdir -p "$output_dir"
    echo -e "${BLUE}[INFO] Starting to scrape URLs for domain: $domain${NC}"

    while true; do
        echo -e "${BLUE}[INFO] Fetching page $page...${NC}"
        response=$(curl -s "$base_url$page")
        urls=$(echo "$response" | jq -r '.url_list[].url' 2>/dev/null)

        if [ -z "$urls" ]; then
            echo -e "${BLUE}[INFO] No more URLs found for domain $domain. Stopping.${NC}"
            break
        fi

        echo "$urls" >> "$output_file"
        found_urls=$((found_urls + $(echo "$urls" | wc -l)))

        page=$((page + 1))
    done

    if [ $found_urls -eq 0 ]; then
        echo -e "${BLUE}[INFO] No URLs found for domain: $domain.${NC}"
    else
        echo -e "${GREEN}[INFO] Scraping completed for domain: $domain. Results saved in $output_file${NC}"
    fi
}

# Main script
check_dependencies

echo -e "${BLUE}Choose an option:${NC}"
echo -e "${GREEN}1.${NC} Process a single domain"
echo -e "${GREEN}2.${NC} Process a file containing subdomains"
echo -n -e "${BLUE}Enter your choice [1/2]: ${NC}"
read -r choice

case $choice in
    1)
        echo -n -e "${BLUE}Enter the domain (e.g., example.com): ${NC}"
        read -r domain

        if [ -z "$domain" ]; then
            echo -e "${RED}[ERROR] No domain provided. Exiting.${NC}"
            exit 1
        fi

        process_domain "$domain"
        ;;
    2)
        echo -n -e "${BLUE}Enter the path to the file containing subdomains without HTTP/HTTPS (e.g., /path/subdomains.txt): ${NC}"
        read -r subdomain_file

        if [ ! -f "$subdomain_file" ]; then
            echo -e "${RED}[ERROR] File not found. Exiting.${NC}"
            exit 1
        fi

        while IFS= read -r subdomain; do
            if [ -n "$subdomain" ]; then
                process_domain "$subdomain"
            fi
        done < "$subdomain_file"
        ;;
    *)
        echo -e "${RED}[ERROR] Invalid choice. Please enter 1 or 2. Exiting.${NC}"
        exit 1
        ;;
esac

exit 0
