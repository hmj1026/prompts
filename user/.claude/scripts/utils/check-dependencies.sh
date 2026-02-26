#!/bin/bash

# Check all dependencies for PHP hooks
# This script verifies that all required and optional tools are installed

echo "🔍 Checking PHP Hooks Dependencies..."
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
installed=0
missing=0
optional_missing=0

# Helper function
check_command() {
    local cmd=$1
    local type=$2  # required or optional
    local package=$3  # for installation help

    if command -v "$cmd" &> /dev/null; then
        version=$($cmd --version 2>&1 | head -n 1 | cut -d' ' -f1-3)
        printf "${GREEN}✅${NC} %-20s %s\n" "$cmd" "$version"
        ((installed++))
        return 0
    else
        if [ "$type" = "required" ]; then
            printf "${RED}❌${NC} %-20s NOT INSTALLED\n" "$cmd"
            [ -n "$package" ] && printf "   Install: %s\n" "$package"
            ((missing++))
        else
            printf "${YELLOW}⚠️${NC}  %-20s NOT INSTALLED (optional)\n" "$cmd"
            [ -n "$package" ] && printf "   Install: %s\n" "$package"
            ((optional_missing++))
        fi
        return 1
    fi
}

# Check command in Docker container
check_docker_command() {
    local container=$1
    local cmd=$2
    local type=$3  # required or optional

    if docker exec "$container" which "$cmd" &>/dev/null 2>&1; then
        version=$(docker exec "$container" "$cmd" --version 2>&1 | head -n 1 | cut -d' ' -f1-3)
        printf "${GREEN}✅${NC} %-20s %s (docker: $container)\n" "$cmd" "$version"
        ((installed++))
        return 0
    else
        if [ "$type" = "required" ]; then
            printf "${RED}❌${NC} %-20s NOT FOUND in docker\n" "$cmd"
            ((missing++))
        else
            printf "${YELLOW}⚠️${NC}  %-20s NOT FOUND in docker (optional)\n" "$cmd"
            ((optional_missing++))
        fi
        return 1
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Core System Tools (Required)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_command "bash" "required" "apt install bash"
check_command "python3" "required" "apt install python3"
check_command "grep" "required" "apt install grep"
check_command "git" "required" "apt install git"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PHP Tools (Required for Basic Hooks)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_command "php" "required" "apt install php-cli"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Optional Testing & Quality Tools"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check phpunit: local first, then docker
if command -v phpunit &>/dev/null; then
    version=$(phpunit --version 2>&1 | head -n 1 | cut -d' ' -f1-3)
    printf "${GREEN}✅${NC} %-20s %s\n" "phpunit" "$version"
    ((installed++))
else
    check_docker_command "pos_php" "phpunit" "optional"
fi

check_command "phpcs" "optional" "composer require --dev squizlabs/php_codesniffer"
check_command "phpstan" "optional" "composer require --dev phpstan/phpstan"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Docker (Optional - for containerized testing)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_command "docker" "optional" "Install Docker Desktop"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Dependency Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

total=$((installed + missing + optional_missing))
echo ""
printf "Total tools checked: %d\n" "$total"
printf "${GREEN}Installed: %d${NC}\n" "$installed"
printf "${RED}Missing (required): %d${NC}\n" "$missing"
printf "${YELLOW}Missing (optional): %d${NC}\n" "$optional_missing"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Detailed Hook Dependencies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
printf '%b\n' "${BLUE}1. pre-commit-validation.sh (CORE - Always Runs)${NC}"
echo "   Required: bash, grep, php, git"
echo "   Status:"
command -v bash &>/dev/null && echo "   ✅ bash" || echo "   ❌ bash"
command -v grep &>/dev/null && echo "   ✅ grep" || echo "   ❌ grep"
command -v php &>/dev/null && echo "   ✅ php" || echo "   ❌ php"
command -v git &>/dev/null && echo "   ✅ git" || echo "   ❌ git"

echo ""
printf '%b\n' "${BLUE}2. verify-setup.sh (Validation Tool)${NC}"
echo "   Required: bash, python3, grep"
echo "   Status:"
command -v bash &>/dev/null && echo "   ✅ bash" || echo "   ❌ bash"
command -v python3 &>/dev/null && echo "   ✅ python3" || echo "   ❌ python3"
command -v grep &>/dev/null && echo "   ✅ grep" || echo "   ❌ grep"

echo ""
printf '%b\n' "${BLUE}3. run-phpunit-tests.sh (OPTIONAL)${NC}"
echo "   Required: bash"
echo "   Optional: phpunit, docker"
echo "   Status:"
command -v bash &>/dev/null && echo "   ✅ bash" || echo "   ❌ bash"
command -v phpunit &>/dev/null && echo "   ✅ phpunit" || echo "   ⚠️  phpunit (optional)"
command -v docker &>/dev/null && echo "   ✅ docker" || echo "   ⚠️  docker (optional)"

echo ""
printf '%b\n' "${BLUE}4. php-code-style-check.sh (OPTIONAL)${NC}"
echo "   Required: bash"
echo "   Optional: phpcs"
echo "   Status:"
command -v bash &>/dev/null && echo "   ✅ bash" || echo "   ❌ bash"
command -v phpcs &>/dev/null && echo "   ✅ phpcs" || echo "   ⚠️  phpcs (optional)"

echo ""
printf '%b\n' "${BLUE}5. phpstan-analysis.sh (OPTIONAL)${NC}"
echo "   Required: bash"
echo "   Optional: phpstan"
echo "   Status:"
command -v bash &>/dev/null && echo "   ✅ bash" || echo "   ❌ bash"
command -v phpstan &>/dev/null && echo "   ✅ phpstan" || echo "   ⚠️  phpstan (optional)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Recommendation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $missing -eq 0 ]; then
    printf '%b\n' "${GREEN}✅ All required dependencies are installed!${NC}"
    echo ""
    echo "Your hooks are ready to use:"
    echo "  • pre-commit-validation.sh - ACTIVE"
    echo "  • verify-setup.sh - READY"

    if command -v phpunit &>/dev/null || docker exec pos_php which phpunit &>/dev/null; then
        echo "  • run-phpunit-tests.sh - READY"
    else
        echo "  • run-phpunit-tests.sh - available (install phpunit to activate)"
    fi

    if command -v phpcs &>/dev/null; then
        echo "  • php-code-style-check.sh - READY"
    else
        echo "  • php-code-style-check.sh - available (install phpcs to activate)"
    fi

    if command -v phpstan &>/dev/null; then
        echo "  • phpstan-analysis.sh - READY"
    else
        echo "  • phpstan-analysis.sh - available (install phpstan to activate)"
    fi

    exit 0
else
    printf '%b\n' "${RED}❌ Missing required dependencies!${NC}"
    echo ""
    echo "You must install these tools:"
    [ ! command -v bash &>/dev/null ] && echo "  • bash"
    [ ! command -v python3 &>/dev/null ] && echo "  • python3"
    [ ! command -v grep &>/dev/null ] && echo "  • grep"
    [ ! command -v git &>/dev/null ] && echo "  • git"
    [ ! command -v php &>/dev/null ] && echo "  • php"
    echo ""
    echo "Install on Ubuntu/Debian:"
    echo "  sudo apt update && sudo apt install bash python3 grep git php-cli"
    exit 1
fi
