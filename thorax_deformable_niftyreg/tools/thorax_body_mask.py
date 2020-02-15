import os
from skimage import measure
import scipy.ndimage
import numpy as np
from PIL import Image
import nibabel as nib
import pdb, traceback, sys
import argparse


def create_body_mask(in_file_path, out_mask_path, out_image_path, env_intensity):
    test_image_path = in_file_path
    print('Creating body mask of image %s' % test_image_path)
    im = nib.load(test_image_path)
    im_data = im.get_data()
    spacing = im.header['pixdim'][1:4]

    im_shape = im_data.shape
    mask_3d = np.zeros(im_shape)
    for z_id in range(im_shape[2]):
        mask_cur_slice = get_body_mask_slice(im_data[:, :, z_id], spacing)
        mask_3d[:, :, z_id] = mask_cur_slice

    im_data_shifted = np.add(im_data, -env_intensity)
    im_data_masked = np.multiply(im_data_shifted, mask_3d.astype(np.float))
    im_data_shifted_back = np.add(im_data_masked, env_intensity)

    # save the mask as nifti
    mask_image_obj = nib.Nifti1Image(mask_3d.astype(np.int16) * 255, im.affine, header=im.header)
    print("Output mask to file %s" % out_mask_path)
    nib.save(mask_image_obj, out_mask_path)

    # save image as nifti
    out_image_obj = nib.Nifti1Image(im_data_shifted_back, im.affine, header=im.header)
    print("Output masked image to file %s" % out_image_path)
    nib.save(out_image_obj, out_image_path)


def get_body_mask_slice(slice, spacing, area_th=100, sigma=1, threshold_tissue=-600, eccen_th=0.99):

    slice_smooth = scipy.ndimage.gaussian_filter(slice.astype(np.float32), sigma)
    slice_binarized = slice_smooth > threshold_tissue

    label = measure.label(slice_binarized)
    properties = measure.regionprops(label)

    candidate_label = set()
    for prop in properties:
        if prop.area * spacing[1] * spacing[2] > area_th and prop.eccentricity < eccen_th:
            candidate_label.add(prop.label)

    # Find the label with largest area, that should be the body.
    mask_cur_slice = np.zeros(slice.shape)
    area_list = [prop.area for prop in properties]
    if len(area_list) > 0:
        max_area_index = area_list.index(max(area_list))
        prop_mass_body = properties[max_area_index]

        mask_cur_slice = label == prop_mass_body.label

        bbox = prop_mass_body.bbox
        filled_image = prop_mass_body.filled_image
        filled_image_full = np.zeros(label.shape).astype(np.bool)
        filled_image_full[bbox[0]:bbox[2], bbox[1]:bbox[3]] = filled_image

        mask_cur_slice = np.logical_or(mask_cur_slice, filled_image_full)
    else:
        print(f'Empty area_list with current slice.')

    return mask_cur_slice


if __name__ == '__main__':
    try:
        parser = argparse.ArgumentParser(description='Create mask file to remove the CT table')
        parser.add_argument('--in_image', type=str, help='Input image.')
        parser.add_argument('--out_mask', type=str, help='Output mask.')
        parser.add_argument('--out_image', type=str, help='Output image.')
        parser.add_argument('--env_intensity', type=float, default=-1000)
        args = parser.parse_args()

        create_body_mask(args.in_image, args.out_mask, args.out_image, args.env_intensity)

    except:
        extype, value, tb = sys.exc_info()
        traceback.print_exc()
        pdb.post_mortem(tb)