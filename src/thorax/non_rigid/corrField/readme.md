# Registration with scan-adaptive irregular ROI masks

## Problem with previous deeds pipeline

The major difficulty for the pipeline based on deeds is how to handle the problem of scan specified irregular valid regions.
NaN voxels, voxels without meaningful intensity, are introduced to the field-of-view after affine registration. 
These voxels must be excluded before feeding the scans into the registration engine. 
The solution was to find a small lung segmentation based ROI region that can include most interested intensity information for later analysis, 
and at the same time to exclude the nan-voxels. 
Then the voxels outside the region were imputed with the ambient intensity.

This approximation on boundary handling can lead to several type of registration flaws 

**Missing intensity**

<img src="./figs/missing_intensity.png" alt="drawing" width="200"/>


**Registration driven by ambient**

<img src="./figs/boundary_issue_2.png" alt="drawing" width="200" title="Registration driven by ambient"/>


