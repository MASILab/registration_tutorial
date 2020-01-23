## Registration pipeline, non-rigid (Abdomen 1/22/2020)

A working pipeline for non-rigid registration of Abdomen CT. The pipeline is based on DeedsBCV.
Please contact yucheng (yucheng.tang@vanderbilt.edu) for any issues.

### Methods

**Preprocessing**:

Run preprocessing for generating same resolution same dimension image to target.

    # ${CONFIG_FILE} - configuration file (e.g. ./config/thorax_nonrigid_example_20200108.sh)
    # ${IN_IMAGE} - input image to preprocess
    # ${OUT_IMAGE} - output image
    # ${TEMP_FOLDER} - location for files of each preprocess substep  
    ./tools/reg_preprocess.sh ${CONFIG_FILE} ${IN_IMAGE} ${OUT_IMAGE} ${TEMP_FOLDER}
    
Preprocessing sub-steps:

Resampling to same resolution

    ${FREESURFER_ROOT}/mri_convert -vs $SPACING_X $SPACING_Y $SPACING_Z ${IN_IM} ${OUT_IM}
    
Padding to same dimensions

    ${FSL_ROOT}/fslmaths ${IN_IM} -add 1000 ${OUT_IM}
    ${FSL_ROOT}/fslmaths ${IN_IM} -thr 0 ${OUT_IM}
    ${PYTHON_ENV} ${SRC_ROOT}/tools/padding.py --ori ${IN_IM} --out ${OUT_IM} --dim_x ${DIM_X} --dim_y ${DIM_Y} --dim_z ${DIM_Z}
    ${FSL_ROOT}/fslmaths ${IN_IM} -sub 1000 ${OUT_IM}
    
**Registration**

Co-registration between preprocessed moving and fixed images.

    # ${REG_TOOL_ROOT} - location of deedsBCV
    # ${FIXED_IMAGE} - preprocessed fixed image
    # ${MOVING_IMAGE} - preprocessed moving image
    # ${OUTPUT_IMAGE} - registered image
    # ${OUTPUT_AFFINE_MATRIX} - name of affine matrix (without extension)
    ${REG_TOOL_ROOT}/linearBCV -F ${FIXED_IMAGE} -M ${MOVING_IMAGE} -O ${OUTPUT_AFFINE_MATRIX}
    ${REG_TOOL_ROOT}/deedsBCV -F ${FIXED_IMAGE} -M ${MOVING_IMAGE} -O ${OUTPUT_IMAGE} -A ${OUTPUT_AFFINE_MATRIX}_matrix.txt

| ![ref_intens_clip_A](./figs_Ab/moving_demo1.png) | ![padded_C](./figs_Ab/target_demo1.png) | ![ref_intens_clip_A](./figs_Ab/overlay_demo1.png) |
| ![ref_intens_clip_A](./figs_Ab/moving_demo11.png) | ![padded_C](./figs_Ab/target_demo11.png) | ![ref_intens_clip_A](./figs_Ab/overlay_demo11.png) |
| ![ref_intens_clip_A](./figs_Ab/moving_demo111.png) | ![padded_C](./figs_Ab/target_demo111.png) | ![ref_intens_clip_A](./figs_Ab/overlay_demo111.png) |
|:----------:|:-------------:|:------:|
|Moving image | Target | Overlay |


### More examples
|Image 1| Image 2 | Image 3 | Image 4 | Image 5 | Reference | 
|:---:|:---:|:---:|:---:|:---:|:---:|
|![ref_intens_clip_C](./figs_Ab/moving_1.png)| ![ref_intens_clip_C](./figs_Ab/moving_2.png) | ![ref_intens_clip_C](./figs_Ab/moving_3.png) | ![ref_intens_clip_C](./figs_Ab/moving_4.png) | ![ref_intens_clip_C](./figs_Ab/moving_5.png) |  ![ref_intens_clip_C](./figs_Ab/target_1.png)  |
|![ref_intens_clip_C](./figs_Ab/moving_11.png)| ![ref_intens_clip_C](./figs_Ab/moving_22.png) | ![ref_intens_clip_C](./figs_Ab/moving_33.png) | ![ref_intens_clip_C](./figs_Ab/moving_44.png) | ![ref_intens_clip_C](./figs_Ab/moving_55.png) | ![ref_intens_clip_C](./figs_Ab/target_11.png) |
|![ref_intens_clip_C](./figs_Ab/moving_111.png)| ![ref_intens_clip_C](./figs_Ab/moving_222.png) | ![ref_intens_clip_C](./figs_Ab/moving_333.png) | ![ref_intens_clip_C](./figs_Ab/moving_444.png) | ![ref_intens_clip_C](./figs_Ab/moving_555.png) | ![ref_intens_clip_C](./figs_Ab/target_111.png) |


