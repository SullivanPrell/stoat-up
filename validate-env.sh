#!/usr/bin/env bash
# Script to validate .env file configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Validating .env configuration..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}ERROR: .env file not found!${NC}"
    echo "Run: cp .env.example .env"
    echo "Then edit .env with your configuration"
    exit 1
fi

# Load .env file
source .env

# Required variables
REQUIRED_VARS=(
    "TF_VAR_region"
    "TF_VAR_tenancy_ocid"
    "TF_VAR_user_ocid"
    "TF_VAR_fingerprint"
    "TF_VAR_private_key_path"
    "TF_VAR_compartment_ocid"
    "TF_VAR_ssh_public_key"
    "TF_VAR_domain_name"
    "STOAT_DOMAIN"
    "ANSIBLE_SSH_PRIVATE_KEY"
)

# Track validation status
ERRORS=0
WARNINGS=0

# Check each required variable
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}✗ Missing required variable: $var${NC}"
        ERRORS=$((ERRORS + 1))
    else
        # Check if it contains example values
        if echo "${!var}" | grep -q "example.com\|aaaaaa\|aa:bb:cc"; then
            echo -e "${YELLOW}⚠ Variable $var contains example value: ${!var}${NC}"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "${GREEN}✓ $var is set${NC}"
        fi
    fi
done

# Additional validation
echo ""
echo "Performing additional validation..."

# Check if SSH private key exists
if [ -n "$ANSIBLE_SSH_PRIVATE_KEY" ]; then
    SSH_KEY_PATH="${ANSIBLE_SSH_PRIVATE_KEY/#\~/$HOME}"
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${RED}✗ SSH private key not found at: $SSH_KEY_PATH${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✓ SSH private key found${NC}"
        
        # Check permissions
        PERMS=$(stat -c %a "$SSH_KEY_PATH" 2>/dev/null || stat -f %Lp "$SSH_KEY_PATH" 2>/dev/null)
        if [ "$PERMS" != "600" ]; then
            echo -e "${YELLOW}⚠ SSH key has incorrect permissions ($PERMS). Should be 600${NC}"
            echo "  Fix with: chmod 600 $SSH_KEY_PATH"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi

# Check if OCI API key exists
if [ -n "$TF_VAR_private_key_path" ]; then
    OCI_KEY_PATH="${TF_VAR_private_key_path/#\~/$HOME}"
    if [ ! -f "$OCI_KEY_PATH" ]; then
        echo -e "${RED}✗ OCI API private key not found at: $OCI_KEY_PATH${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✓ OCI API private key found${NC}"
    fi
fi

# Summary
echo ""
echo "======================================"
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Validation failed with $ERRORS error(s)${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Validation passed with $WARNINGS warning(s)${NC}"
    echo "Please review the warnings above before proceeding"
    exit 0
else
    echo -e "${GREEN}All validations passed!${NC}"
    echo "Your configuration is ready to use"
    exit 0
fi
