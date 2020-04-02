function interp_non_rigid_label_inverse_wrap_niftyreg_folder {
  LOCAL_FOLDER_TRANS=$1
  LOCAL_IMAGE_LABEL=$2
  LOCAL_FOLDER_TARGETS=$3
  LOCAL_FOLDER_OUT_ROOT=$4

  echo
  echo "##############################################"
  echo "Nonrigid inverse wrap label map using NIFTYREG"
  echo
  echo "Folder with transformation fields is ${LOCAL_FOLDER_TRANS}"
  echo "Label image ${LOCAL_IMAGE_LABEL}"
  echo "Output root folder ${LOCAL_FOLDER_OUT_ROOT}"
  echo

#  project_folder=${OUT_ROOT}/reg_folder2atlas_10vox
  trans_revert_folder=${LOCAL_FOLDER_OUT_ROOT}/trans_revert
  interp_label_folder=${LOCAL_FOLDER_OUT_ROOT}/interp_label
  mkdir -p ${trans_revert_folder}
  mkdir -p ${interp_label_folder}

  trans_folder=${LOCAL_FOLDER_TRANS}
  refs_folder=${LOCAL_FOLDER_TARGETS}
  label_img=${LOCAL_IMAGE_LABEL}

  echo
  echo "Transformation folder ${trans_folder}"
  echo "Label image ${label_img}"
  echo "Output revert trans folder ${trans_revert_folder}"
  echo "Output interp label folder ${interp_label_folder}"
  echo

  for file_path in "$trans_folder"/*
  do
    start=`date +%s`

    file_base_name="$(basename -- $file_path)"
    trans=${trans_folder}/${file_base_name}
    trans_revert=${trans_revert_folder}/${file_base_name}
    moving_img=${label_img}
    out_img=${interp_label_folder}/${file_base_name}
    ref_img=${refs_folder}/${file_base_name}

    set -o xtrace
    ${REG_TOOL_ROOT}/reg_transform \
      -omp ${NUM_PROCESSES} \
      -ref ${moving_img} \
      -invNrr ${trans} ${moving_img} ${trans_revert}
    set +o xtrace

    set -o xtrace
    ${REG_TOOL_ROOT}/reg_resample \
     -ref ${ref_img}\
     -flo ${moving_img}\
     -trans ${trans_revert}\
     -res ${out_img}\
     -inter 0\
     -pad 0\
     -omp ${NUM_PROCESSES}
    set +o xtrace

    end=`date +%s`

    runtime=$((end-start))

    echo "Complete! Total ${runtime} (s)"
  done

  echo ""
}

function interp_identity_resample_niftyreg_folder {
  LOCAL_IN_LABEL_FOLDER=$1
  LOCAL_IN_TARGET_FOLDER=$2
  LOCAL_OUT_RESAMPLED_LABEL_FOLDER=$3

  echo
  echo "###################################"
  echo "Rsample label files to target space"

  for file_path in "$LOCAL_IN_LABEL_FOLDER"/*
  do
    start=`date +%s`
    file_base_name="$(basename -- $file_path)"
    flo_img=${LOCAL_IN_LABEL_FOLDER}/${file_base_name}
    ref_img=${LOCAL_IN_TARGET_FOLDER}/${file_base_name}
    res_img=${LOCAL_OUT_RESAMPLED_LABEL_FOLDER}/${file_base_name}

    set -o xtrace
#    ${NIFYREG_ROOT}/reg_resample -trans ${TOOL_ROOT}/identity_affine.txt -ref ${ref_img} -flo ${flo_img} -res ${res_img} -pad 0
    ${NIFYREG_ROOT}/reg_resample -ref ${ref_img} -flo ${flo_img} -res ${res_img} -pad 0 -inter 0
    set +o xtrace

    end=`date +%s`
    runtime=$((end-start))
    echo "Complete! Total ${runtime} (s)"
  done
}