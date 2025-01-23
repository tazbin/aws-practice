#!/bin/bash

# Set the snapshot range
SNAPSHOT_RANGE="[0:4]"

# Fetch all volumes and their VolumeIds
echo "Fetching all volumes..."
volumes=$(aws ec2 describe-volumes --query 'Volumes[*].VolumeId' --output text)
volume_count=$(echo "$volumes" | wc -w| xargs)
echo "-> Total volumes: $volume_count"

# Fetch snapshots based on the variable range with additional details
echo "Fetching all snapshots in range $SNAPSHOT_RANGE..."
snapshots=$(aws ec2 describe-snapshots --owner-ids self --query "Snapshots$SNAPSHOT_RANGE.[SnapshotId,VolumeId,StartTime]" --output text)
snapshot_count=$(echo "$snapshots" | wc -l | xargs)
echo "-> Total snapshots: $snapshot_count"

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
    status="ACTIVE"
  else
    status="ORPHAN"
  fi

  # Print the snapshot details in tabular format
  printf "%-25s %-30s %-35s %-15s\n" "$snapshot_id" "$volume_id" "$snapshot_date" "$status"
done <<< "$snapshots"

echo "----------------------------------------------------------------------------------------------------------"
