# Tutorial for Body/Thorax Registration
This repository includes the step-by-step instructions for body/thorax registration pipelines used in MASI lab. Both affine and non-rigid registration will be discussed. Examples are provided to validate each steps of the pipeline.

Please contact Kaiwen (kaiwen.xu@vanderbilt.edu) for any issues.

## Registration pipeline

### Affine (Thorax LDCT, SPORE, 1/3/2020)

**Preprocessing**:

Apply the following command to both moving and fixed images.

    > ./tools/reg_preprocess.sh ./config/thorax_affine_example_20200103.sh PATH_IN_IMAGE PATH_OUT_IMAGE TEMPORARY_FOLDER

Preprocessing sub-steps:

Body mask based on connected component analysis
    
    > ${PYTHON_ENV} ${SRC_ROOT}/tools/thorax_body_mask.py --in_image ${IN_IM} --out_mask ${MASK_IM} --out_image ${OUT_IM}

Lung segmentation based ROI mask 

    > ${PYTHON_ENV} ${SRC_ROOT}/tools/seg_roi.py --method lung_seg_roi_z_mask --ori ${IN_IM} --mask ${LUNG_MASK_IM} --roi_region ${ROI_REGION_IM} --roi ${ROI_MASKED_IM} --fsl_root ${FSL_ROOT}

Resampling to uniform resolution

    > ${FREESURFER_ROOT}/mri_convert -vs $SPACING_X $SPACING_Y $SPACING_Z ${IN_IM} ${RESAMPLE_MID_IM}        
    > {PYTHON_ENV} ${SRC_ROOT}/tools/fix_boundary_artifact_mri_convert.py --ori ${RESAMPLE_MID_IM} --out ${OUT_IM}

Padding to uniform dimensions

    > ${FSL_ROOT}/fslmaths ${IN_IM} -add 1000 ${OUT_IM}
    > ${FSL_ROOT}/fslmaths ${IN_IM} -thr 0 ${OUT_IM}
    > ${PYTHON_ENV} ${SRC_ROOT}/tools/padding.py --ori ${IN_IM} --out ${OUT_IM} --dim_x ${DIM_X} --dim_y ${DIM_Y} --dim_z ${DIM_Z}
    > ${FSL_ROOT}/fslmaths ${IN_IM} -sub 1000 ${OUT_IM}

(Optional) Intensity clipping [0, 1000] for an approximated bone mask.

    > ${FSL_ROOT}/fslmaths ${IN_IM} -thr 0 -sub 1000 -uthr 0 -add 1000 ${OUT_IM}


**Registration**

Co-registration between preprocessed moving and fixed images.

    > ${REG_TOOL_ROOT}/reg_aladin -ln 5 -ref FIXED_IMAGE -flo MOVING_IMAGE -res OUTPUT_IMAGE -aff OUTPUT_AFFINE_MATRIX

**Interpolation**

Propagate the transformation (affine matrix) to original moving image using nearest neighbor interpolation under same coordinate space (i.e. with same resolution and boundary padding) 

    > ${REG_TOOL_ROOT}/reg_resample -inter 0 -pad -1000 -ref FIXED_IM -flo IN_IMAGE -trans TRANS_MATRIX -res OUT_IMAGE

- FIXED_IM = to provide the coordinate system of the resampled image.
- IN_IMAGE = input image to resample, should be resampled and padded into the same space as the images used in co-registration
- OUT_IMAGE = resampled image

### Non-rigid (thorax LDCT, SPORE, 1/3/2020)



## Registration tools
Please refer to the review paper [1]. The full registration commands and configuration options can be found in the [supplementary materials](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4972188/bin/NIHMS805331-supplement-tbme-xu-2574816-mm_zip.zip) of [1].

# References
[1] Xu, Z., Lee, C. P., Heinrich, M. P., Modat, M., Rueckert, D., Ourselin, S., … Landman, B. A. (2016). Evaluation of Six Registration Methods for the Human Abdomen on Clinically Acquired CT. IEEE Transactions on Biomedical Engineering, 63(8), 1563–1572. https://doi.org/10.1109/TBME.2016.2574816