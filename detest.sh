#!/bin/bash

# 🔐 Your SPN object ID
SPN_OBJECT_ID="fc90b168-67b2-4db9-9891-5bcac2f6de94"

# 🧙 Fetch subscriptions (name and ID)
mapfile -t SUB_NAMES < <(az account list --query "[].name" -o tsv)
mapfile -t SUB_IDS < <(az account list --query "[].id" -o tsv)

if [ ${#SUB_NAMES[@]} -eq 0 ]; then
  echo "🚫 No subscriptions found. Make sure you're logged in: az login"
  exit 1
fi

# 🧾 Display numbered list
echo "🎯 Select subscriptions to deploy to:"
for i in "${!SUB_NAMES[@]}"; do
  printf "  [%2d] %s\n" "$((i+1))" "${SUB_NAMES[$i]}"
done

# 👇 Get user selection by number
read -rp $'\nEnter numbers separated by space (e.g. 1 2 4): ' -a SELECTED_INDEXES

# ❌ Validate input
if [ ${#SELECTED_INDEXES[@]} -eq 0 ]; then
  echo "🚫 Nothing selected. Exiting."
  exit 1
fi

# 🚀 Deploy to each selected subscription
for IDX in "${SELECTED_INDEXES[@]}"; do
  if ! [[ "$IDX" =~ ^[0-9]+$ ]] || (( IDX < 1 || IDX > ${#SUB_NAMES[@]} )); then
    echo "⚠️ Invalid selection: $IDX. Skipping."
    continue
  fi

  SUB_NAME="${SUB_NAMES[$((IDX-1))]}"
  SUB_ID="${SUB_IDS[$((IDX-1))]}"

  echo ""
  echo "🟢 Deploying to: $SUB_NAME [$SUB_ID]"
  az account set --subscription "$SUB_ID"

  az deployment sub create \
    --location uksouth \
    --template-uri "https://app.cloudorchestrate.io/azure/template/serve/d1e7a748-bf0d-4383-81f5-4bfcfaed9c0a.json" \
    --parameters servicePrincipalObjectId="$SPN_OBJECT_ID"

  echo "✅ Done with $SUB_NAME"
done

echo ""
echo "🏁 All deployments finished, fam. Go flex. 💪"
