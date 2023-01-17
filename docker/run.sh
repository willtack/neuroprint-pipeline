#!/bin/bash
#
# Testing neuroprint Docker image standalone (i.e. not on Flywheel)
#

docker run  -v /home/will/Gears/neuroprint-pipeline/docker/input:/input \
            -v /home/will/Gears/neuroprint-pipeline/docker/output:/output \
            willtack/neuroprint-pipeline:0.13.0 \
            --ct_image_file /input/sub-105371_ses-20071009x1020_CorticalThicknessNormalizedToTemplate.nii.gz \
            --t1_image_file /input/sub-120870_ses-120870x20191205x3T_ExtractedBrain0N4.nii.gz \
            --patient_age 83 --patient_sex 0 --thresholds '0.0 0.5 1.0' --prefix sub-105371_ses-20071009 --output_dir /output


# Uncomment to run interactively
#docker run  --rm -ti --entrypoint=/bin/bash \
#              -v /home/will/Gears/neuroprint-pipeline/docker/input:/input \
#              -v /home/will/Gears/neuroprint-pipeline/docker/output:/output \
#             willtack/neuroprint-pipeline:0.13.0
