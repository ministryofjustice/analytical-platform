#!/bin/bash

# Define the source and target directories
source_dir="data-platform"
target_dir="application-migration"

echo "Source directory: $source_dir"
echo "Target directory: $target_dir"

# Initialize and plan
(cd $source_dir && terraform init && terraform plan -no-color -out plan.out)
echo "Generated the plan in $source_dir/plan.out"

# Convert the plan to JSON
(cd $source_dir && terraform show -json plan.out > plan.json)
echo "Converted the plan to JSON: $source_dir/plan.json"

# Parse the JSON plan
json=`cat $source_dir/plan.json`

echo "Plan JSON parsed from $source_dir/plan.json"

# Extract resources being destroyed
destroyed_resources=$(echo "$json" | jq -r '.resource_changes[] | select(.change.actions[] | contains("delete")) | .address')

echo "Resources being destroyed:"
echo "$destroyed_resources"

# Pull the states from both backends
(cd $source_dir && terraform init && terraform state pull > source.tfstate)
echo "Pulled state from $source_dir to $source_dir/source.tfstate"

# Backup the source state
cp $source_dir/source.tfstate $source_dir/source.tfstate.backup
echo "Backed up the source state to $source_dir/source.tfstate.backup"

(cd $target_dir && terraform init && terraform state pull > target.tfstate)
echo "Pulled state from $target_dir to $target_dir/target.tfstate"

# Create a file for the mv commands
mv_commands_file="mv_commands.sh"
echo "#!/bin/bash" > $mv_commands_file

# Iterate over each line of destroyed_resources
while IFS= read -r resource
do
    # Generate terraform state mv command locally and write to the file
    echo "Preparing to move resource: $resource"
    echo "terraform state mv -state=$source_dir/source.tfstate -state-out=$target_dir/target.tfstate '$resource' '$resource'" >> $mv_commands_file
done <<< "$destroyed_resources"

# Make the file executable
chmod +x $mv_commands_file

echo "Generated mv commands in $mv_commands_file"

# Push the states back to the respective backends
# (cd $source_dir && terraform init && terraform state push source.tfstate)
# echo "Pushed state to $source_dir"
# (cd $target_dir && terraform init && terraform state push target.tfstate)
# echo "Pushed state to $target_dir"
