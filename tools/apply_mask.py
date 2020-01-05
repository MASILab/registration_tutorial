import os
from tools.utils import *
import argparse
import numpy as np
import nibabel as nib


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ori', type=str)
    parser.add_argument('--mask', type=str)
    parser.add_argument('--ambient', type=float, default=-1000)
    parser.add_argument('--out', type=str)
    args = parser.parse_args()

    ori_img_obj = nib.load(args.ori)
    mask_img_obj = nib.load(args.mask)

    ori_img = ori_img_obj.get_data()
    mask_img = mask_img_obj.get_data()

    masked_img = np.zeros(ori_img.shape)
    masked_img = np.add(masked_img, args.ambient)

    masked_img[mask_img > 0] = ori_img[mask_img > 0]

    masked_img_obj = nib.Nifti1Image(masked_img, affine=ori_img_obj.affine, header=ori_img_obj.header)
    nib.save(masked_img_obj, args.out)


if __name__ == '__main__':
    main()
