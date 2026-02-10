#!/usr/bin/env bash
# colors.sh - Demonstrate colorful output with shurl

show_logo() {
    cat << "EOF"

      ____  ___   _     ____________
     / __ \/   | ( )  _/_/ ____/ __ \
    / / / / /| |  V _/_//___ \/ / / /
   / /_/ / ___ |  _/_/ ____/ / /_/ /
  /_____/_/  |_| /_/  /_____/\____/
      Keeping AI Productive
    50 Days In And Beyond

EOF
}

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
NC='\033[0m' # No Color

# Background colors
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'
BG_WHITE='\033[47m'

show_colors() {
    echo -e "${BOLD}🎨 shurl Color Demonstration${NC}"
    echo "="=============================
    echo ""
    
    echo -e "${BOLD}Basic Colors:${NC}"
    echo -e "  ${RED}Red text${NC} - For ${RED}errors${NC} or ${RED}critical warnings${NC}"
    echo -e "  ${GREEN}Green text${NC} - For ${GREEN}success messages${NC} and ${GREEN}✓ checkmarks${NC}"
    echo -e "  ${YELLOW}Yellow text${NC} - For ${YELLOW}highlights${NC} and ${YELLOW}⚠ warnings${NC}"
    echo -e "  ${BLUE}Blue text${NC} - For ${BLUE}information${NC} and ${BLUE}status updates${NC}"
    echo -e "  ${PURPLE}Purple text${NC} - For ${PURPLE}special notes${NC} and ${PURPLE}metadata${NC}"
    echo -e "  ${CYAN}Cyan text${NC} - For ${CYAN}code${NC}, ${CYAN}commands${NC}, and ${CYAN}user input${NC}"
    echo -e "  ${GRAY}Gray text${NC} - For ${GRAY}secondary information${NC} and ${GRAY}disabled items${NC}"
    
    echo ""
    echo -e "${BOLD}Text Effects:${NC}"
    echo -e "  ${BOLD}Bold text${NC} - For ${BOLD}headings${NC} and ${BOLD}emphasis${NC}"
    echo -e "  ${UNDERLINE}Underlined text${NC} - For ${UNDERLINE}links${NC} and ${UNDERLINE}titles${NC}"
    echo -e "  ${BLINK}Blinking text${NC} - For ${BLINK}alerts${NC} (rarely used)"
    echo -e "  ${REVERSE}Reversed text${NC} - For ${REVERSE}high contrast${NC}"
    
    echo ""
    echo -e "${BOLD}Background Colors:${NC}"
    echo -e "  ${BG_RED}${WHITE} Red background ${NC} - For ${BG_RED}${WHITE} severe errors ${NC}"
    echo -e "  ${BG_GREEN}${WHITE} Green background ${NC} - For ${BG_GREEN}${WHITE} success states ${NC}"
    echo -e "  ${BG_YELLOW}${BLACK} Yellow background ${NC} - For ${BG_YELLOW}${BLACK} warnings ${NC}"
    echo -e "  ${BG_BLUE}${WHITE} Blue background ${NC} - For ${BG_BLUE}${WHITE} information boxes ${NC}"
    echo -e "  ${BG_PURPLE}${WHITE} Purple background ${NC} - For ${BG_PURPLE}${WHITE} special notices ${NC}"
    
    echo ""
    echo -e "${BOLD}Combination Examples:${NC}"
    echo -e "  ${BOLD}${GREEN}✓ Success:${NC} ${GREEN}Operation completed successfully${NC}"
    echo -e "  ${BOLD}${RED}✗ Error:${NC} ${RED}Failed to download file${NC}"
    echo -e "  ${BOLD}${YELLOW}⚠ Warning:${NC} ${YELLOW}This action cannot be undone${NC}"
    echo -e "  ${BOLD}${CYAN}ℹ Info:${NC} ${CYAN}Downloading from GitHub...${NC}"
    echo -e "  ${BOLD}${BLUE}→ Command:${NC} ${CYAN}shurl gh:user/repo/script.sh${NC}"
    
    echo ""
    echo -e "${BG_BLUE}${WHITE}${BOLD} Tip ${NC} ${BLUE}Scripts using colors are more user-friendly!${NC}"
}

show_shurl_examples() {
    echo ""
    echo -e "${BOLD}🚀 shurl Usage Examples with Colors:${NC}"
    echo "="=====================================
    echo ""
    
    echo -e "${GREEN}Basic usage:${NC}"
    echo -e "  ${CYAN}shurl https://example.com/script.sh${NC}"
    echo ""
    
    echo -e "${YELLOW}GitHub shorthand:${NC}"
    echo -e "  ${CYAN}shurl gh:user/repo/install.sh${NC}"
    echo -e "  ${CYAN}shurl gh:user/repo@develop/setup.sh${NC}"
    echo ""
    
    echo -e "${BLUE}Safety features:${NC}"
    echo -e "  ${CYAN}shurl ${BOLD}--dry-run${NC}${CYAN} gh:external/tool/install.sh${NC}"
    echo -e "  ${CYAN}shurl ${BOLD}--update${NC}${CYAN} gh:team/scripts/deploy.sh${NC}"
    echo -e "  ${CYAN}shurl ${BOLD}--clear-cache${NC}"
    echo ""
    
    echo -e "${PURPLE}With arguments:${NC}"
    echo -e "  ${CYAN}shurl gh:org/tool/run.sh ${YELLOW}--verbose --force --output=result.txt${NC}"
    echo ""
    
    echo -e "${RED}Danger zone (preview first!):${NC}"
    echo -e "  ${CYAN}shurl --dry-run https://unknown-source.com/install.sh${NC}"
    echo -e "  ${GRAY}# Always preview scripts from untrusted sources${NC}"
}

show_color_code() {
    echo ""
    echo -e "${BOLD}📝 Color Code Reference:${NC}"
    echo "="===========================
    echo ""
    
    cat << "EOF"
# Define colors at the top of your script
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'  # No Color (reset)

# Usage in echo with -e flag
echo -e "${GREEN}Success!${NC}"
echo -e "${RED}Error:${NC} Something went wrong"
echo -e "${BOLD}${BLUE}Information:${NC} Processing data..."

# For printf (no -e needed)
printf "${YELLOW}Warning:${NC} This is a warning\n"
printf "${CYAN}Command:${NC} shurl gh:user/repo/script.sh\n"

# Remember: Always reset with ${NC}!
EOF
    
    echo ""
    echo -e "${YELLOW}⚠ Note:${NC} Not all terminals support all colors and effects."
    echo -e "      Test in your target environment."
}

main() {
    show_logo
    echo -e "${CYAN}🎨 Color Demonstration Script${NC}"
    echo ""
    echo -e "This script shows how ${BOLD}colorful output${NC} can improve"
    echo -e "the user experience of shell scripts run via ${CYAN}shurl${NC}."
    echo ""
    
    show_colors
    show_shurl_examples
    show_color_code
    
    echo ""
    echo -e "${GREEN}${BOLD}✓ Try it yourself:${NC}"
    echo -e "  ${CYAN}shurl --dry-run gh:day50-dev/shurl/examples/colors.sh${NC}"
    echo -e "  ${CYAN}shurl gh:day50-dev/shurl/examples/colors.sh${NC}"
    echo ""
    echo -e "${GRAY}Script cached at: $HOME/.cache/shurl/$(echo "https://raw.githubusercontent.com/day50-dev/shurl/main/examples/colors.sh" | sha256sum | cut -d' ' -f1).sh${NC}"
    
    echo ""
    echo -e "${BG_CYAN}${WHITE}${BOLD} Remember ${NC} ${CYAN}Use colors to make your scripts more readable and user-friendly!${NC}"
}

main "$@"
