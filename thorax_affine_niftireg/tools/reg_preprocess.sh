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
TEMP_Z_ROI_REGION=${temp_folder}/roi_region_mask
TEMP_Z_ROI_MASKED_IM=${temp_folder}/roi_masked_im
TEMP_BODY_MASK=${temp_folder}/body_mask
TEMP_BODY_MASKED=${temp_folder}/body_masked
TEMP_MASKED=${temp_folder}/masked
TEMP_RESAMPLE=${temp_folder}/resample
TEMP_PAD=${temp_folder}/padding
TEMP_INTENS_CLIP=${temp_folder}/intens_clip

IM_LUNG_MASK=${TEMP_LUNG_MASK}/${file_name}
IM_Z_ROI_REGION=${TEMP_Z_ROI_REGION}/${file_name}
IM_Z_ROI_MASKED=${TEMP_Z_ROI_MASKED_IM}/${file_name}
IM_BODY_MASK=${TEMP_BODY_MASK}/${file_name}
IM_BODY_MASKED=${TEMP_BODY_MASKED}/${file_name}
IM_MASKED=${TEMP_MASKED}/${file_name}
IM_RESAMPLE=${TEMP_RESAMPLE}/${file_name}
IM_PAD=${TEMP_PAD}/${file_name}
IM_INTENS_CLIP=${TEMP_INTENS_CLIP}/${file_name}

mkdir -p ${TEMP_LUNG_MASK}
mkdir -p ${TEMP_Z_ROI_REGION}
mkdir -p ${TEMP_Z_ROI_MASKED_IM}
mkdir -p ${TEMP_BODY_MASK}
mkdir -p ${TEMP_BODY_MASKED}
mkdir -p ${TEMP_MASKED}
mkdir -p ${TEMP_RESAMPLE}
mkdir -p ${TEMP_PAD}
mkdir -p ${TEMP_INTENS_CLIP}

echo "Preprocessing pipeline:"
echo "Input image is ${in_image}"
echo "Output image is ${out_image}"
echo "Temp folder is ${temp_folder}"
echo ""

# Resampling
TEMP_FOLDER_RESAMPLE=${temp_folder}/resample_temp
resample_image ${in_image} ${IM_RESAMPLE} ${TEMP_FOLDER_RESAMPLE}

# Get body mask
get_body_mask ${IM_RESAMPLE} ${IM_BODY_MASKED} ${IM_BODY_MASK}

# Get z roi mask
get_z_roi_mask ${IM_RESAMPLE} ${IM_LUNG_MASK} ${IM_Z_ROI_REGION} ${IM_Z_ROI_MASKED}

# Apply the mask
apply_mask ${IM_BODY_MASKED} ${IM_Z_ROI_REGION} ${IM_MASKED}

# Padding image
TEMP_FOLDER_PADDING=${temp_folder}/padding_temp
padding_image ${IM_MASKED} ${IM_PAD} ${TEMP_FOLDER_PADDING} -1000

# Intensity clip
intensity_clip ${IM_PAD} ${IM_INTENS_CLIP}


echo "Copy ${IM_INTENS_CLIP} to ${out_image}."
cp ${IM_INTENS_CLIP} ${out_image}
echo "Done"

if [ "$IF_REMOVE_TEMP_FILES" = true ] ; then
  echo "Removing temp files..."
  set -o xtrace
#  rm -f ${IM_LUNG_MASK}
  rm -f ${IM_Z_ROI_REGION}
  rm -f ${IM_Z_ROI_MASKED}
  rm -f ${IM_BODY_MASK}
  rm -f ${IM_BODY_MASKED}
  rm -f ${IM_MASKED}
  rm -f ${IM_RESAMPLE}
  rm -r ${IM_PAD}
  rm -r ${IM_INTENS_CLIP}
  set +o xtrace
  echo "Done."
fi

end=`date +%s`

runtime=$((end-start))

echo "Complete! Total ${runtime} (s)"
