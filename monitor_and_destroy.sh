#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Terraform Apply with monitoring...${NC}"

# Run terraform apply and capture its output and exit status
terraform apply -auto-approve 2>&1 | tee terraform.log
APPLY_STATUS=${PIPESTATUS[0]}

if [ $APPLY_STATUS -ne 0 ]; then
    echo -e "${RED}Error detected in Terraform apply! Status code: $APPLY_STATUS${NC}"
    echo -e "${YELLOW}Starting automatic destroy...${NC}"
    
    # Wait a moment before destroying to ensure any partial resources are registered
    sleep 10
    
    # Run terraform destroy
    terraform destroy -auto-approve
    DESTROY_STATUS=$?
    
    if [ $DESTROY_STATUS -eq 0 ]; then
        echo -e "${GREEN}Resources successfully destroyed${NC}"
    else
        echo -e "${RED}Error during destroy! Manual cleanup may be needed${NC}"
        echo -e "${RED}Please check AWS console for any remaining resources${NC}"
        exit 2
    fi
    
    exit 1
else
    echo -e "${GREEN}Terraform apply completed successfully!${NC}"
    echo -e "${GREEN}Cluster is being created. You can monitor its status in the AWS console${NC}"
    exit 0
fi 
