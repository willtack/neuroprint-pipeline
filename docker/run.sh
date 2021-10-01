#!/bin/bash
#
# Testing neuroprint Docker image standalone (i.e. not on Flywheel)
#

docker run  -v /home/will/Gears/neuroprint-pipeline/docker/input:/input \
            -v /home/will/Gears/neuroprint-pipeline/docker/output:/output \
            willtack/neuroprint-pipeline:0.5.0 \
            --label_image_file /input/sub-120870_ses-120870x20191205x3T_Schaefer2018_200Parcels17Networks.nii.gz \
            --ct_image_file /input/sub-120870_ses-120870x20191205x3T_CorticalThickness.nii.gz \
            --t1_image_file /input/sub-120870_ses-120870x20191205x3T_ExtractedBrain0N4.nii.gz \
            --patient_age 72 --patient_sex 0 --thresholds '0.0 0.5 1.0' --prefix sub-120870_ses-120870x20191205x3T --output_dir /output


# Uncomment to run interactively
# docker run  --rm -ti --entrypoint=/bin/bash \
#              -v /home/will/Gears/neuroprint-pipeline/docker/input:/input \
#              -v /home/will/Gears/neuroprint-pipeline/docker/output:/output \
#              willtack/neuroprint-pipeline:0.5.0 
