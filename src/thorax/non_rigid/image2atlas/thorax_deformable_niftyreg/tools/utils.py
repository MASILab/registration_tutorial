import os
import errno
import math
import shutil


def get_range_paral_chunk(total_num_item, chunk_pair):
    num_item_each_chunk = int(math.ceil(float(total_num_item) / float(chunk_pair[1])))
    range_lower = num_item_each_chunk * (chunk_pair[0] - 1)
    # range_upper = num_item_each_chunk * chunk_pair[0] - 1
    range_upper = num_item_each_chunk * chunk_pair[0]
    if range_upper > total_num_item:
        range_upper = total_num_item

    return [range_lower, range_upper]


def get_current_chunk(in_list, chunk_pair):
    chunks_list = get_chunks_list(in_list, chunk_pair[1])
    current_chunk = chunks_list[chunk_pair[0] - 1]
    return current_chunk


def get_chunks_list(in_list, num_chunks):
    return [in_list[i::num_chunks] for i in range(num_chunks)]


def get_nii_filepath_and_filename_list(dataset_root):
    nii_file_path_list = []
    subject_list = os.listdir(dataset_root)
    for i in range(len(subject_list)):
        subj = subject_list[i]
        subj_path = dataset_root + '/' + subj
        sess_list = os.listdir(subj_path)
        for sess in sess_list:
            sess_path = subj_path + '/' + sess
            nii_files = os.listdir(sess_path)
            for nii_file in nii_files:
                nii_file_path = sess_path + '/' + nii_file
                nii_file_path_list.append(nii_file_path)
                # nii_file_name_list.append(nii_file)


    return nii_file_path_list


def get_nii_filepath_and_filename_list_flat(dataset_root):
    nii_file_path_list = []
    nii_file_name_list = os.listdir(dataset_root)
    for file_name in nii_file_name_list:
        nii_file_path = os.path.join(dataset_root, file_name)
        nii_file_path_list.append(nii_file_path)

    return nii_file_path_list


def get_nii_filepath_and_filename_list_hierarchy(dataset_root):
    nii_file_path_list = []
    nii_file_name_list = []
    subject_list = os.listdir(dataset_root)
    for i in range(len(subject_list)):
        subj = subject_list[i]
        subj_path = dataset_root + '/' + subj
        sess_list = os.listdir(subj_path)
        for sess in sess_list:
            sess_path = subj_path + '/' + sess
            nii_files = os.listdir(sess_path)
            for nii_file in nii_files:
                nii_file_path = sess_path + '/' + nii_file
                nii_file_path_list.append(nii_file_path)
                nii_file_name_list.append(nii_file)

    return nii_file_path_list


def get_dataset_path_list(dataset_root, dataset_type):
    file_path_list = []
    if dataset_type == 'flat':
        file_path_list = get_nii_filepath_and_filename_list_flat(dataset_root)
    elif dataset_type == 'hierarchy':
        file_path_list = get_nii_filepath_and_filename_list(dataset_root)
    else:
        file_path_list = []

    return file_path_list


def resample_spore_nifti(spore_nifti_root, spore_resample_root):
    """
    Resample spore data, using c3d
    :param spore_nifti_root:
    :param spore_resample_root:
    :return:
    """
    spore_nii_file_path_list = []
    spore_nii_file_name_list = []
    subject_list = os.listdir(spore_nifti_root)
    for i in range(len(subject_list)):
        subj = subject_list[i]
        subj_path = spore_nifti_root + '/' + subj
        sess_list = os.listdir(subj_path)
        for sess in sess_list:
            sess_path = subj_path + '/' + sess
            nii_files = os.listdir(sess_path)
            for nii_file in nii_files:
                nii_file_path = sess_path + '/' + nii_file
                spore_nii_file_path_list.append(nii_file_path)
                spore_nii_file_name_list.append(nii_file)

    file_count = 1
    for iFile in range(len(spore_nii_file_path_list)):
        # if file_count > 3:
        #     break

        file_path = spore_nii_file_path_list[iFile]
        file_name = spore_nii_file_name_list[iFile]

        output_path = spore_resample_root + '/' + file_name

        print('Read image: ', file_path)

        # command_read_info_str = 'c3d ' + file_path + ' -info-full'
        # os.system(command_read_info_str)

        command_str = 'c3d ' + file_path + ' -resample 256x256x180 -o ' + output_path

        os.system(command_str)

        print('Output file: ', file_name, " {}/{}".format(iFile, len(spore_nii_file_name_list)))
        # command_image_info_str = 'c3d ' + output_path + ' -info-full'
        #
        # os.system(command_image_info_str)

        file_count = file_count + 1


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise


def get_image_name_from_path(image_path):
    return os.path.basename(image_path)


def dataset_hierarchy_to_flat(in_folder, out_folder):
    file_path_list = get_nii_filepath_and_filename_list(in_folder)
    for file_idx in range(len(file_path_list)):
        file_path = file_path_list[file_idx]
        print(f'({file_idx}/{len(file_path_list)}), Process image {file_path}.')
        file_name = get_image_name_from_path(file_path)
        out_path = os.path.join(out_folder, file_name)
        if os.path.exists(out_path):
            print(out_path + ' already exist')
        else:
            print('Copy file %s to %s' % (file_path, out_path))
            shutil.copyfile(file_path, out_path)


def get_extension(file_full_path):
    filename, file_extension = os.path.splitext(file_full_path)
    return file_extension


def get_registration_command_non_rigid(registration_method_name,
                                       reg_args,
                                       label_file,
                                       reg_tool_root,
                                       fixed_image,
                                       moving_image,
                                       output_image,
                                       output_mat,
                                       output_trans,
                                       output_affine):
    command_list = []
    actual_output_mat_path = output_mat + '_matrix.txt'

    if registration_method_name == 'deformable_deedsBCV':
        linearBCVslow_path = os.path.join(reg_tool_root, 'linearBCVslow')
        deedsBCVslow_path = os.path.join(reg_tool_root, 'deedsBCVslow')
        label_prop_command = ''
        if label_file != '':
            label_prop_command = f'-S {label_file}'
        command_list.append(f'{linearBCVslow_path} -F {fixed_image} -M {moving_image} -O {output_mat}')
        command_list.append(f'{deedsBCVslow_path} {reg_args} -F {fixed_image} -M {moving_image} -O {output_image} -A {actual_output_mat_path} {label_prop_command}')
    elif registration_method_name == 'deformable_deedsBCV_paral':
        linearBCV_path = os.path.join(reg_tool_root, 'linearBCV')
        deedsBCV_path = os.path.join(reg_tool_root, 'deedsBCV')

        label_prop_command = ''
        if label_file != '':
            label_prop_command = f'-S {label_file}'

        command_list.append(f'{linearBCV_path} -F {fixed_image} -M {moving_image} -O {output_mat}')
        command_list.append(f'{deedsBCV_path} {reg_args} -F {fixed_image} -M {moving_image} -O {output_image} -A {actual_output_mat_path} {label_prop_command}')
    elif registration_method_name == 'deformable_niftyreg':
        reg_aladin_path = os.path.join(reg_tool_root, 'reg_aladin')
        reg_f3d_path = os.path.join(reg_tool_root, 'reg_f3d')

        output_mat_real = output_mat.replace('.nii.gz', '.txt')
        output_affine_im = output_affine
        output_non_rigid_trans = output_trans

        command_list.append(
            f'{reg_aladin_path} -voff {reg_args} -ref {fixed_image} -flo {moving_image} -res {output_affine_im} -aff {output_mat_real}'
        )

        command_list.append(
            f'{reg_f3d_path} -voff {reg_args} -maxit 1000 -sx 10 -ref {fixed_image} -flo {moving_image} -aff {output_mat_real} -cpp {output_non_rigid_trans} -res {output_image}'
        )

    else:
        command_list.append('TODO')

    return command_list


def get_registration_command(registration_method_name, reg_args, label_file, reg_tool_root, fixed_image, moving_image, output_image, output_mat):

    command_list = []
    actual_output_mat_path = output_mat + '_matrix.txt'

    if registration_method_name == 'affine_flirt':
        flirt_path = os.path.join(reg_tool_root, 'flirt')
        command_str = f'{flirt_path} {reg_args} -dof 12 -in {moving_image} -ref {fixed_image} -out {output_image} -omat {output_mat} '
        command_list.append(command_str)
    elif registration_method_name == 'affine_flirt_zhoubing':
        flirt_path = os.path.join(reg_tool_root, 'flirt')
        # 1. Rigid.
        mid_step_rigid_mat = output_mat + "_rigid.txt"
        mid_step_rigid_im = output_mat + "_rigid.nii.gz"
        command_list.append(f'{flirt_path} -v -dof 6 -in {moving_image} -ref {fixed_image} -omat {mid_step_rigid_mat} -out {mid_step_rigid_im} -nosearch')
        # 2. DOF 9 Affine.
        command_list.append(f'{flirt_path} -v -dof 9 -in {moving_image} -ref {fixed_image} -init {mid_step_rigid_mat} -omat {output_mat} -out {output_image} -nosearch')
    elif registration_method_name == 'affine_nifty_reg':
        reg_aladin_path = os.path.join(reg_tool_root, 'reg_aladin')
        output_mat_real = output_mat.replace('.nii.gz', '.txt')
        command_list.append(f'{reg_aladin_path} -ln 5 -ref {fixed_image} -flo {moving_image} -res {output_image} -aff {output_mat_real}')
    elif registration_method_name == 'affine_nifty_reg_mask':
        reg_aladin_path = os.path.join(reg_tool_root, 'reg_aladin')
        output_mat_real = output_mat.replace('.nii.gz', '.txt')
        fixed_image_mask = fixed_image.replace('.nii.gz', '_mask.nii.gz')
        moving_image_mask = moving_image.replace('.nii.gz', '_mask.nii.gz')
        command_list.append(f'{reg_aladin_path} -ln 5 -ref {fixed_image} -rmask {fixed_image_mask} -flo {moving_image} -fmask {moving_image_mask} -res {output_image} -aff {output_mat_real}')
    elif registration_method_name == 'rigid_nifty_reg':
        reg_aladin_path = os.path.join(reg_tool_root, 'reg_aladin')
        output_mat_real = output_mat.replace('.nii.gz', '.txt')
        command_list.append(
            f'{reg_aladin_path} -rigOnly -ln 5 -ref {fixed_image} -flo {moving_image} -res {output_image} -aff {output_mat_real}')
    elif registration_method_name == 'affine_deedsBCV':
        linearBCVslow_path = os.path.join(reg_tool_root, 'linearBCVslow')
        applyLinearBCVfloat_path = os.path.join(reg_tool_root, 'applyLinearBCVfloat')
        command_list.append(f'{linearBCVslow_path} -F {fixed_image} -M {moving_image} -O {output_mat}')
        command_list.append(f'{applyLinearBCVfloat_path} -M {moving_image} -A {actual_output_mat_path} -D {output_image}')
    elif registration_method_name == 'deformable_deedsBCV':
        linearBCVslow_path = os.path.join(reg_tool_root, 'linearBCVslow')
        deedsBCVslow_path = os.path.join(reg_tool_root, 'deedsBCVslow')

        label_prop_command = ''
        if label_file != '':
            label_prop_command = f'-S {label_file}'

        command_list.append(f'{linearBCVslow_path} -F {fixed_image} -M {moving_image} -O {output_mat}')
        command_list.append(f'{deedsBCVslow_path} {reg_args} -F {fixed_image} -M {moving_image} -O {output_image} -A {actual_output_mat_path} {label_prop_command}')
    elif registration_method_name == 'deformable_deedsBCV_paral':
        linearBCV_path = os.path.join(reg_tool_root, 'linearBCV')
        deedsBCV_path = os.path.join(reg_tool_root, 'deedsBCV')

        label_prop_command = ''
        if label_file != '':
            label_prop_command = f'-S {label_file}'

        command_list.append(f'{linearBCV_path} -F {fixed_image} -M {moving_image} -O {output_mat}')
        command_list.append(f'{deedsBCV_path} {reg_args} -F {fixed_image} -M {moving_image} -O {output_image} -A {actual_output_mat_path} {label_prop_command}')
    elif registration_method_name == 'deformable_niftyreg':
        reg_aladin_path = os.path.join(reg_tool_root, 'reg_aladin')
        reg_f3d_path = os.path.join(reg_tool_root, 'reg_f3d')

        output_mat_real = output_mat.replace('.nii.gz', '.txt')
        output_affine_im = output_image.replace('.nii.gz', '_affine.nii.gz')
        output_non_rigid_trans = output_image.replace('.nii.gz', '_non_rigid_trans.nii.gz')

        command_list.append(
            f'{reg_aladin_path} -ln 5 -omp 32 -ref {fixed_image} -flo {moving_image} -res {output_affine_im} -aff {output_mat_real}'
        )

        command_list.append(
            f'{reg_f3d_path} -ln 5 -omp 32 -maxit 1000 {reg_args} -ref {fixed_image} -flo {moving_image} -aff {output_mat_real} -cpp {output_non_rigid_trans} -res {output_image}'
        )

    else:
        command_list.append('TODO')

    return command_list


def get_interpolation_command(interp_type_name, bash_config, src_root, moving_image):

    command_list = []
    file_name = moving_image
    real_mat_name = file_name.replace('nii.gz', 'txt')

    bash_script_path = ''
    if interp_type_name == 'clipped_ori':
        bash_script_path = os.path.join(src_root, 'tools/interp_clipped_roi.sh')
    elif interp_type_name == 'full_ori':
        bash_script_path = os.path.join(src_root, 'tools/interp_full_ori.sh')
    elif interp_type_name == 'roi_lung_mask':
        bash_script_path = os.path.join(src_root, 'tools/interp_ori_lung_mask.sh')

    command_list.append(f'{bash_script_path} {bash_config} {file_name} {real_mat_name}')

    return command_list
