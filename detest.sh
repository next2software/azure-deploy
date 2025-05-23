#!/bin/bash

# 🔐 Service Principal Object ID
SPN_OBJECT_ID="fc90b168-67b2-4db9-9891-5bcac2f6de94"

# 📥 Fetch subscriptions into an array
mapfile -t SUBSCRIPTIONS < <(az account list --query "[].{name:name, id:id}" -o tsv)

# 🧾 Display numbered list
echo "🎯 Available Azure Subscriptions:"
for i in "${!SUBSCRIPTIONS[@]}"; do
    NAME=$(echo "${SUBSCRIPTIONS[$i]}" | cut -f1)
    echo "  [$((i+1))] $NAME"
done

# 🧑 Prompt user to select subscriptions
read -rp $'\nEnter the numbers of the subscriptions to deploy to (e.g., 1 3 5): ' -a SELECTIONS

# ❌ Check for empty input
if [ ${#SELECTIONS[@]} -eq 0 ]; then
    echo "🚫 No subscriptions selected. Exiting."
    exit 1
fi

# 🚀 Loop through selected subscriptions
for INDEX in "${SELECTIONS[@]}"; do
    if ! [[ "$INDEX" =~ ^[0-9]+$ ]] || (( INDEX < 1 || INDEX > ${#SUBSCRIPTIONS[@]} )); then
        echo "⚠️ Skipping invalid selection: $INDEX"
        continue
    fi

    SUB_LINE="${SUBSCRIPTIONS[$((INDEX-1))]}"
    SUB_NAME=$(echo "$SUB_LINE" | cut -f1)
    SUB_ID=$(echo "$SUB_LINE" | cut -f2)

    echo ""
    echo "🔄 Deploying to [$SUB_NAME] ($SUB_ID)"
    az account set --subscription "$SUB_ID"

    az deployment sub create \
      --location uksouth \
      --template-uri "https://app.cloudorchestrate.io/azure/template/serve/d1e7a748-bf0d-4383-81f5-4bfcfaed9c0a.json" \
      --parameters servicePrincipalObjectId="$SPN_OBJECT_ID"

    echo "✅ Deployment complete for $SUB_NAME"
done

echo ""
echo "🏁 All selected deployments done!"
