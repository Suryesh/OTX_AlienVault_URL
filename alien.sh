#!/bin/bash

# Banner
echo -e "\033[1;31m"
cat <<"EOF"
 █████╗ ██╗     ██╗███████╗███╗   ██╗    ██╗   ██╗██████╗ ██╗     ███████╗
██╔══██╗██║     ██║██╔════╝████╗  ██║    ██║   ██║██╔══██╗██║     ██╔════╝
███████║██║     ██║█████╗  ██╔██╗ ██║    ██║   ██║██████╔╝██║     ███████╗
██╔══██║██║     ██║██╔══╝  ██║╚██╗██║    ██║   ██║██╔══██╗██║     ╚════██║
██║  ██║███████╗██║███████╗██║ ╚████║    ╚██████╔╝██║  ██║███████╗███████║
╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚═╝  ╚═══╝     ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
                                          Built by Suryesh, V: 0.5
EOF
echo -e "\033[0m"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

#checking update
check_for_updates() {
    repo_url="https://raw.githubusercontent.com/Suryesh/OTX_AlienVault_URL/main/alien.sh"
    local_script="$(realpath "$0")"

    echo -e "${BLUE}[INFO]${NC} Checking for updates..."
    latest_script=$(curl -s "$repo_url")

    if [[ -z "$latest_script" ]]; then
        echo -e "${RED}[ERROR]${NC} Unable to fetch the latest script. Check your internet connection."
        return
    fi

    echo -e "${BLUE}[INFO]${NC} Fetched latest script content."

    if [[ "$latest_script" != "$(cat "$local_script")" ]]; then
        echo -e "${BLUE}[INFO]${NC} A new version of the script is available."
        echo -n "Do you want to update? (y/n): "
        read -r update_choice
        if [[ "${update_choice,,}" == "y" ]]; then
            echo "$latest_script" >"$local_script"
            chmod +x "$local_script"
            echo -e "${GREEN}[SUCCESS]${NC} Script updated successfully. Restarting..."
            exec "$local_script" "$@"
        else
            echo -e "${BLUE}[INFO]${NC} Update skipped. Continuing with the current version."
        fi
    else
        echo -e "${BLUE}[INFO]${NC} You are using the latest version of the script."
    fi
}


#checking dependencies
check_dependencies() {
    local dependencies=("curl" "jq")
    local missing=()

    echo -e "${BLUE}[INFO]${NC} Checking dependencies..."
    sleep 1
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[ERROR]${NC} Missing dependencies: ${missing[*]}."
        echo -e "${BLUE}[INFO]${NC} Please install the missing dependencies and try again."
        exit 1
    fi

    echo -e "${GREEN}[INFO]${NC} All dependencies are installed."
    sleep 1
    clear
}

# Function to validate domain format
is_valid_domain() {
    if [[ "$1" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate file path
is_valid_file_path() {
    if [[ -f "$1" && -r "$1" ]]; then
        return 0
    else
        return 1
    fi
}

process_domain() {
    local domain=$1
    local output_dir="logs_otx/$domain"
    local output_file="$output_dir/urls.txt"
    local base_url="https://otx.alienvault.com/api/v1/indicators/domain/$domain/url_list?limit=500&page="
    local page=1
    local found_urls=0

    mkdir -p "$output_dir"
    echo -e "${BLUE}[INFO]${NC} Starting to scrape URLs for domain: $domain"

    while true; do
        echo -e "${BLUE}[INFO]${NC} Fetching page $page..."
        response=$(curl -s "$base_url$page")
        urls=$(echo "$response" | jq -r '.url_list[].url' 2>/dev/null)

        if [ -z "$urls" ]; then
            echo -e "${BLUE}[INFO]${NC} No more URLs found for domain $domain. Stopping."
            break
        fi

        echo "$urls" >>"$output_file"
        found_urls=$((found_urls + $(echo "$urls" | wc -l)))

        page=$((page + 1))
    done

    if [ $found_urls -eq 0 ]; then
        echo -e "${BLUE}[INFO]${NC} No URLs found for domain: $domain."
    else
        echo -e "${GREEN}[INFO]${NC} Scraping completed for domain: $domain. Results saved in $output_file"
    fi
}

# Main script
check_dependencies
check_for_updates

while true; do
    clear
    echo -e "${BLUE}Choose an option:${NC}"
    echo -e "${GREEN}1.${NC} Process a single domain"
    echo -e "${GREEN}2.${NC} Process a file containing subdomains"
    echo -n -e "${BLUE}Enter your choice [1/2]: ${NC}"
    read -r choice

    case "${choice,,}" in # handle case-insensitivity
    1)
        clear
        echo -n -e "${BLUE}Enter the domain (e.g., example.com): ${NC}"
        read -r domain

        if [ -z "$domain" ]; then
            echo -e "${RED}[ERROR]${NC} No domain provided."
            continue
        fi
        
        # Validate the domain format
            if ! is_valid_domain "$domain"; then
                echo -e "${RED}[ERROR]${NC} Invalid domain format. Please enter a valid domain (e.g., example.com, sub.example.com)."
                continue
            fi

        process_domain "$domain"
        break
        ;;
    2)
        clear
        while true; do
            echo -n -e "${BLUE}Enter the file path : ${NC}"
            read -e -r subdomain_file

            if [ ! -f "$subdomain_file" ]; then
                echo -e "${RED}[ERROR]${NC} File not found. Please try again or press [q] to quit."
                echo -e "${BLUE}Enter [t] to try again, or [q] to quit: ${NC}"
                read -r retry_choice
                case "${retry_choice,,}" in
                t)
                    continue # Try again for the file input
                    ;;
                q)
                    exit 0
                    ;;
                *)
                    echo -e "${RED}[ERROR]${NC} Invalid choice, exiting."
                    exit 1
                    ;;
                esac
            fi

            while IFS= read -r subdomain; do
                if [ -n "$subdomain" ]; then
                    # Validate the subdomain format
                    if is_valid_domain "$subdomain"; then
                        process_domain "$subdomain"
                    else
                        echo -e "${RED}[ERROR]${NC} Invalid subdomain format: $subdomain."
                    fi
                fi
            done <"$subdomain_file"
            break
        done
        break
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Invalid choice. Please enter option 1 or 2. Press [q] to quit."
        echo -n -e "${BLUE}Enter [q] to quit or press any key to try again: ${NC}"
        read -r quit_choice
        if [ "${quit_choice,,}" == "q" ]; then
            exit 0
        fi
        continue
        ;;
    esac
done

exit 0
