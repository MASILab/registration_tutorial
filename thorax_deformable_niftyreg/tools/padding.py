from skimage import transform
import nibabel as nib
import argparse
import os
import numpy as np


def main():
    parser = argparse.ArgumentParser(description='Resample The NIFTI image')
    parser.add_argument('--ori', type=str,
                        help='The original image path you want to resample')
    parser.add_argument('--out', type=str,
                        help='The output path of the generated image')
    parser.add_argument('--dim_x', type=int)
    parser.add_argument('--dim_y', type=int)
    parser.add_argument('--dim_z', type=int)
    parser.add_argument('--pad_val', type=float, default=-1000)
    parser.add_argument('--c3d_root', type=str)
    args = parser.parse_args()

    dim = []
    dim.append(args.dim_x)
    dim.append(args.dim_y)
    dim.append(args.dim_z)

    img = nib.load(args.ori)
    header = img.header

    vox_bot = np.zeros(3)
    vox_top = np.zeros(3)

    for dim_idx in range(3):
        vox_bot[dim_idx] = (dim[dim_idx] - header['dim'][dim_idx + 1]) // 2
        vox_top[dim_idx] = dim[dim_idx] - header['dim'][dim_idx + 1] - vox_bot[dim_idx]
        print(f'# vox padded to dim {dim_idx} is: bot {vox_bot[dim_idx]}, top {vox_top[dim_idx]}', flush=True)

    vox_bot_str = f'{vox_bot[0]}x{vox_bot[1]}x{vox_bot[2]}vox'
    vox_top_str = f'{vox_top[0]}x{vox_top[1]}x{vox_top[2]}vox'
    c3d_pad_comm_str = f'{args.c3d_root}/c3d {args.ori} -pad {vox_bot_str} {vox_top_str} {args.pad_val} -o {args.out}'
    print(c3d_pad_comm_str, flush=True)
    os.system(c3d_pad_comm_str)


def shift_nifti(img, shift_value):
    image_data = img.get_data()
    image_data_shifted = image_data + shift_value
    image_data_shifted_obj = nib.Nifti1Image(image_data_shifted, np.eye(4))
    return image_data_shifted_obj


if __name__ == '__main__':
    main()
