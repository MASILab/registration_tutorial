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
  TEMP_FOLDER=$3
  RESAMPLE_MID_IM=${TEMP_FOLDER}/resample_mid_im/${file_name}
  mkdir -p ${TEMP_FOLDER}/resample_mid_im

  set -o xtrace
  ${FREESURFER_ROOT}/mri_convert -vs $SPACING_X $SPACING_Y $SPACING_Z ${IN_IM} ${RESAMPLE_MID_IM}
  ${PYTHON_ENV} ${SRC_ROOT}/tools/fix_boundary_artifact_mri_convert.py --ori ${RESAMPLE_MID_IM} --out ${OUT_IM}
  set +o xtrace

  if [ "$IF_REMOVE_TEMP_FILES" = true ] ; then
    set -o xtrace
    rm ${RESAMPLE_MID_IM}
    set +o xtrace
  fi

  echo ""
}

function padding_image {
  echo "Padding image"

  IN_IM_INPUT=$1
  OUT_IM_INPUT=$2
  TEMP_FOLDER=$3

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
  echo "${FSL_ROOT}/fslmaths ${IN_IM} -add 1000 ${OUT_IM}"
  ${FSL_ROOT}/fslmaths ${IN_IM} -add 1000 ${OUT_IM}
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
  echo "${FSL_ROOT}/fslmaths ${IN_IM} -sub 1000 ${OUT_IM}"
  ${FSL_ROOT}/fslmaths ${IN_IM} -sub 1000 ${OUT_IM}
  echo "Output image to ${OUT_IM}"

  echo "Complete padding"
  echo "Copy ${OUT_IM} to ${OUT_IM_INPUT}"
  cp ${OUT_IM} ${OUT_IM_INPUT}
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

  echo "Clip intensity between 0 and 1000"
  set -o xtrace
  ${FSL_ROOT}/fslmaths ${IN_IM} -thr 0 -sub 1000 -uthr 0 -add 1000 ${OUT_IM}
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

