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
    args = parser.parse_args()

    dim = []
    dim.append(args.dim_x)
    dim.append(args.dim_y)
    dim.append(args.dim_z)

    img = nib.load(args.ori)
    header = img.header
    print(header['dim'][1].dtype, dim[0])
    x_b = (header['dim'][1] - dim[0]) // 2
    y_b = (header['dim'][2] - dim[1]) // 2
    z_b = (header['dim'][3] - dim[2]) // 2

    os.system('fslroi ' + args.ori + ' ' + args.out + ' ' + str(x_b) + ' ' +
              str(dim[0]) + ' ' + str(y_b) + ' ' + str(dim[1]) + ' ' + str(str(z_b)) + ' ' + str(dim[2]))


def shift_nifti(img, shift_value):
    image_data = img.get_data()
    image_data_shifted = image_data + shift_value
    image_data_shifted_obj = nib.Nifti1Image(image_data_shifted, np.eye(4))
    return image_data_shifted_obj


if __name__ == '__main__':
    main()
