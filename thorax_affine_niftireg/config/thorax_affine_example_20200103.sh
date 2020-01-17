
DATA_ROOT=/nfs/masi/xuk9/SPORE
SRC_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/04-registration_tutorial/thorax_affine_niftireg
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python
REG_TOOL_ROOT=/home/local/VANDERBILT/gaor2/bin_tool/rg/niftyreg
FSL_ROOT=/usr/local/fsl/bin
FREESURFER_ROOT=/nfs/masi/xuk9/local/freesurfer/bin
C3D_ROOT=/home/local/VANDERBILT/xuk9/src/c3d/bin

IN_ROOT=
OUT_ROOT=/nfs/masi/xuk9/SPORE/registration/affine_niftyreg/20200104_pipeline_demo/thorax_affine_niftireg

IF_REMOVE_TEMP_FILES=false

SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=550
DIM_Y=550
DIM_Z=500

MAT_OUT=${OUT_ROOT}/omat
REG_OUT=${OUT_ROOT}/reg
PREPROCESS_OUT=${OUT_ROOT}/preprocess
SLURM_DIR=${OUT_ROOT}/slurm
LOG_DIR=${OUT_ROOT}/log
TEMP_DIR=${OUT_ROOT}/temp
FIXED_IMAGE_DIR=${OUT_ROOT}/fixed_image

FIXED_IMAGE=${FIXED_IMAGE_DIR}/fixed_image.nii.gz
