#!/bin/bash

# Usage:
# interp_roi_lung_mask.sh <bash_config> <ori nii file path> <affine matrix> <reference image> <out path> <temp folder>

start=`date +%s`

bash_config_file=$(readlink -f $1)
ori_file_path=$(readlink -f $2)
real_mat_name=$(readlink -f $3)
ref_file_path=$(readlink -f $4)
out_path=$(readlink -f $5)
temp_folder=$(readlink -f $6)

file_name=$(basename ${ori_file_path})
#real_mat_name=$(basename ${real_mat_name})

BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
IF_REMOVE_TEMP_FILES=false
source ${bash_config_file}
source ${BASH_DIR}/reg_preprocess_functions.sh

TRANS_MAT=${real_mat_name}
FIXED_IM=${ref_file_path}

function interpolate_image {
    INTERP_LOC=$1
    INTERP_IN_IM=$2

    echo "Interpolate ${INTERP_LOC} image : ${INTERP_IN_IM}"

    # Process ori Image
    # 1. resample
    # 2. padding
    # 3. interp preprocess result
    TEMP_RESAMPLE=${temp_folder}/interp/${INTERP_LOC}/resample
    TEMP_PAD=${temp_folder}/interp/${INTERP_LOC}/padding
    TEMP_INTERP_PRE=${temp_folder}/${INTERP_LOC}/preprocess_interp
    IM_RESAMPLE=${TEMP_RESAMPLE}/${file_name}
    IM_PAD=${TEMP_PAD}/${file_name}
    IM_INTERP_PRE=${TEMP_INTERP_PRE}/${file_name}

    mkdir -p ${TEMP_RESAMPLE}
    mkdir -p ${TEMP_PAD}
    mkdir -p ${TEMP_INTERP_PRE}

    # Preprocess for interpolation
    echo ""
    echo "Preprocess for interpolation: ${INTERP_IN_IM}"

    TEMP_FOLDER_RESAMPLE=${temp_folder}/interp/resample_temp/${INTERP_LOC}
    resample_image ${INTERP_IN_IM} ${IM_RESAMPLE} ${TEMP_FOLDER_RESAMPLE}
    TEMP_FOLDER_PADDING=${temp_folder}/interp/padding_temp/${INTERP_LOC}
    padding_image ${IM_RESAMPLE} ${IM_PAD} ${TEMP_FOLDER_PADDING}
    cp ${IM_PAD} ${IM_INTERP_PRE}

    INTERP_DIR=${out_path}/interp/${INTERP_LOC}
    mkdir -p ${INTERP_DIR}

    set -o xtrace
    ${REG_TOOL_ROOT}/reg_resample -inter 0 -pad -1000 -ref ${FIXED_IM} -flo ${IM_INTERP_PRE} -trans ${TRANS_MAT} -res ${INTERP_DIR}/${file_name}
#    cp ${IM_INTERP_PRE} ${INTERP_DIR}/${file_name}
    set +o xtrace

    if [ "$IF_REMOVE_TEMP_FILES" = true ] ; then
      set -o xtrace
      rm -f ${IM_RESAMPLE}
      rm -f ${IM_PAD}
      rm -f ${IM_INTERP_PRE}
      set +o xtrace
    fi
}

# Process ori Image
interpolate_image ori ${ori_file_path}

# Process mask image
TEMP_LUNG_MASK=${temp_folder}/lung_mask
IM_LUNG_MASK=${TEMP_LUNG_MASK}/${file_name}
interpolate_image mask ${IM_LUNG_MASK}

end=`date +%s`

runtime=$((end-start))

echo "Complete! Total ${runtime} (s)"