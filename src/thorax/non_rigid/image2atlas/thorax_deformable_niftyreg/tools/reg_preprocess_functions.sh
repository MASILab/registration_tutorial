function get_body_mask {
  IN_IM=$1
  OUT_IM=$2
  MASK_IM=$3

  echo "Body mask (to remove suroundings like CT table)"
  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/thorax_body_mask.py --in_image ${IN_IM} --out_mask ${MASK_IM} --out_image ${OUT_IM}
  set +o xtrace

  echo ""
}

function resample_image {
  echo "Resample image"
  IN_IM=$1
  OUT_IM=$2

  set -o xtrace
  ${C3D_ROOT}/c3d ${IN_IM} -resample-mm ${SPACING_X}x${SPACING_Y}x${SPACING_Z}mm -o ${OUT_IM}
  set +o xtrace

  echo ""
}

function resample_image_with_boundary_crop {
  echo "Resample image"
  IN_IM=$1
  OUT_IM=$2

  OUT_DIR=$(dirname "${OUT_IM}")
  FILE_NAME=$(basename "${OUT_IM}")
  OUT_DIR_TEMP=${OUT_DIR}/temp
  mkdir -p ${OUT_DIR_TEMP}
  TEMP_IM=${OUT_DIR_TEMP}/${FILE_NAME}

  set -o xtrace
  ${C3D_ROOT}/c3d ${IN_IM} -resample-mm ${SPACING_X}x${SPACING_Y}x${SPACING_Z}mm -o ${TEMP_IM}
  ${C3D_ROOT}/c3d ${TEMP_IM} -region 1% 98% -o ${OUT_IM}
  set +o xtrace

  if [ "$IF_REMOVE_TEMP_FILES" = true ] ; then
    set -o xtrace
    rm -f ${TEMP_IM}
    set +o xtrace
  fi

  echo ""
}

function padding_c3d {
  echo "Padding image using c3d"

  IN_IM_INPUT=$1
  OUT_IM_INPUT=$2
#  ENV_INTENSITY=-1000
  ENV_INTENSITY="$3"

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/padding.py \
    --ori ${IN_IM_INPUT} \
    --out ${OUT_IM_INPUT} \
    --dim_x ${DIM_X} --dim_y ${DIM_Y} --dim_z ${DIM_Z} \
    --pad_val ${ENV_INTENSITY} \
    --c3d_root ${C3D_ROOT}
  set +o xtrace
}

function padding_with_reg_resample {
  echo "Padding image"

  IN_IM_INPUT=$1
  OUT_IM_INPUT=$2

  ENV_INTENSITY=-1000

  set -o xtrace
#  ${NIFYREG_ROOT}/reg_resample -ref ${STD_SPACE_NII} -flo ${IN_IM_INPUT} -res ${OUT_IM_INPUT} -pad ${ENV_INTENSITY} -trans ${IDENTITY_MAT}
  ${NIFYREG_ROOT}/reg_resample -ref ${STD_SPACE_NII} -flo ${IN_IM_INPUT} -res ${OUT_IM_INPUT} -pad ${ENV_INTENSITY}

  set +o xtrace

  echo ""
}

function padding_image {
  echo "Padding image"

  IN_IM_INPUT=$1
  OUT_IM_INPUT=$2
  TEMP_FOLDER=$3
  PAD_VAL=$4 # -1000 for air

  ENV_INTENSITY=-5000

  TEMP_ADD1K=${TEMP_FOLDER}/add_1k
  TEMP_THR0=${TEMP_FOLDER}/thr_0
  TEMP_PAD=${TEMP_FOLDER}/padding
  TEMP_SUB1K=${TEMP_FOLDER}/sub_1k

  mkdir -p ${TEMP_ADD1K}
  mkdir -p ${TEMP_THR0}
  mkdir -p ${TEMP_PAD}
  mkdir -p ${TEMP_SUB1K}

  IN_IM=${IN_IM_INPUT}
  OUT_IM=${TEMP_ADD1K}/${file_name}
  echo "add 1000..."
  echo "${FSL_ROOT}/fslmaths ${IN_IM} -add $((-${ENV_INTENSITY})) ${OUT_IM}"
  ${FSL_ROOT}/fslmaths ${IN_IM} -add $((-${ENV_INTENSITY})) ${OUT_IM}
  echo "Output image to ${OUT_IM}"

  IN_IM=${OUT_IM}
  OUT_IM=${TEMP_THR0}/${file_name}
  echo "thr 0..."
  echo "${FSL_ROOT}/fslmaths ${IN_IM} -thr 0 ${OUT_IM}"
  ${FSL_ROOT}/fslmaths ${IN_IM} -thr 0 ${OUT_IM}
  echo "Output image to ${OUT_IM}"

  IN_IM=${OUT_IM}
  OUT_IM=${TEMP_PAD}/${file_name}
  echo "padding..."
  echo "${PYTHON_ENV} ${SRC_ROOT}/tools/padding.py --ori ${IN_IM} --out ${OUT_IM} --dim_x ${DIM_X} --dim_y ${DIM_Y} --dim_z ${DIM_Z}"
  ${PYTHON_ENV} ${SRC_ROOT}/tools/padding.py --ori ${IN_IM} --out ${OUT_IM} --dim_x ${DIM_X} --dim_y ${DIM_Y} --dim_z ${DIM_Z}
  echo "Output image to ${OUT_IM}"

  IN_IM=${OUT_IM}
  OUT_IM=${TEMP_SUB1K}/${file_name}
  echo "sub 1000..."
  echo "${FSL_ROOT}/fslmaths ${IN_IM} -sub $((-${ENV_INTENSITY})) ${OUT_IM}"
  ${FSL_ROOT}/fslmaths ${IN_IM} -sub $((-${ENV_INTENSITY})) ${OUT_IM}
  echo "Output image to ${OUT_IM}"

  echo "Complete padding"
  echo "Copy ${OUT_IM} to ${OUT_IM_INPUT}"
#  cp ${OUT_IM} ${OUT_IM_INPUT}
  ${C3D_ROOT}/c3d ${OUT_IM} -replace ${ENV_INTENSITY} ${PAD_VAL} -o ${OUT_IM_INPUT}
  echo "Done."

  if [ "$IF_REMOVE_TEMP_FILES" = true ] ; then
    set -o xtrace
    rm -f ${TEMP_ADD1K}/${file_name}
    rm -f ${TEMP_THR0}/${file_name}
    rm -f ${TEMP_PAD}/${file_name}
    rm -f ${TEMP_SUB1K}/${file_name}
    set +o xtrace
  fi

  echo ""
}

function intensity_clip {
  IN_IM=$1
  OUT_IM=$2

  IN_IM_NON_NAN=${OUT_IM}_non_nan.nii.gz

  echo "Clip intensity between 0 and 1000"
  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/replace_nan.py --val -1000 --in_image ${IN_IM} --out_image ${IN_IM_NON_NAN}
  ${FSL_ROOT}/fslmaths ${IN_IM_NON_NAN} -thr 0 -sub 1000 -uthr 0 -add 1000 ${OUT_IM}
  rm -rf ${IN_IM_NON_NAN}
  set +o xtrace
  echo "Output image to ${OUT_IM}"
  echo ""
}

function get_z_roi_mask {
  IN_IM=$1
  LUNG_MASK_IM=$2
  ROI_REGION_IM=$3
  ROI_MASKED_IM=$4

  echo "Get Lung mask and ROI masked (not clipping) image"
  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/seg_roi.py --method lung_seg_roi_z_mask --ori ${IN_IM} --mask ${LUNG_MASK_IM} --roi_region ${ROI_REGION_IM} --roi ${ROI_MASKED_IM} --fsl_root ${FSL_ROOT}
  set +o xtrace
  echo ""
}

function get_full_roi_mask {
  IN_IM=$1
  LUNG_MASK_IM=$2
  ROI_REGION_IM=$3
  ROI_MASKED_IM=$4

  echo "Get lung mask and full ROI masked image"
  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/seg_roi.py --method lung_seg_roi_clip_full --ori ${IN_IM} --mask ${LUNG_MASK_IM} --roi_region ${ROI_REGION_IM} --roi ${ROI_MASKED_IM} --c3d_root ${C3D_ROOT}
  set +o xtrace

}

function apply_mask {
  IN_IM=$1
  MASK_IM=$2
  OUT_IM=$3

  echo "Apply mask to image."
  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/apply_mask.py --ori ${IN_IM} --mask ${MASK_IM} --out ${OUT_IM}
  set +o xtrace
  echo ""
}

function generate_padding_mask {
  IN_IM=$1 # input image to pad.
  OUT_MASK=$2 # output non-null region mask.
  TEMP_FOLDER=$3

  echo "Generate non-null/null region mask for padding"

  TEMP_UNIT_MAP=${TEMP_FOLDER}/unit_map
  TEMP_PAD_MAP=${TEMP_FOLDER}/pad_map

  mkdir -p ${TEMP_UNIT_MAP}
  mkdir -p ${TEMP_PAD_MAP}

  set -o xtrace
  ${FSL_ROOT}/fslmaths ${IN_IM} -mul 0 -add 1 ${TEMP_UNIT_MAP}/${file_name}
  ${PYTHON_ENV} ${SRC_ROOT}/tools/padding.py --ori ${TEMP_UNIT_MAP}/${file_name} --out ${TEMP_PAD_MAP}/${file_name} --dim_x ${DIM_X} --dim_y ${DIM_Y} --dim_z ${DIM_Z}
  ${FSL_ROOT}/fslmaths ${TEMP_PAD_MAP}/${file_name} -ero ${OUT_MASK}
  set +o xtrace

  if [ "$IF_REMOVE_TEMP_FILES" = true ] ; then
    set -o xtrace
    rm -f ${TEMP_UNIT_MAP}/${file_name}
    rm -f ${TEMP_PAD_MAP}/${file_name}
    set +o xtrace
  fi

  echo ""
}

function generate_unit_image {
  IN_IM=$1 # Reference image
  OUT_UNIT_IM=$2

  echo "Generate unit image."

  set -o xtrace
  ${FSL_ROOT}/fslmaths ${IN_IM} -mul 0 -add 1 ${OUT_UNIT_IM}
  set +o xtrace

  echo ""
}

function set_coordinate_origin_with_lung_mask {
  IN_IM=$1
  IN_MASK=$2
  OUT=$3

  echo "Set coordinate origin to lung mask centroid"

  set -o xtrace
  ${PYTHON_ENV} ${SRC_ROOT}/tools/set_image_origin_to_lung_mask_center.py --in_image ${IN_IM} --in_mask ${IN_MASK} --out ${OUT} --c3d_root ${C3D_ROOT}
  set +o xtrace
 
  echo ""
}

function convert_dicom_nii_folder {
  LOCAL_FOLDER_IN_DCM=$1
  LOCAL_FOLDER_OUT_NII=$2

  echo "Convert dicom to nii"
  echo "Input dcm folder: ${LOCAL_FOLDER_IN_DCM}"
  echo "Output nii folder: ${LOCAL_FOLDER_OUT_NII}"
  mkdir -p ${LOCAL_FOLDER_OUT_NII}

  LOCAL_DCOM2NIIX_TEMP_FOLDER=${LOCAL_FOLDER_OUT_NII}/temp
  mkdir -p ${LOCAL_DCOM2NIIX_TEMP_FOLDER}

  convert_dicom_nii () {
    local file_path=$1

    start=`date +%s`

    file_base_name="$(basename -- $file_path)"
    in_dcm=${LOCAL_FOLDER_IN_DCM}/${file_base_name}

    local_temp_direct_output_folder=${LOCAL_DCOM2NIIX_TEMP_FOLDER}/${file_base_name}
    mkdir -p ${local_temp_direct_output_folder}

    set -o xtrace
    ${DCM_2_NII_TOOL} -m y -z y -o ${local_temp_direct_output_folder} ${in_dcm}
    set +o xtrace

    for output_nii_file_path in "${local_temp_direct_output_folder}"/*.nii.gz
    do
      set -o xtrace
      cp ${output_nii_file_path} ${LOCAL_FOLDER_OUT_NII}/${file_base_name}.nii.gz
      set +x xtrace
    done

    end=`date +%s`
    runtime=$((end-start))
    echo "Complete! Total ${runtime} (s)"
  }

  for file_path in "${LOCAL_FOLDER_IN_DCM}"/*
  do
#    convert_dicom_nii ${file_path} &
    convert_dicom_nii ${file_path}
  done

#  wait
  set -o xtrace
  rm -rf ${LOCAL_DCOM2NIIX_TEMP_FOLDER}
  set +o xtrace
}
