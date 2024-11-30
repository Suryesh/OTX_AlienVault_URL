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

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# Prompt for domain
echo -e -n "${CYAN}Enter the domain: ${NC}"
read domain

# Check if the domain is provided
if [ -z "$domain" ]; then
    echo -e "${RED}[ERROR] No domain provided. Exiting.${NC}"
    exit 1
fi

# Create output directory
output_dir="logs_otx/$domain"
mkdir -p "$output_dir"
output_file="$output_dir/urls.txt"

# Base URL for AlienVault OTX API
base_url="https://otx.alienvault.com/api/v1/indicators/domain/$domain/url_list?limit=500&page="

# Scrape URLs
page=1
found_urls=0

while true; do
    echo -e "${YELLOW}[INFO] Fetching page $page...${NC}"
    response=$(curl -s "$base_url$page")
    
    # Extract URLs from the response using jq
    urls=$(echo "$response" | jq -r '.url_list[].url' 2>/dev/null)

    if [ -z "$urls" ]; then
        echo -e "${YELLOW}[INFO] No more URLs found. Stopping.${NC}"
        break
    fi

    echo "$urls" >> "$output_file"
    found_urls=$((found_urls + $(echo "$urls" | wc -l)))
    page=$((page + 1))
done

if [ $found_urls -eq 0 ]; then
    echo -e "${RED}[INFO] No URLs found for domain: $domain.${NC}"
else
    echo -e "${GREEN}[INFO] Scraping completed for domain: $domain. Results saved in $output_file${NC}"
fi

exit 0
