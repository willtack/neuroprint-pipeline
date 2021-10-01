## Docker
#### Inputs
The pipeline requires three input images, a label image, a cortical thickness, and a brain-extracted T1w, all in subject space. It also requires a csv indexing the labels, but that is baked into the gear.
Move these images to an `input` folder, e.g. `/home/user/myproject/sub-01/input`. Next, make directory for the output files, e.g. `/home/user/myproject/sub-01/output` and mount both directories into the container as in the first two lines of the command. `/input` and `/output` after the colon refer to the directory locations within the container.

#### Parameters
After the call to the Docker image itself, there are parameters that will be passed to the main python script in the container. Leave `--label_index_file` as is. Use the within-container paths for the image files (i.e. `/input`), which will have the same names as in your local directories.
`--patient_age` is the patient's age at day of scan, an input to the model. `--patient_sex` is obvious. `--thresholds` refers to the w-scores at which the rendered statistical maps will be thresholded (exactly three). `--prefix` is how the output filenames will begin and `--output_dir` is the location in the container where output files should go (match it up with the second line in the command).

```
docker run  -v /home/user/myproject/sub-01/input:/input \
            -v /home/user/myproject/sub-01/output:/output \
            willtack/neuroprint-pipeline:0.4.0 \
            --label_index_file /opt/labelset/Schaefer2018_200Parcels_17Networks_order.csv \
            --label_image_file /input/sub-120870_ses-120870x20191205x3T_Schaefer2018_200Parcels17Networks.nii.gz \
            --ct_image_file /input/sub-120870_ses-120870x20191205x3T_CorticalThickness.nii.gz \
            --t1_image_file /input/sub-120870_ses-120870x20191205x3T_ExtractedBrain0N4.nii.gz \
            --patient_age 72 --patient_sex 0 --thresholds '0.0 0.5 1.0' --prefix sub-120870_ses-120870x20191205x3T --output_dir /output

```
