

# Runtime enviroment
PROJ_ROOT=/home/local/VANDERBILT/xuk9/03-Projects/04-registration_tutorial/thorax_deformable_niftyreg/..
SRC_ROOT=${PROJ_ROOT}/thorax_deformable_niftyreg
PYTHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python

# Tools
TOOL_ROOT=${PROJ_ROOT}/packages
DCM_2_NII_TOOL=${TOOL_ROOT}/dcm2niix
C3D_ROOT=${TOOL_ROOT}/c3d
NIFYREG_ROOT=${TOOL_ROOT}/niftyreg/bin
REG_TOOL_ROOT=${NIFYREG_ROOT}

# Data
DEMO_DATA_ROOT=/nfs/masi/registration_demo_data/thorax/non_rigid_niftyreg
DEMO_SCANS=${DEMO_DATA_ROOT}/demo_scan_nii
OUT_ROOT=${SRC_ROOT}/demo_output

# Preprocessing
SPACING_X=1
SPACING_Y=1
SPACING_Z=1
DIM_X=441
DIM_Y=441
DIM_Z=400

IF_REMOVE_TEMP_FILES=false
PRE_METHOD=resample_pad_res

# Registration
REG_METHOD=deformable_niftyreg
IMAGE_ATLAS=${DEMO_DATA_ROOT}/atlas/atlas.nii.gz
IMAGE_LABEL=${DEMO_DATA_ROOT}/atlas/label.nii.gz

# Running environment
NUM_PROCESSES=16

        