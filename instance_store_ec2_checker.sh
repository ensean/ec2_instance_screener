#!/bin/sh
# query ec2 instance with instance store in every region
# instance store types
OUTPUT_FILE_PATH_ALL=/tmp/ec2_all.list
OUTPUT_FILE_PATH_INSTANCESTORE=/tmp/iec2_with_instance_store.list

# may need to be updated 
INSTANCE_STORE_PREFIX='i3\.|d2\.|h1\.|m5d\.|m5ad\.|m5dn\.|c5d\.|p3dn\.|g4dn\.|f1\.|r5d\.|r5ad\.|r5dn\.|x1\.|z1d\.'

# get current region from metadata
current_region=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep '\"region\"' | cut -d\" -f4`


# get region list 
region_list=`aws ec2 describe-regions \
    --no-all-regions \
    --query "Regions[].{Name:RegionName}" \
    --region $current_region \
    --output text`


echo 'Id    AZ  Instance_Type   Status' > $OUTPUT_FILE_PATH_ALL

# query instances in each region

for region in $region_list; do
    echo "Filtering instances in region ${region} ..."
    aws ec2 describe-instances \
        --query 'Reservations[].Instances[].[InstanceId, Placement.AvailabilityZone,InstanceType,State.Name]' \
        --region $region \
        --output text >> $OUTPUT_FILE_PATH_ALL
done

# filter out instances with instance store
cat $OUTPUT_FILE_PATH_ALL | grep -E $INSTANCE_STORE_PREFIX > $OUTPUT_FILE_PATH_INSTANCESTORE

cnt=`cat $OUTPUT_FILE_PATH_INSTANCESTORE | wc -l`

if [ $cnt -gt 0 ]; then
    echo "#####################################################################"
    echo "Instance with instance store is list below"
    echo "PS. You can also find the content in $OUTPUT_FILE_PATH_INSTANCESTORE"
    echo "#####################################################################"
    cat $OUTPUT_FILE_PATH_INSTANCESTORE
else
    echo "No instance with instance store is found in the current account"
fi
