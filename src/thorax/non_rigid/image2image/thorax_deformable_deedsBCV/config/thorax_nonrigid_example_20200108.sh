# Config Version 2.0

DATA_ROOT=/nfs/masi/xuk9/SPORE
SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/04-registration_tutorial/thorax_deformable_deedsBCV
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python
REG_TOOL_ROOT=/fs4/masi/baos1/deeds_bk/deedsBCV
FSL_ROOT=/usr/local/fsl/bin
FREESURFER_ROOT=/nfs/masi/xuk9/local/freesurfer/bin

IN_ROOT=
OUT_ROOT=/nfs/masi/xuk9/SPORE/registration/affine_niftyreg/20200104_pipeline_demo/thorax_deformable_deedsBCV

IF_REMOVE_TEMP_FILES=false

SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=450
DIM_Y=450
DIM_Z=400

MAT_OUT=${OUT_ROOT}/omat
REG_OUT=${OUT_ROOT}/reg
PREPROCESS_OUT=${OUT_ROOT}/preprocess
SLURM_DIR=${OUT_ROOT}/slurm
LOG_DIR=${OUT_ROOT}/log
TEMP_DIR=${OUT_ROOT}/temp
FIXED_IMAGE_DIR=${OUT_ROOT}/fixed_image

FIXED_IMAGE=${FIXED_IMAGE_DIR}/fixed_image.nii.gz
