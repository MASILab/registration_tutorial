#!/bin/bash

# Usage:
# interp_clipped_roi.sh <bash_config> <nii file name> <real mat name>

start=`date +%s`

bash_config_file=$(readlink -f $1)
file_name=$(readlink -f $2)
real_mat_name=$(readlink -f $3)

file_name=$(basename ${file_name})
real_mat_name=$(basename ${real_mat_name})

source ${bash_config_file}

TEMP_PAD=${TEMP_DIR}/padding
IM_PAD=${TEMP_PAD}/${file_name}

TRANS_MAT=${MAT_OUT}/${real_mat_name}
FIXED_IM=${FIXED_IMAGE_DIR}/fixed_image.nii.gz

INTERP_DIR=${OUT_ROOT}/interp
mkdir -p ${INTERP_DIR}

set -o xtrace
${REG_TOOL_ROOT}/reg_resample -inter 0 -pad -1000 -ref ${FIXED_IM} -flo ${IM_PAD} -trans ${TRANS_MAT} -res ${INTERP_DIR}/${file_name}
set +o xtrace

end=`date +%s`

runtime=$((end-start))

echo "Complete! Total ${runtime} (s)"