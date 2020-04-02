#!/bin/bash

REG_TOOL_ROOT=/fs4/masi/baos1/deeds_bk/deedsBCV
FIXED_IMAGE=/nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200108_pipeline_demo/preprocessed/reference.nii.gz

for i in $(seq 1 1)
do
    # ./reg_preprocess.sh ../config/thorax_nonrigid_example_20200108.sh /nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200108_pipeline_demo/demo_cases/moving${i}.nii.gz /nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200108_pipeline_demo/preprocessed/moving${i}.nii.gz /nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200108_pipeline_demo/temp

    # ${REG_TOOL_ROOT} - location of deedsBCV
    # ${FIXED_IMAGE} - preprocessed fixed image
    # ${MOVING_IMAGE} - preprocessed moving image
    # ${OUTPUT_IMAGE} - registered image
    # ${OUTPUT_AFFINE_MATRIX} - name of affine matrix (without extension)

    MOVING_IMAGE=/nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200108_pipeline_demo/preprocessed/moving${i}.nii.gz
    OUTPUT_AFFINE_MATRIX=/nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200108_pipeline_demo/mat/moving${i}
    OUTPUT_IMAGE=/nfs/masi/xuk9/SPORE/registration/nonrigid_deedsBCV/20200108_pipeline_demo/reg/moving${i}.nii.gz
    ${REG_TOOL_ROOT}/linearBCV -F ${FIXED_IMAGE} -M ${MOVING_IMAGE} -O ${OUTPUT_AFFINE_MATRIX}
    ${REG_TOOL_ROOT}/deedsBCV -F ${FIXED_IMAGE} -M ${MOVING_IMAGE} -O ${OUTPUT_IMAGE} -A ${OUTPUT_AFFINE_MATRIX}_matrix.txt
done
