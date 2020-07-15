# Tutorial for Thorax/Abdomen Registration

This repository includes the step-by-step instructions for abdomen/thorax registration pipelines used in MASI lab. Both affine and non-rigid registration will be discussed. Examples are provided to validate each step of the pipelines. Please refer to kaiwen.xu@vanderbilt.edu (Thorax) and yucheng.tang@vanderbilt.edu (Abdomen) for questions.

# Contributors

Kaiwen Xu<sup>1*</sup>,
Yucheng Tang<sup>1*</sup>,
Riqiang Gao<sup>1</sup>,
Mirza S. Khan<sup>1</sup>,
Ho Hin Lee<sup>1</sup>,
Shunxing Bao<sup>1</sup>,
Yuankai Huo<sup>1</sup>,
Steve A. Deppen<sup>2</sup>,
Alexis B. Paulson<sup>2</sup>,
Kim L. Sandler<sup>2</sup>,
Bennett A. Landman<sup>2</sup>

<sup>1</sup> Vanderbilt University, Nashville TN 37235, USA

<sup>2</sup> Vanderbilt University Medical Center, Nashville TN 37235, USA

<sup>*</sup> Maintainers of this repository

# Citation

If you find methods described in this tutorial can help your work, please cite:

Kaiwen Xu, Yucheng Tang, Riqiang Gao, Mirza S. Khan, Shunxing Bao, Yuankai Huo, Steve A. Deppen, Alexis B. Paulson, Kim L. Sandler, Bennett A. Landman. (2020, July 13). Tutorial for Thorax / Abdomen Registration (Version v1.0). Zenodo. http://doi.org/10.5281/zenodo.3942004

    @misc{kaiwen_xu_2020_3942004,
      author       = {Kaiwen Xu and
                      Yucheng Tang and
                      Riqiang Gao and
                      Mirza S. Khan and
                      Ho Hin Lee and
                      Shunxing Bao and
                      Yuankai Huo and
                      Steve A. Deppen and
                      Alexis B. Paulson and
                      Kim L. Sandler and
                      Bennett A. Landman},
      title        = {Tutorial for Thorax / Abdomen Registration},
      month        = jul,
      year         = 2020,
      publisher    = {Zenodo},
      version      = {v1.0},
      doi          = {10.5281/zenodo.3942004},
      url          = {https://doi.org/10.5281/zenodo.3942004}
    }

## Demos of working pipeline

+ Thorax examples
    + [**affine_niftireg**](./src/thorax/affine/niftireg/readme.md) 
    + [**deformable_corrField**](./src/thorax/non_rigid/corrField/readme.md)
    + [deformable_deedsBCV](./src/thorax/non_rigid/image2image/thorax_deformable_deedsBCV/readme.md)
    + [deformable_niftyreg](./src/thorax/non_rigid/image2atlas/thorax_deformable_niftyreg/readme.md)
    + [deformable_corrField](./src/thorax/non_rigid/corrField/readme.md)
+ Abdomen examples
    + [abdomen_affine_niftireg](./src/abdomen/abdomen_affine_niftireg/readme.md)
    + [abdomen_deformable_deedsBCV](./src/abdomen/abdomen_deformable_deedsBCV/readme.md)

## Registration tools

Here we maintain a list of registration tools that had been used or evaluated in MASI lab for thorax-abdomen-body registration tasks.

For corrField and deeds, we maintain our own customized version in our github. 
Please check [corrField_masi](https://github.com/MASILab/corrField_masi) and [deedsBCV_masi](./packages/deedsBCV/README.md). 
They have been evaluated, fine tuned and are now serving as our main working non-rigid registration tools. 

For FSL, ANTS, IRTK and NIFTYREG, the following contents are included from Zhoubing's review paper [[1]] as the known best practices.
For details, please refer to [[1]] and also its [supplementary materials](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4972188/bin/NIHMS805331-supplement-tbme-xu-2574816-mm_zip.zip) of [1].

### corrField

A non-rigid registration tool developed by Dr. Mattias Heinrich [[2]][[3]]. The original link (zip package): [corrFieldWeb.zip](http://www.mpheinrich.de/code/corrFieldWeb.zip)  
The tool follows a similar discrete optimization approach as deeds.
The difference is, while deeds uses regular densely sampled control points to drive registration, corrField is based on a group of unstructured distributed keypoints.
Given a mask on the reference image space, these key-points are selected based on a particular image feature detector.
This provide flexibilities to control the ROI region that drive registration, but with penalty on registration stability (folding problem) and accuracy.

The tool is carefully evaluated with the target to overcome the limited ROI flexibility of deeds.
A multi-step coarse-to-fine approach is proposed to mitigate the folding problem and increase registration accuracy.

For details, please refer to the session [deformable_corrField](./src/thorax/corrField/readme.md)

### DEEDS

DEnsE Displacement Sampling (http://mpheinrich.de/software.html) [[4]]
All parameters are internally defined. Please contact heinrich@imi.uni-luebeck.de for additional information.

We are maintaining a customized version of deedsBCV with several additional utilities while sharing the core registration algo with the original.

Please refer to [deedsBCV (masi version)](./packages/deedsBCV/README.md).

### FSL

FMRIB Software Library (FSL) version 5.0
(http://fsl.fmrib.ox.ac.uk/fsldownloads/)

    # ${TARGETIMG} -target intensity image
    # ${SOURCEIMG} – source intensity image
    # ${SOURCELABEL} – source atlas label
    # ${RIGIDIMG} – rigid registered image
    # ${RIGIDTFM} – rigid registration transformation
    # ${AFFINEIMG} – affine registered image
    # ${AFFINETFM} – affine registration transformation
    # ${AFFINELABEL} – affine registered label
    # ${NONRIGIDIMG} – non-rigid registered image
    # ${NONRIGIDTFM} – non-rigid registration transformation
    # ${NONRIGIDLABEL} – non-rigid registered label

    # rigid image registration 
    flirt -v -dof 6 -in ${SOURCEIMG} -ref ${TARGETIMG} -omat ${RIGIDTFM} -out ${RIGIDIMG} -nosearch
    # affine image registration
    flirt -v -dof 9 -in ${SOURCEIMG} -ref ${TARGETIMG} -init ${RIGIDTFM} -omat ${AFFINETFM} -out ${AFFINEIMG} -nosearch
    # affine label propagation
    flirt -v -in ${SOURCELABEL} -ref ${TARGETIMG} -applyxfm -init ${AFFINETFM} -out ${AFFINELABEL} -interp nearestneighbour
    # non-rigid image registration
    fnirt -v --in=${SOURCEIMG} –ref=${TARGETIMG} –aff=${AFFINETFM} –cout=${NONRIGIDTFM} –iout=${NONRIGIDIMG}
    # non-rigid label propagation
    applywarp -v -i ${SOURCELABEL} -w ${NONRIGIDTFM} --interp=nn -r ${TARGETIMG} -o ${NONRIGIDLABEL}

**Remarks**

+ For flirt, DOF can be set to 12 (affine), 9 (traditional), 7 (global rescale) or 6 (rigid body). 
  Full flirt user guide: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FLIRT/UserGuide


### ANTS-CC

Advanced Normalization Tools (ANTs) version 1.9
(http://sourceforge.net/projects/advants/files/ANTS/)

    # ${TARGETIMG} -target intensity image
    # ${SOURCEIMG} – source intensity image
    # ${SOURCELABEL} – source atlas label
    # ${RIGIDTFMPREFIX} – prefix of rigid registration transformation
    # ${RIGIDTFM} – rigid registration transformation (RIGIDTFM=${RIGIDTFMPREFIX}0GenericAffine.mat)
    # ${AFFINETFMPREFIX} – prefix of affine registration transformation
    # ${AFFINETFM} – affine registration transformation (AFFINETFM=${AFFINETFMPREFIX}0GenericAffine.mat)
    # ${AFFINELABEL} – affine registered label
    # ${NONRIGIDTFMPREFIX} – prefix of non-rigid registration transformation
    # ${NONRIGIDTFMWARP} – non-rigid registration associated warping field (NONRIGIDTFMWARP=${NONRIGIDTFMPREFIX}1Warp.nii.gz)
    # ${NONRIGIDTFMAFFINE} – non-rigid registration associated affine transformation (NONRIGIDTFMAFFINE==${NONRIGIDTFMPREFIX}0GenericAffine.mat)
    # ${NONRIGIDLABEL} – non-rigid registered label
    
    # run with two CPU cores
    NUMBEROFTHREADS=2
    ORIGINALNUMBEROFTHREADS=${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS}
    ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NUMBEROFTHREADS
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS
    # rigid image registration
    antsRegistration --dimensionality 3 --metric CC[${TARGETIMG},${SOURCEIMG},1,4] --interpolation Linear --transform Rigid[0.1] --initial-moving-transform [${TARGETIMG},${SOURCEIMG},1]  --winsorize-image-intensities [0.005,0.995] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 12x8x4x2 --smoothing-sigmas 4x3x2x1vox --float --output ${RIGIDTFMPREFIX}
    # affine image registration
    antsRegistration --dimensionality 3 --metric CC[${TARGETIMG},${SOURCEIMG},1,4]  --interpolation Linear --transform Affine[0.1] --initial-moving-transform ${RIGIDTFM} --winsorize-image-intensities [0.005,0.995] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 12x8x4x2 --smoothing-sigmas 4x3x2x1vox --float --output ${AFFINETFMPREFIX}
    # affine label propagation
    antsApplyTransforms --dimensionality 3 -i ${SOURCELABEL} -o ${AFFINELABEL} -r ${TARGETIMG} -t ${AFFINETFM} -n NearestNeighbor
    # non-rigid image registration
    antsRegistration --dimensionality 3 --metric [${TARGETIMG},${SOURCEIMG},1,4] --interpolation Linear --transform SyN[0.1,3,0] --initial-moving-transform ${AFFINETFM} --winsorize-image-intensities [0.005,0.995] --convergence [100x100x70x50x20,1e-6,10] --shrink-factors 10x6x4x2x1 --smoothing-sigmas 5x3x2x1x0vox --float --output ${NONRIGIDTFMPREFIX}
    # non-rigid label propagation
    antsApplyTransforms --dimensionality 3 -i ${SOURCELABEL} -o ${NONRIGIDLABEL} -r ${TARGETIMG} -t ${NONRIGIDTFMWARP} ${NONRIGIDTFMAFFINE} -n NearestNeighbor

### ANTS-QUICK-MI

Advanced Normalization Tools (ANTs) version 1.9
(http://sourceforge.net/projects/advants/files/ANTS/)

    # ${TARGETIMG} -target intensity image
    # ${SOURCEIMG} – source intensity image
    # ${SOURCELABEL} – source atlas label
    # ${RIGIDTFMPREFIX} – prefix of rigid registration transformation
    # ${RIGIDTFM} – rigid registration transformation (RIGIDTFM=${RIGIDTFMPREFIX}0GenericAffine.mat)
    # ${AFFINETFMPREFIX} – prefix of affine registration transformation
    # ${AFFINETFM} – affine registration transformation (AFFINETFM=${AFFINETFMPREFIX}0GenericAffine.mat)
    # ${AFFINELABEL} – affine registered label
    # ${NONRIGIDTFMPREFIX} – prefix of non-rigid registration transformation
    # ${NONRIGIDTFMWARP} – non-rigid registration associated warping field (NONRIGIDTFMWARP=${NONRIGIDTFMPREFIX}1Warp.nii.gz)
    # ${NONRIGIDTFMAFFINE} – non-rigid registration associated affine transformation (NONRIGIDTFMAFFINE==${NONRIGIDTFMPREFIX}0GenericAffine.mat)
    # ${NONRIGIDLABEL} – non-rigid registered label
    
    # run with two CPU cores
    NUMBEROFTHREADS=2
    ORIGINALNUMBEROFTHREADS=${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS}
    ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NUMBEROFTHREADS
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS
    # rigid image registration
    antsRegistration --dimensionality 3 --metric MI[${TARGETIMG},${SOURCEIMG},1,32,REGULAR,0.25] --interpolation Linear --transform Rigid[0.1] --initial-moving-transform [${TARGETIMG},${SOURCEIMG},1]  --winsorize-image-intensities [0.005,0.995] --convergence [1000x500x250x0,1e-6,10] --shrink-factors 12x8x4x2 --smoothing-sigmas 4x3x2x1vox --float --output ${RIGIDTFMPREFIX}
    # affine image registration
    antsRegistration --dimensionality 3 --metric MI[${TARGETIMG},${SOURCEIMG},1,32,REGULAR,0.25]  --interpolation Linear --transform Affine[0.1] --initial-moving-transform ${RIGIDTFM} --winsorize-image-intensities [0.005,0.995] --convergence [1000x500x250x0,1e-6,10] --shrink-factors 12x8x4x2 --smoothing-sigmas 4x3x2x1vox --float --output ${AFFINETFMPREFIX}
    # affine label propagation
    antsApplyTransforms --dimensionality 3 -i ${SOURCELABEL} -o ${AFFINELABEL} -r ${TARGETIMG} -t ${AFFINETFM} -n NearestNeighbor
    # non-rigid image registration
    antsRegistration --dimensionality 3 --metric [${TARGETIMG},${SOURCEIMG},1,4] --interpolation Linear --transform SyN[0.1,3,0] --initial-moving-transform ${AFFINETFM} --winsorize-image-intensities [0.005,0.995] --convergence [100x100x70x50x0,1e-6,10] --shrink-factors 10x6x4x2x1 --smoothing-sigmas 5x3x2x1x0vox --float --output ${NONRIGIDTFMPREFIX}
    # non-rigid label propagation
    antsApplyTransforms --dimensionality 3 -i ${SOURCELABEL} -o ${NONRIGIDLABEL} -r ${TARGETIMG} -t ${NONRIGIDTFMWARP} ${NONRIGIDTFMAFFINE} -n NearestNeighbor

### IRTK

Image Registration Toolkit (IRTK) version 2.0
(http://www.doc.ic.ac.uk/~dr/software/download.html)

    # ${TARGETIMG} -target intensity image
    # ${SOURCEIMG} – source intensity image
    # ${SOURCELABEL} – source atlas label
    # ${RIGIDIMG} – rigid registered image
    # ${RIGIDTFM} – rigid registration transformation
    # ${AFFINETFM} – affine registration transformation
    # ${AFFINELABEL} – affine registered label
    # ${NONRIGIDTFM} – non-rigid registration transformation
    # ${NONRIGIDLABEL} – non-rigid registered label
    
    # rigid image registration 
    rreg ${TARGETIMG} ${SOURCEIMG} -dofout ${RIGIDTFM} -translation_only -Tp -900
    # affine image registration
    areg ${TARGETIMG} ${SOURCEIMG} -dofin ${RIGIDTFM} -dofout ${AFFINETFM} -translation_scale –Tp -900
    # affine label propagation
    transformation ${SOURCELABEL} ${AFFINELABEL} -dofin ${AFFINETFM} -target ${TARGETIMG} -nn -matchInputType
    # non-rigid image registration
    nreg ${TARGETIMG} ${SOURCEIMG} -dofin ${AFFINETFM} -dofout ${NONRIGIDTFM} -Tp -900 -ds 20
    # non-rigid label propagation
    transformation ${SOURCELABEL} ${NONRIGIDLABEL} -dofin ${NONRIGIDTFM} -target ${TARGETIMG} -nn –matchInputType

### NIFTYREG

NiftyReg, version with the 390df2baaf809a625ed5afe0dbc81ca6a3f7c647 Git hash
(http://sourceforge.net/p/niftyreg/git/ci/master/tree/)

    # ${TARGETIMG} -target intensity image
    # ${SOURCEIMG} – source intensity image
    # ${SOURCELABEL} – source atlas label
    # ${AFFINEIMG} – affine registered image
    # ${AFFINETFM} – affine registration transformation
    # ${AFFINELABEL} – affine registered label
    # ${NONRIGIDIMG} – non-rigid registered image
    # ${NONRIGIDTFM} – non-rigid registration transformation
    # ${NONRIGIDLABEL} – non-rigid registered label
    
    # affine image registration
    reg_aladin -ln 5 -omp 2 -ref ${TARGETIMG} -flo ${SOURCEIMG} -res ${AFFINEIMG} -aff ${AFFINETFM} 
    # affine label propagation
    reg_resample -inter 0 -ref ${TARGETIMG} -flo ${SOURCELABEL} -trans ${AFFINETFM} -res ${AFFINELABEL} 
    # non-rigid image registration
    reg_f3d -ln 5 --rUpTh 500 --fUpTh 500 -omp 2 -maxit 1000 -ref ${TARGETIMG} -flo ${SOURCEIMG} -aff ${AFFINETFM} -cpp ${NONRIGIDTFM} -res ${NONRIGIDIMG}
    # non-rigid label propagation
    reg_resample -inter 0 -ref ${TARGETIMG} -flo ${SOURCELABEL} -trans ${NONRIGIDTFM} -res ${NONRIGIDLABEL}

# References
[1] Xu, Z., Lee, C. P., Heinrich, M. P., Modat, M., Rueckert, D., Ourselin, S., … Landman, B. A. (2016). Evaluation of Six Registration Methods for the Human Abdomen on Clinically Acquired CT. IEEE Transactions on Biomedical Engineering, 63(8), 1563–1572. https://doi.org/10.1109/TBME.2016.2574816

[2] Heinrich, M. P., Handels, H., & Simpson, I. J. A. (2015). Estimating large lung motion in COPD patients by symmetric regularised correspondence fields. Lecture Notes in Computer Science (Including Subseries Lecture Notes in Artificial Intelligence and Lecture Notes in Bioinformatics), 9350, 338–345. https://doi.org/10.1007/978-3-319-24571-3_41

[3] Ruhaak, J., Polzin, T., Heldmann, S., Simpson, I. J. A., Handels, H., Modersitzki, J., & Heinrich, M. P. (2017). Estimation of Large Motion in Lung CT by Integrating Regularized Keypoint Correspondences into Dense Deformable Registration. IEEE Transactions on Medical Imaging, 36(8), 1746–1757. https://doi.org/10.1109/TMI.2017.2691259

[4] Heinrich, M. P., Jenkinson, M., Brady, M., & Schnabel, J. A. (2013). MRF-Based deformable registration and ventilation estimation of lung CT. IEEE Transactions on Medical Imaging, 32(7), 1239–1248. https://doi.org/10.1109/TMI.2013.2246577
