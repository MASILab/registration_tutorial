import nibabel as nib
import argparse
import pdb, traceback, sys

def main():
    try:
        parser = argparse.ArgumentParser(description='Fix the boundary issue of mri_roi resampling.')
        parser.add_argument('--ori', type=str,
                            help='The original image path you want to resample')
        parser.add_argument('--out', type=str,
                            help='The output path of the generated image')
        parser.add_argument('--pad_val', type=float, default=-1000.0)
        args = parser.parse_args()

        print(f'Loading {args.ori} to remove boundary artifacts')
        img_art = nib.load(args.ori)
        img_art_data = img_art.get_data()

        img_art_data[ 0,  :,  :] = args.pad_val
        img_art_data[-1,  :,  :] = args.pad_val
        img_art_data[ :,  0,  :] = args.pad_val
        img_art_data[ :, -1,  :] = args.pad_val
        img_art_data[ :,  :,  0] = args.pad_val
        img_art_data[ :,  :, -1] = args.pad_val

        print(f'Output to {args.out}')
        img_art_removed_obj = nib.Nifti1Image(img_art_data, img_art.affine, img_art.header)
        nib.save(img_art_removed_obj, args.out)
    except:
        extype, value, tb = sys.exc_info()
        traceback.print_exc()
        pdb.post_mortem(tb)


if __name__ == '__main__':
    main()
