#!/bin/bash

# Usage:
# reg_preprocess.sh <bash_config_file> <in_image> <output_image> <temp_folder>

start=`date +%s`

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
IF_REMOVE_TEMP_FILES=true

bash_config_file=$(readlink -f $1)
in_image=$(readlink -f $2)
out_image=$(readlink -f $3)
temp_folder=$(readlink -f $4)
file_name=$(basename "$in_image")

echo "Configuration file is ${bash_config_file}"
echo "in_image ${in_image}"

source ${bash_config_file}
source ${BASH_DIR}/reg_preprocess_functions.sh

TEMP_LUNG_MASK=${temp_folder}/lung_mask
TEMP_FULL_ROI_REGION=${temp_folder}/roi_region_mask
TEMP_FULL_ROI_MASKED_IM=${temp_folder}/roi_masked_im
TEMP_RESAMPLE=${temp_folder}/resample
TEMP_PAD=${temp_folder}/padding

IM_LUNG_MASK=${TEMP_LUNG_MASK}/${file_name}
IM_FULL_ROI_REGION=${TEMP_FULL_ROI_REGION}/${file_name}
IM_FULL_ROI_MASKED=${TEMP_FULL_ROI_MASKED_IM}/${file_name}
IM_RESAMPLE=${TEMP_RESAMPLE}/${file_name}
IM_PAD=${TEMP_PAD}/${file_name}

mkdir -p ${TEMP_LUNG_MASK}
mkdir -p ${TEMP_FULL_ROI_REGION}
mkdir -p ${TEMP_FULL_ROI_MASKED_IM}
mkdir -p ${TEMP_RESAMPLE}
mkdir -p ${TEMP_PAD}

echo "Preprocessing pipeline:"
echo "Input image is ${in_image}"
echo "Output image is ${out_image}"
echo "Temp folder is ${temp_folder}"
echo ""

# Resampling
TEMP_FOLDER_RESAMPLE=${temp_folder}/resample_temp
resample_image ${in_image} ${IM_RESAMPLE} ${TEMP_FOLDER_RESAMPLE}

# Get full roi mask
get_full_roi_mask ${IM_RESAMPLE} ${IM_LUNG_MASK} ${IM_FULL_ROI_REGION} ${IM_FULL_ROI_MASKED}

# Padding image
TEMP_FOLDER_PADDING=${temp_folder}/padding_temp
padding_image ${IM_FULL_ROI_MASKED} ${IM_PAD} ${TEMP_FOLDER_PADDING}

echo "Copy ${IM_PAD} to ${out_image}."
cp ${IM_PAD} ${out_image}
echo "Done"

if [ "$IF_REMOVE_TEMP_FILES" = true ] ; then
  echo "Removing temp files..."
  set -o xtrace
  rm -f ${IM_LUNG_MASK}
  rm -f ${IM_FULL_ROI_REGION}
  rm -f ${IM_FULL_ROI_MASKED}
  rm -f ${IM_RESAMPLE}
  rm -r ${IM_PAD}
  set +o xtrace
  echo "Done."
fi

end=`date +%s`

runtime=$((end-start))

echo "Complete! Total ${runtime} (s)"
