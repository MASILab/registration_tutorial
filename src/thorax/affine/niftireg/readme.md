## Registration pipeline, Affine (Thorax LDCT, SPORE, 1/6/2020)

A working pipeline for Thorax CT affine registration. NIFTIREG is used as registration engine. Please contact Kaiwen (kaiwen.xu@vanderbilt.edu) for any issues.

### Methods

**Preprocessing**:

The following script is a collection of preprocessing substeps. Both moving and fixed images should be preprocessed before registration.

    # ${CONFIG_FILE} - configuration file (e.g. ./config/thorax_affine_example_20200103.sh)
    # ${IN_IMAGE} - input image to preprocess
    # ${OUT_IMAGE} - output image
    # ${TEMP_FOLDER} - location for files of each preprocess substep  
    ./tools/reg_preprocess.sh ${CONFIG_FILE} ${IN_IMAGE} ${OUT_IMAGE} ${TEMP_FOLDER}

Preprocessing sub-steps:

Resampling to same resolution

    ${C3D_ROOT}/c3d ${IN_IM} -resample-mm ${SPACING_X}x${SPACING_Y}x${SPACING_Z}mm -o ${OUT_IM}        

Body mask based on connected component analysis
    
    ${PYTHON_ENV} ${SRC_ROOT}/tools/thorax_body_mask.py --in_image ${IN_IM} --out_mask ${MASK_IM} --out_image ${OUT_IM}

| ![resampled_image](./figs/moving_1_resampled_1.png) |  ![body_mask](./figs/moving_1_body_mask_1_1.png) | ![body_masked_image](./figs/moving_1_bodymasked_1.png) |
|:----------:|:-------------:|:------:|
| Resampled image   |      Body mask      | Apply body mask |

Generate lung segmentation based ROI mask, then clip on z direction. Registration tend to be more robust with this z roi clipping.

    ${PYTHON_ENV} ${SRC_ROOT}/tools/seg_roi.py --method lung_seg_roi_z_mask --ori ${IN_IM} --mask ${LUNG_MASK_IM} --roi_region ${ROI_REGION_IM} --roi ${ROI_MASKED_IM} --fsl_root ${FSL_ROOT}

| ![body_masked_image_A](./figs/moving_1_bodymasked_C.png) |  ![z_roi_mask](./figs/moving_1_z_roi_mask_C.png) | ![z_roi_masked_image](./figs/moving_1_z_roi_masked_C.png) |
|:----------:|:-------------:|:------:|
|    |      z roi mask      | z-clipped |

Padding to same dimensions

    ${FSL_ROOT}/fslmaths ${IN_IM} -add 1000 ${OUT_IM}
    ${FSL_ROOT}/fslmaths ${IN_IM} -thr 0 ${OUT_IM}
    ${PYTHON_ENV} ${SRC_ROOT}/tools/padding.py --ori ${IN_IM} --out ${OUT_IM} --dim_x ${DIM_X} --dim_y ${DIM_Y} --dim_z ${DIM_Z}
    ${FSL_ROOT}/fslmaths ${IN_IM} -sub 1000 ${OUT_IM}

Intensity clipping [0, 1000] to eliminate boundary effect

    ${FSL_ROOT}/fslmaths ${IN_IM} -thr 0 -sub 1000 -uthr 0 -add 1000 ${OUT_IM}

| ![padded_A](./figs/moving_1_padded_A.png) |  ![padded_C](./figs/moving_1_padded_C.png) | ![padded_S](./figs/moving_1_padded_S.png) |
|:----------:|:-------------:|:------:|
| ![intens_clip_A](./figs/moving_1_intens_clip_A.png) |  ![intens_clip_C](./figs/moving_1_intens_clip_C.png) | ![intens_clip_S](./figs/moving_1_intens_clip_S.png) |
|    |    ||

**Registration**

Co-registration between preprocessed moving and fixed images.

    # ${REG_TOOL_ROOT} - location of bin folder of nifti_reg
    # ${FIXED_IMAGE} - preprocessed fixed image
    # ${MOVING_IMAGE} - preprocessed moving image
    # ${OUTPUT_IMAGE} - registered image
    # ${OUTPUT_AFFINE_MATRIX} - affine matrix
    ${REG_TOOL_ROOT}/reg_aladin -ln 5 -ref ${FIXED_IMAGE} -flo ${MOVING_IMAGE} -res ${OUTPUT_IMAGE} -aff ${OUTPUT_AFFINE_MATRIX}

| ![ref_intens_clip_A](./figs/moving_1_intens_clip_A.png) |  ![padded_C](./figs/register_intens_clip_A.png) | ![ref_intens_clip_A](./figs/ref_intens_clip_A.png) |
|:----------:|:-------------:|:------:|
| ![ref_intens_clip_C](./figs/moving_1_intens_clip_C.png) |  ![padded_C](./figs/register_intens_clip_C.png) | ![ref_intens_clip_A](./figs/ref_intens_clip_C.png) |
| ![ref_intens_clip_C](./figs/moving_1_intens_clip_S.png) |  ![padded_C](./figs/register_intens_clip_S.png) | ![ref_intens_clip_A](./figs/ref_intens_clip_S.png) |
|Moving image | Affine | fixed image|

**Interpolation**

Propagate the transformation (affine matrix) to original moving image using nearest neighbor interpolation under same coordinate space (i.e. with same resolution and boundary padding) 

    # ${SRC_ROOT} - location of the repository
    # ${CONFIG_FILE} - configuration file (./config/thorax_affine_example_20200103.sh)
    # ${IN_IMAGE} - original image without preprocessing
    # ${AFFINE_MATRIX} - transformation matrix as the output of affine registration
    # ${FIXED_IMAGE} - to provide the coordinate system of the resampled image
    # ${TEMP_FOLDER} - location for temporary files
    ${SRC_ROOT}/tools/ref_interp.sh ${CONFIG_FILE} ${IN_IMAGE} ${AFFINE_MATRIX} ${FIXED_IMAGE} ${OUT_IMAGE} ${TEMP_FOLDER}

| ![ref_intens_clip_A](./figs/moving_1_interp_pad_A.png) |  ![padded_C](./figs/moving_1_interp_A.png) | ![ref_intens_clip_A](./figs/ref_interp_A.png) |
|:----------:|:-------------:|:------:|
| ![ref_intens_clip_C](./figs/moving_1_interp_pad_S.png) |  ![padded_C](./figs/moving_1_interp_S.png) | ![ref_intens_clip_A](./figs/ref_interp_S.png) |
| ![ref_intens_clip_C](./figs/moving_1_interp_pad_C.png) |  ![padded_C](./figs/moving_1_interp_C.png) | ![ref_intens_clip_A](./figs/ref_interp_C.png) |
|Moving image | Affine | fixed image|

### More examples

|Image 1| Image 2 | Image 3 | Image 4 | Image 5 | Reference | 
|:---:|:---:|:---:|:---:|:---:|:---:|
|![ref_intens_clip_C](./figs/moving_1_interp_pad_A.png)| ![ref_intens_clip_C](./figs/moving_2_interp_pad_A.png) | ![ref_intens_clip_C](./figs/moving_3_interp_pad_A.png) | ![ref_intens_clip_C](./figs/moving_4_interp_pad_A.png) | ![ref_intens_clip_C](./figs/moving_5_interp_pad_A.png) |  |
|![ref_intens_clip_C](./figs/moving_1_interp_A.png)| ![ref_intens_clip_C](./figs/moving_2_interp_A.png) | ![ref_intens_clip_C](./figs/moving_3_interp_A.png) | ![ref_intens_clip_C](./figs/moving_4_interp_A.png) | ![ref_intens_clip_C](./figs/moving_5_interp_A.png) | ![ref_intens_clip_C](./figs/ref_interp_A.png) |
|![ref_intens_clip_C](./figs/moving_1_interp_pad_S.png)| ![ref_intens_clip_C](./figs/moving_2_interp_pad_S.png) | ![ref_intens_clip_C](./figs/moving_3_interp_pad_S.png) | ![ref_intens_clip_C](./figs/moving_4_interp_pad_S.png) | ![ref_intens_clip_C](./figs/moving_5_interp_pad_S.png) |  |
|![ref_intens_clip_C](./figs/moving_1_interp_S.png)| ![ref_intens_clip_C](./figs/moving_2_interp_S.png) | ![ref_intens_clip_C](./figs/moving_3_interp_S.png) | ![ref_intens_clip_C](./figs/moving_4_interp_S.png) | ![ref_intens_clip_C](./figs/moving_5_interp_S.png) | ![ref_intens_clip_C](./figs/ref_interp_S.png) |
|![ref_intens_clip_C](./figs/moving_1_interp_pad_C.png)| ![ref_intens_clip_C](./figs/moving_2_interp_pad_C.png) | ![ref_intens_clip_C](./figs/moving_3_interp_pad_C.png) | ![ref_intens_clip_C](./figs/moving_4_interp_pad_C.png) | ![ref_intens_clip_C](./figs/moving_5_interp_pad_C.png) |  |
|![ref_intens_clip_C](./figs/moving_1_interp_C.png)| ![ref_intens_clip_C](./figs/moving_2_interp_C.png) | ![ref_intens_clip_C](./figs/moving_3_interp_C.png) | ![ref_intens_clip_C](./figs/moving_4_interp_C.png) | ![ref_intens_clip_C](./figs/moving_5_interp_C.png) | ![ref_intens_clip_C](./figs/ref_interp_C.png) |

<!---
your comment goes here
and here

### Affine Template/Atlas (SPORE)

|Unregistered| Affine average | Variance (log) | Reference |
|:---:|:---:|:---:|:---:|
|![ref_intens_clip_C](./figs/ori_average_A.png)|![ref_intens_clip_C](./figs/template_affine_1_A.png)| ![ref_intens_clip_C](./figs/variance_A.png) |![ref_intens_clip_C](./figs/ref_pad_A.png)|
|![ref_intens_clip_C](./figs/ori_average_S.png)|![ref_intens_clip_C](./figs/template_affine_1_S.png)| ![ref_intens_clip_C](./figs/variance_S.png) |![ref_intens_clip_C](./figs/ref_pad_S.png)|
|![ref_intens_clip_C](./figs/ori_average_C.png)|![ref_intens_clip_C](./figs/template_affine_1_C.png)| ![ref_intens_clip_C](./figs/variance_C.png) |![ref_intens_clip_C](./figs/ref_pad_C.png)|

Note: 1 failed case out of 1473 scans.

-->

### Remarks on boundary handling of interpolation

Interpolation substeps related to intensity-nan boundary handling.

**Pad original image using nan**

    padding_image ${IM_RESAMPLE} ${IM_PAD} ${TEMP_FOLDER_PADDING} ${INTERP_ENV_VAL}
    ${C3D_ROOT}/c3d ${IM_PAD} -replace ${INTERP_ENV_VAL} nan -o ${IM_TO_NAN}
    
Example case (00000256time20170420, SPORE). Visualized using itksnap. nan voxel automatically change to 0:
![pad_with_nan](./figs/pad_with_nan.png)


**Resample using cubic interpolation**

Using option 1) "-inter 3" cubic interpolation; 2) "-pad NaN" nan padding of niftireg.

    ${REG_TOOL_ROOT}/reg_resample -inter 3 -pad NaN -ref ${FIXED_IM} -flo ${IM_INTERP_PRE} -trans ${TRANS_MAT} -res ${INTERP_DIR}/${file_name}

Interpolated image:    
![interpolated_with_nan](./figs/interpolated_with_nan.png)

Average of 10 interpolated images, with union of non-nan region:
![10_average_with_nan](./figs/10_average_with_nan.png)
