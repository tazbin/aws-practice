#!/bin/bash

SNAPSHOT_RANGE="[0:4]"

GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

# Fetch all volumes and their VolumeIds
echo "Fetching all volumes..."
volumes=$(aws ec2 describe-volumes --query 'Volumes[*].VolumeId' --output text)
volume_count=$(echo "$volumes" | wc -w | xargs)  # Trim any extra spaces
echo "-> Fetched $volume_count volumes"

# Fetch snapshots based on the variable range with additional details
echo "Fetching all snapshots..."
snapshots=$(aws ec2 describe-snapshots --owner-ids self --query "Snapshots[?StartTime<'2020-01-01T00:00:00Z']$SNAPSHOT_RANGE.[SnapshotId,VolumeId,StartTime]" --output text)
snapshot_count=$(echo "$snapshots" | wc -l | xargs)  # Trim any extra spaces
echo "-> Fetched snapshots in range $SNAPSHOT_RANGE, Total snapshots $snapshot_count"

echo "--------------------------------------------------"
echo "Snapshot Details (Active and Orphan)"
echo "--------------------------------------------------"

# Prepare the header for the table
printf "%-25s %-30s %-35s %-15s\n" "SnapshotId" "VolumeId" "Creation Date" "Status"
echo "----------------------------------------------------------------------------------------------------------"

# Loop through all snapshots and check volume status
while IFS= read -r snapshot; do
  snapshot_id=$(echo $snapshot | awk '{print $1}')
  volume_id=$(echo $snapshot | awk '{print $2}')
  snapshot_date=$(echo $snapshot | awk '{print $3}')

  # Check if the volume ID for the snapshot exists in the active volumes list
  if echo "$volumes" | grep -q "$volume_id"; then
    status="${GREEN}ACTIVE${RESET}"
  else
    status="${RED}ORPHAN${RESET}"
  fi

  # Print the snapshot details in tabular format
  printf "%-25s %-30s %-35s %-15s\n" "$snapshot_id" "$volume_id" "$snapshot_date" "$status"
done <<< "$snapshots"

echo "----------------------------------------------------------------------------------------------------------"
