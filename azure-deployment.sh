#!/bin/bash

APP_ID="4da14022-49ca-45de-a174-d6e180dd8f3f"

# Check for Azure CLI
if ! command -v az &> /dev/null; then
  echo "Azure CLI (az) is required but not installed. Please install it first."
  exit 1
fi

# Login check
if ! az account show --only-show-errors &> /dev/null; then
  echo "Please log in to Azure first using 'az login'."
  exit 1
fi

# Lookup Enterprise Application object ID by appId
echo "Looking up Enterprise Application with appId: \"$APP_ID\"..."
ENTERPRISE_APP_OBJECT_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv --only-show-errors)

if [ -z "$ENTERPRISE_APP_OBJECT_ID" ]; then
  echo "Enterprise Application with appId \"$APP_ID\" not found in this tenant."
  exit 1
fi

echo "Found Enterprise App Object ID: $ENTERPRISE_APP_OBJECT_ID"
echo

# Fetch all subscriptions
echo "Fetching Azure subscriptions..."
mapfile -t subscriptions < <(az account list --query "[].{name:name, id:id}" -o tsv --only-show-errors)

if [ ${#subscriptions[@]} -eq 0 ]; then
  echo "No subscriptions found."
  exit 1
fi

# Display options
echo "Available Subscriptions:"
declare -A subscription_ids
index=1
for sub in "${subscriptions[@]}"; do
  name=$(echo "$sub" | cut -f1)
  id=$(echo "$sub" | cut -f2)
  echo "[$index] $name ($id)"
  subscription_ids[$index]=$id
  ((index++))
done

# Prompt user for selection
echo
read -p "Enter the numbers of the subscriptions to assign (comma-separated, e.g. 1,3): " selected_input

IFS=',' read -ra selected_indexes <<< "$selected_input"

# Assign the role
for idx in "${selected_indexes[@]}"; do
  sub_id="${subscription_ids[$idx]}"
  if [ -n "$sub_id" ]; then
    echo "Assigning Contributor role to Enterprise App for subscription: $sub_id"
    az role assignment create \
      --assignee-object-id "$ENTERPRISE_APP_OBJECT_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "Contributor" \
      --scope "/subscriptions/$sub_id" \
      --only-show-errors &> /dev/null

    if [ $? -eq 0 ]; then
      echo "✅ Role assignment successful for $sub_id"
    else
      echo "❌ Failed to assign role for $sub_id"
    fi
  else
    echo "Invalid selection: $idx"
  fi
done

echo "All role assignments completed."
