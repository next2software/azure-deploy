#!/bin/bash

# Check for Azure CLI
if ! command -v az &> /dev/null; then
  echo "Azure CLI (az) is required but not installed. Please install it first."
  exit 1
fi

# Set the Enterprise Application object ID (replace with your actual value or pass it as an argument)
ENTERPRISE_APP_OBJECT_ID="$1"
if [ -z "$ENTERPRISE_APP_OBJECT_ID" ]; then
  echo "Usage: $0 <enterprise_app_object_id>"
  exit 1
fi

# Fetch all subscriptions
echo "Fetching Azure subscriptions..."
mapfile -t subscriptions < <(az account list --query "[].{name:name, id:id}" -o tsv)

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
    echo "Assigning Reader role to Enterprise App for subscription: $sub_id"
    az role assignment create \
      --assignee-object-id "$ENTERPRISE_APP_OBJECT_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "Reader" \
      --scope "/subscriptions/$sub_id"
  else
    echo "Invalid selection: $idx"
  fi
done

echo "Done!"
