#!/bin/bash

# ========================
# Configurable Parameters
# ========================
SP_NAME="gh-action-sp"
RESOURCE_GROUP="rg-gaviti-prod"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
LOCATION="centralus"

# ========================
# Create the Service Principal
# ========================
echo "Creating service principal '$SP_NAME' for resource group '$RESOURCE_GROUP'..."

az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --sdk-auth \
  --output json > azure-credentials.json

# ========================
# Output Results
# ========================
echo ""
echo "✅ Service principal created successfully."
echo "📄 'azure-credentials.json' saved locally. Add this to GitHub as secret 'AZURE_CREDENTIALS'."
echo "📋 Your AZURE_SUBSCRIPTION_ID value:"
echo "$SUBSCRIPTION_ID"

echo ""
echo "🚨 Be sure to delete 'azure-credentials.json' after saving it to GitHub for security!"
