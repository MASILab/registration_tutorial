#!/bin/bash

#set -e

# Usage:
# reg_preprocess.sh <bash_config_file> <in_image> <output_image> <temp_folder>

start=`date +%s`

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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
TEMP_NON_NULL_MASK=${temp_folder}/non_null_mask
TEMP_REGISTRATION_MASK=${temp_folder}/registration_mask
TEMP_RESET_ORIGIN=${temp_folder}/reset_origin

IM_LUNG_MASK=${TEMP_LUNG_MASK}/${file_name}
IM_Z_ROI_REGION=${TEMP_Z_ROI_REGION}/${file_name}
IM_Z_ROI_MASKED=${TEMP_Z_ROI_MASKED_IM}/${file_name}
IM_BODY_MASK=${TEMP_BODY_MASK}/${file_name}
IM_BODY_MASKED=${TEMP_BODY_MASKED}/${file_name}
IM_MASKED=${TEMP_MASKED}/${file_name}
IM_RESAMPLE=${TEMP_RESAMPLE}/${file_name}
IM_PAD=${TEMP_PAD}/${file_name}
IM_INTENS_CLIP=${TEMP_INTENS_CLIP}/${file_name}
IM_NON_NULL_MASK=${TEMP_NON_NULL_MASK}/${file_name}
IM_REGISTRATION_MASK=${TEMP_REGISTRATION_MASK}/${file_name}
IM_RESET_ORIGIN=${TEMP_RESET_ORIGIN}/${file_name}

mkdir -p ${TEMP_LUNG_MASK}
mkdir -p ${TEMP_Z_ROI_REGION}
mkdir -p ${TEMP_Z_ROI_MASKED_IM}
mkdir -p ${TEMP_BODY_MASK}
mkdir -p ${TEMP_BODY_MASKED}
mkdir -p ${TEMP_MASKED}
mkdir -p ${TEMP_RESAMPLE}
mkdir -p ${TEMP_PAD}
mkdir -p ${TEMP_INTENS_CLIP}
mkdir -p ${TEMP_NON_NULL_MASK}
mkdir -p ${TEMP_REGISTRATION_MASK}
mkdir -p ${TEMP_RESET_ORIGIN}

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
get_full_roi_mask ${IM_RESAMPLE} ${IM_LUNG_MASK} ${IM_Z_ROI_REGION} ${IM_Z_ROI_MASKED}

## Apply the mask
apply_mask ${IM_BODY_MASKED} ${IM_Z_ROI_REGION} ${IM_MASKED}

# Set coordinate origin to lung mask centroid
#set_coordinate_origin_with_lung_mask ${IM_MASKED} ${IM_LUNG_MASK} ${IM_RESET_ORIGIN}

# Generate non-null mask
#TEMP_FOLDER_NON_NULL_MASK=${temp_folder}/non_null_temp
#generate_padding_mask ${IM_RESET_ORIGIN} ${IM_NON_NULL_MASK} ${TEMP_FOLDER_NON_NULL_MASK}

# Padding image
#padding_with_reg_resample ${IM_RESET_ORIGIN} ${IM_PAD}
padding_c3d ${IM_MASKED} ${IM_PAD} -1000

# Intensity clip
#intensity_clip ${IM_PAD} ${IM_INTENS_CLIP}

# Generate mask for masked registration (z roi region with padding)
#${PYTHON_ENV} ${SRC_ROOT}/tools/padding.py --ori ${IM_Z_ROI_REGION} --out ${IM_REGISTRATION_MASK} --dim_x ${DIM_X} --dim_y ${DIM_Y} --dim_z ${DIM_Z}

echo "Preprocess complete, copy output data"
set -o xtrace
  cp ${IM_PAD} ${out_image}
set +o xtrace

#OUT_REG_MASK_PATH="${out_image/.nii.gz/_mask.nii.gz}"
#echo "Copy ${IM_REGISTRATION_MASK} to ${OUT_REG_MASK_PATH}"
#cp ${IM_REGISTRATION_MASK} ${OUT_REG_MASK_PATH}
#echo "Done"

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
#  rm -r ${IM_NON_NULL_MASK}
  rm -r ${IM_INTENS_CLIP}
  rm -r ${IM_RESET_ORIGIN}
  set +o xtrace
  echo "Done."
fi

end=`date +%s`

runtime=$((end-start))

echo "Complete! Total ${runtime} (s)"
