#!/bin/bash

# Set the snapshot range
SNAPSHOT_RANGE="[0:2]"

# Fetch all volumes and their VolumeIds
echo "Fetching all volumes..."
volumes=$(aws ec2 describe-volumes --query 'Volumes[*].VolumeId' --output text)
volume_count=$(echo "$volumes" | wc -w)
echo "-> Fetched $volume_count volumes"

# Fetch snapshots based on the variable range
echo "Fetching all snapshots..."
snapshots=$(aws ec2 describe-snapshots --owner-ids self --query "Snapshots$SNAPSHOT_RANGE.[SnapshotId,VolumeId]" --output text)
snapshot_count=$(echo "$snapshots" | wc -l)
echo "-> Fetched snapshots in range $SNAPSHOT_RANGE, Total snapshots $snapshot_count numbers"

echo "--------------------------------------------------"
echo "Snapshots and their associated Volumes"
echo "--------------------------------------------------"

# Loop through all snapshots and check if the volume is still active
while IFS= read -r snapshot; do
  snapshot_id=$(echo $snapshot | awk '{print $1}')
  volume_id=$(echo $snapshot | awk '{print $2}')

  # Check if the volume ID for the snapshot exists in the active volumes list
  if echo "$volumes" | grep -q "$volume_id"; then
    echo -e "SnapshotId: $snapshot_id, VolumeId: $volume_id (Active)"
  else
    echo -e "SnapshotId: $snapshot_id, VolumeId: $volume_id (Orphan - Volume Deleted)"
  fi
done <<< "$snapshots"

echo "--------------------------------------------------"
