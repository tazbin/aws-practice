#!/bin/bash

SNAPSHOT_RANGE="[0:40]"
DATE_FILTER="2026-01-25T00:00:00Z"

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

# Get snapshots by range
snapshots=$(aws ec2 describe-snapshots --owner-ids self \
    --query "Snapshots$SNAPSHOT_RANGE.[SnapshotId,VolumeId,StartTime,VolumeSize]" \
    --output text)

snapshot_count=$(echo "$snapshots" | wc -l | xargs)  # Trim any extra spaces
echo "-> Fetched snapshots in range $SNAPSHOT_RANGE, Total snapshots: $snapshot_count"

echo "----------------------------------------------------------------------------------------------------------------------"
echo "Snapshot Details (Active and Orphan)"
echo "----------------------------------------------------------------------------------------------------------------------"

# Prepare the header for the table
printf "%-25s %-30s %-35s %-15s %-15s\n" "SnapshotId" "VolumeId" "Creation Date" "Status" "Size (GB)"
echo "----------------------------------------------------------------------------------------------------------------------"

# Initialize total snapshot size
total_size=0

# Loop through all snapshots and check volume status
while IFS= read -r snapshot; do
  snapshot_id=$(echo "$snapshot" | awk '{print $1}')
  volume_id=$(echo "$snapshot" | awk '{print $2}')
  snapshot_date=$(echo "$snapshot" | awk '{print $3}')
  snapshot_size=$(echo "$snapshot" | awk '{print $4}')

  # Ensure snapshot_size is a valid number
  if [[ ! "$snapshot_size" =~ ^[0-9]+$ ]]; then
    snapshot_size=0
  fi

  # Convert MB to GB if size is abnormally large
  if [[ $snapshot_size -gt 1024 ]]; then
    snapshot_size_gb=$(awk "BEGIN { printf \"%.2f\", $snapshot_size / 1024 }")
  else
    snapshot_size_gb=$snapshot_size
  fi

  # Check if the volume ID for the snapshot exists in the active volumes list
  if echo "$volumes" | grep -q "$volume_id"; then
    status="${GREEN}ACTIVE${RESET}"
  else
    status="${RED}ORPHAN${RESET}"
  fi

  # Add snapshot size to total
  total_size=$(awk "BEGIN { printf \"%.2f\", $total_size + $snapshot_size_gb }")

  # Print the snapshot details in tabular format
  printf "%-25s %-30s %-35s %-26s %-15s\n" "$snapshot_id" "$volume_id" "$snapshot_date" "$status" "$snapshot_size_gb"

done <<< "$snapshots"

echo "----------------------------------------------------------------------------------------------------------------------"
printf "Total Snapshot Size: %.2f GB\n" "$total_size"
echo "----------------------------------------------------------------------------------------------------------------------"