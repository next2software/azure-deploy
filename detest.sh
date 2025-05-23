#!/bin/bash

# Replace with your SPN object ID
SPN_OBJECT_ID="fc90b168-67b2-4db9-9891-5bcac2f6de94"

# Fetch all subscriptions with name and ID
echo "Fetching available subscriptions..."
az account list --query "[].{name:name, id:id}" -o table

# Ask the user which subscriptions to deploy to (comma-separated)
read -rp "Enter comma-separated subscription IDs you want to deploy to: " INPUT_IDS

# Convert input string into array
IFS=',' read -ra SELECTED_IDS <<< "$INPUT_IDS"

# Loop over selected subscriptions
for SUBSCRIPTION_ID in "${SELECTED_IDS[@]}"
do
    # Trim whitespace
    SUBSCRIPTION_ID=$(echo "$SUBSCRIPTION_ID" | xargs)

    echo ""
    echo "🔄 Deploying to subscription: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID"

    az deployment sub create \
      --location uksouth \
      --template-uri "https://app.cloudorchestrate.io/azure/template/serve/d1e7a748-bf0d-4383-81f5-4bfcfaed9c0a.json" \
      --parameters servicePrincipalObjectId="$SPN_OBJECT_ID"

    echo "✅ Done with $SUBSCRIPTION_ID"
done

echo ""
echo "🚀 All selected deployments complete."
