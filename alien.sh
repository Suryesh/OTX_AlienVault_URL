#!/bin/bash

# Banner
cat << "EOF"

 █████╗ ██╗     ██╗███████╗███╗   ██╗    ██╗   ██╗██████╗ ██╗     ███████╗
██╔══██╗██║     ██║██╔════╝████╗  ██║    ██║   ██║██╔══██╗██║     ██╔════╝
███████║██║     ██║█████╗  ██╔██╗ ██║    ██║   ██║██████╔╝██║     ███████╗
██╔══██║██║     ██║██╔══╝  ██║╚██╗██║    ██║   ██║██╔══██╗██║     ╚════██║
██║  ██║███████╗██║███████╗██║ ╚████║    ╚██████╔╝██║  ██║███████╗███████║
╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚═╝  ╚═══╝     ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
                                           		Built by Suryesh
                                           		                                           		
EOF

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

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
echo -n -e "${BLUE}Do you want to pass a single domain or a file containing subdomains? (Press 'Enter' for single domain, type 'f' for file): ${NC}"
read -e input_type

if [ "$input_type" == "" ]; then
    # User pressed Enter for single domain
    echo -n -e "${BLUE}Enter the domain (e.g., example.com): ${NC}"
    read -e domain

    if [ -z "$domain" ]; then
        echo -e "${RED}[ERROR] No domain provided. Exiting.${NC}"
        exit 1
    fi

    process_domain "$domain"

elif [ "$input_type" == "f" ]; then

    echo -n -e "${BLUE}Enter the path to the file containing subdomains without HTTP/HTTPS (e.g., /path/subdomains.txt): ${NC}"
    read -e subdomain_file

    if [ ! -f "$subdomain_file" ]; then
        echo -e "${RED}[ERROR] File not found. Exiting.${NC}"
        exit 1
    fi

    while IFS= read -r subdomain; do
        if [ -n "$subdomain" ]; then
            process_domain "$subdomain"
        fi
    done < "$subdomain_file"

else
    echo -e "${RED}[ERROR] Invalid input type. Please press Enter for single domain or type 'f' for file. Exiting.${NC}"
    exit 1
fi

exit 0
