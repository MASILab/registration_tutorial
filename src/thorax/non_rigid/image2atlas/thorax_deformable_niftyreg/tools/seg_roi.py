import nibabel as nib
import numpy as np
import argparse
import os
import time
from seg_lung import segment_a_lung
import datetime

def run_preprocess_method(method_str, nii_file_path, mask_file_path, roi_region_path, output_file_path, c3d_root):
    if method_str == 'lung_seg_roi_clip_full':
        run_roi_clip(nii_file_path, mask_file_path, roi_region_path, output_file_path, c3d_root)
    elif method_str == 'lung_seg_roi_z_only':
        run_roi_clip_v2(nii_file_path, mask_file_path, roi_region_path, output_file_path, c3d_root)
    elif method_str == 'lung_seg_roi_z_mask':
        run_roi_mask_v1(nii_file_path, mask_file_path, roi_region_path, output_file_path)
    else:
        raise Exception('Unknown preprocess method.')

def run_roi_clip(ori_path, mask_path, roi_region_path, roi_clip_path, c3d_root):

    get_mask_image(ori_path, mask_path)
    xmin, xsize, ymin, ysize, zmin, zsize = get_roi(mask_path, roi_region_path)
    clip_roi_region(ori_path, roi_clip_path, xmin, xsize, ymin, ysize, zmin, zsize, c3d_root)


def run_roi_clip_v2(ori_path, mask_path, roi_region_path, roi_clip_path, fsl_root=''):

    get_mask_image(ori_path, mask_path)
    xmin, xsize, ymin, ysize, zmin, zsize = get_roi_z_clip_only(mask_path, roi_region_path)
    clip_roi_region(ori_path, roi_clip_path, xmin, xsize, ymin, ysize, zmin, zsize, fsl_root)


def run_roi_mask_v1(ori_path, mask_path, roi_region_path, roi_masked_path):
    get_mask_image(ori_path, mask_path)
    xmin, xsize, ymin, ysize, zmin, zsize = get_roi_z_clip_only(mask_path, roi_region_path)
    apply_roi_mask(ori_path, roi_masked_path, xmin, xsize, ymin, ysize, zmin, zsize)


def get_roi(mask_path, roi_path):
    t0 = time.time()
    roi_scale = 0.05

    print('Get ROI from %s ' % mask_path)
    img_nii = nib.load(mask_path)
    img = img_nii.get_data()
    roi = np.zeros(img.shape, dtype = np.uint8)
    x_list, y_list, z_list = [], [], []
    for i in range(img.shape[0]):
        if np.sum(img[i, :, :]) > 20:
            x_list.append(i)
    for i in range(img.shape[1]):
        if np.sum(img[:, i, :]) > 20:
            y_list.append(i)
    for i in range(img.shape[2]):
        if np.sum(img[:, :, i]) > 20:
            z_list.append(i)
            #roi[:, :, i] = 1
    x_begin, x_end = x_list[0] - int(roi_scale * len(x_list)), x_list[-1] + int (roi_scale * len(x_list))
    y_begin, y_end = y_list[0] - int(roi_scale * len(y_list)), y_list[-1] + int (roi_scale * len(y_list))
    z_begin, z_end = z_list[0] , z_list[-1]

    if x_end > img.shape[0]:
        x_end = img.shape[0]
    if x_begin < 0:
        x_begin = 0
    if y_end > img.shape[1]:
        y_end = img.shape[1]
    if y_begin < 0:
        y_begin = 0
    if z_end > img.shape[2]:
        z_end = img.shape[2]
    if z_begin < 0:
        z_begin = 0

    roi[x_begin: x_end, y_begin: y_end, z_begin: z_end] = 1
    roi_nii = nib.Nifti1Image(roi, img_nii.affine, img_nii.header)
    nib.save(roi_nii, roi_path)
    print('Output to %s' % roi_path)
    t1 = time.time()
    print('%.3f (s)' % (t1 - t0))

    return x_begin, x_end - x_begin, y_begin, y_end - y_begin, z_begin, z_end - z_begin


def get_roi_z_clip_only(mask_path, roi_path):
    t0 = time.time()
    roi_scale = 0.05

    print('Get ROI from %s ' % mask_path)
    img_nii = nib.load(mask_path)
    img = img_nii.get_data()
    roi = np.zeros(img.shape, dtype = np.uint8)
    x_list, y_list, z_list = [], [], []

    for i in range(img.shape[2]):
        if np.sum(img[:, :, i]) > 20:
            z_list.append(i)
            #roi[:, :, i] = 1

    z_begin, z_end = z_list[0] , z_list[-1]

    roi[:, :, z_begin: z_end] = 1
    roi_nii = nib.Nifti1Image(roi, img_nii.affine, img_nii.header)
    nib.save(roi_nii, roi_path)
    print('Output to %s' % roi_path)
    t1 = time.time()
    print('%.3f (s)' % (t1 - t0))

    x_begin = 0
    x_dim = img.shape[0]
    y_begin = 0
    y_dim = img.shape[1]

    z_dim = z_end - z_begin

    return x_begin, x_dim, y_begin, y_dim, z_begin, z_dim


def apply_roi_mask(ori_img_path, masked_img_path, xmin, xsize, ymin, ysize, zmin, zsize, ambient_val=-1000):
    t0 = time.time()
    print('Apply roi mask to ori image')
    ori_img_obj = nib.load(ori_img_path)
    ori_img_data = ori_img_obj.get_data()

    mask_img_data = np.zeros(ori_img_data.shape)
    mask_img_data = mask_img_data + ambient_val

    xmax = xmin + xsize
    ymax = ymin + ysize
    zmax = zmin + zsize
    mask_img_data[xmin:xmax, ymin:ymax, zmin:zmax] = ori_img_data[xmin:xmax, ymin:ymax, zmin:zmax]

    masked_img_obj = nib.Nifti1Image(mask_img_data, affine=ori_img_obj.affine, header=ori_img_obj.header)
    nib.save(masked_img_obj, masked_img_path)

    print('Output image %s' % masked_img_path)
    t1 = time.time()
    print('%.3f (s)' % (t1 - t0))


def clip_roi_region(ori_img_path, roi_img_path, xmin, xsize, ymin, ysize, zmin, zsize, c3d_root):
    t0 = time.time()
    # print('fsl_root', fsl_root)
    # roi_tool_str = os.path.join(fsl_root, 'fslroi')
    # command_roi_str = '%s %s %s %d %d %d %d %d %d' % \
    #                   (roi_tool_str, ori_img_path, roi_img_path,
    #                    xmin, xsize, ymin, ysize, zmin, zsize)

    print('c3d_root', c3d_root)
    roi_tool_str = os.path.join(c3d_root, 'c3d')
    command_roi_str = f'{roi_tool_str} {ori_img_path} -region {xmin}x{ymin}x{zmin}vox {xsize}x{ysize}x{zsize}vox -o {roi_img_path}'

    print('Cropping image %s...' % ori_img_path)
    print(command_roi_str)
    os.system(command_roi_str)
    print('Output image %s' % roi_img_path)
    t1 = time.time()
    print('%.3f (s)' % (t1 - t0))

def get_mask_image(ori_img_path, mask_img_path):
    t0 = time.time()
    print('Segment file %s' % ori_img_path)

    if os.path.exists(mask_img_path):
        print(mask_img_path + ' already existed')
    else:
        try:
            segment_a_lung(ori_img_path, mask_img_path)
            # command_get_mask_str = 'python ./seg_lung.py --ori %s --out %s' % (ori_img_path, mask_img_path)
            # os.system(command_get_mask_str)
            print('Output to file %s' % mask_img_path)
        except:
            print('get_mask_image-------------------- something is wrong with: ', ori_img_path)

    t1 = time.time()
    print('%.3f (s)' % (t1 - t0))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--method', type=str)
    parser.add_argument('--ori', type=str, help='Input image.')
    parser.add_argument('--mask', type=str, help='The mask data generated by kaggle method.')
    parser.add_argument('--roi_region', type=str)
    parser.add_argument('--roi', type=str, help='out path of the segmented image')
    parser.add_argument('--c3d_root', type=str)
    args = parser.parse_args()

    # run_roi_clip(args.ori, args.mask, args.roi_region, args.roi)
    run_preprocess_method(args.method, args.ori, args.mask, args.roi_region, args.roi, args.c3d_root)
    print('Exit run_roi_clip')
    print(datetime.datetime.now())
    print('')
