#!/bin/bash

PYEHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python
BASH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASH_CONFIG_PATH=${BASH_DIR}/run_config.sh

# Generate the config file
${PYEHON_ENV} ${BASH_DIR}/tools/create_config_file.py --config-path ${BASH_CONFIG_PATH} --num-processes 16 --proj-root ${BASH_DIR}/..

source ${BASH_CONFIG_PATH}
source ${SRC_ROOT}/tools/reg_preprocess_functions.sh
source ${SRC_ROOT}/tools/reg_registration_functions.sh
source ${SRC_ROOT}/tools/reg_interpolation_functions.sh

start=`date +%s`

# Preprocess
PREPROCESS_FOLDER=${OUT_ROOT}/preprocess
mkdir -p ${PREPROCESS_FOLDER}
${SRC_ROOT}/tools/run_preprocess_folder.sh ${DEMO_SCANS} ${PREPROCESS_FOLDER} ${BASH_CONFIG_PATH}

# Registration to atlas
REG_RESULT_ROOT=${OUT_ROOT}/reg
mkdir -p ${REG_RESULT_ROOT}
non_rigid_niftyreg_folder ${PREPROCESS_FOLDER} ${IMAGE_ATLAS} ${REG_RESULT_ROOT}

# Revert transformation fields then apply to label
FOLDER_TRANS=${REG_RESULT_ROOT}/trans
INTERP_RESULT_ROOT=${OUT_ROOT}/interp
mkdir -p ${INTERP_RESULT_ROOT}
interp_non_rigid_label_inverse_wrap_niftyreg_folder ${FOLDER_TRANS} ${IMAGE_LABEL} ${PREPROCESS_FOLDER} ${INTERP_RESULT_ROOT}

# Resample labels to target image space.
LABEL_FOLDER=${INTERP_RESULT_ROOT}/interp_label
TARGE_FOLDER=${DEMO_SCANS}
RESAMPLE_LABEL_FOLDER=${OUT_ROOT}/out/label_data
mkdir -p ${RESAMPLE_LABEL_FOLDER}
interp_identity_resample_niftyreg_folder ${LABEL_FOLDER} ${TARGE_FOLDER} ${RESAMPLE_LABEL_FOLDER}

end=`date +%s`
runtime=$((end-start))
echo "Complete! Total ${runtime} (s)"