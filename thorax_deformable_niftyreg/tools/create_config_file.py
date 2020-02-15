import argparse

def generate_config_file(bash_config_path, num_processes, proj_root):
    print(f'Generate configuration file {bash_config_path}')
    print(f'Num of processes: {num_processes}')
    with open(bash_config_path, 'w') as rsh:
        rsh.write(f'''

# Runtime enviroment
PROJ_ROOT={proj_root}
SRC_ROOT=${{PROJ_ROOT}}/thorax_deformable_niftyreg
PYEHON_ENV=/home/local/VANDERBILT/xuk9/anaconda3/envs/python37/bin/python

# Tools
TOOL_ROOT=${{PROJ_ROOT}}/packages
DCM_2_NII_TOOL=${{TOOL_ROOT}}/dcm2niix
C3D_ROOT=${{TOOL_ROOT}}/c3d
NIFYREG_ROOT=${{TOOL_ROOT}}/niftyreg/bin
REG_TOOL_ROOT=${{NIFYREG_ROOT}}

# Data
DEMO_DATA_ROOT=/nfs/masi/registration_demo_data/thorax/non_rigid_niftyreg
DEMO_SCANS=${{DEMO_DATA_ROOT}}/demo_scan_nii
OUT_ROOT=${{SRC_ROOT}}/demo_output

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
IMAGE_ATLAS=${{DEMO_DATA_ROOT}}/atlas/atlas.nii.gz
IMAGE_LABEL=${{DEMO_DATA_ROOT}}/atlas/label.nii.gz

# Running environment
NUM_PROCESSES={num_processes}

        ''')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--config-path', type=str)
    parser.add_argument('--num-processes', type=int)
    parser.add_argument('--proj-root', type=str)

    args = parser.parse_args()
    generate_config_file(args.config_path, args.num_processes, args.proj_root)
