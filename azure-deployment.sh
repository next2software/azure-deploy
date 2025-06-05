#!/bin/bash

APP_NAME="Cloud Orchestration SaaS"

# Check for Azure CLI
if ! command -v az &> /dev/null; then
  echo "Azure CLI is required. Please install it first."
  exit 1
fi

# Check Azure login status
if ! az account show --only-show-errors &> /dev/null; then
  echo "You're not signed in to Azure. Please run 'az login' and try again."
  exit 1
fi

# Find the Enterprise Application
echo "Finding \"$APP_NAME\"..."
ENTERPRISE_APP_OBJECT_ID=$(az ad sp list --display-name "$APP_NAME" --query "[0].id" -o tsv --only-show-errors)

if [ -z "$ENTERPRISE_APP_OBJECT_ID" ]; then
  echo "\"$APP_NAME\" was not found in this Azure tenant."
  exit 1
fi

echo "Found: $APP_NAME"
echo

# Get available subscriptions
echo "Retrieving available subscriptions..."
mapfile -t subscriptions < <(az account list --query "[].{name:name, id:id}" -o tsv --only-show-errors)

if [ ${#subscriptions[@]} -eq 0 ]; then
  echo "No subscriptions available."
  exit 1
fi

# Display subscription options
declare -A subscription_ids
index=1
echo "Available Subscriptions:"
for sub in "${subscriptions[@]}"; do
  name=$(echo "$sub" | cut -f1)
  id=$(echo "$sub" | cut -f2)
  echo "[$index] $name ($id)"
  subscription_ids[$index]=$id
  ((index++))
done

# User input
echo
read -p "Select subscriptions to assign (comma-separated, e.g. 1,3): " selected_input
IFS=',' read -ra selected_indexes <<< "$selected_input"

# Assign role to each selected subscription
for idx in "${selected_indexes[@]}"; do
  sub_id="${subscription_ids[$idx]}"
  if [ -n "$sub_id" ]; then
    echo "Assigning access to subscription: $sub_id"
    az role assignment create \
      --assignee-object-id "$ENTERPRISE_APP_OBJECT_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "Contributor" \
      --scope "/subscriptions/$sub_id" \
      --only-show-errors &> /dev/null

    if [ $? -eq 0 ]; then
      echo "✅ Access granted for $sub_id"
    else
      echo "❌ Could not assign access for $sub_id"
    fi
  else
    echo "Invalid option: $idx"
  fi
done

echo
echo "Finished assigning access."
