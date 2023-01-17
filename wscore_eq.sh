#!/bin/bash
#
# Run the w-score equation using fslmaths
#

beta1=$1
beta2=$2
beta3=$3
residualsSD=$4
ct=$5
age=$6
sex=$7
outputdir=$8
prefix=$9

clustersize=250
ctSmooth=$(basename ${ct} .nii.gz)_smooth.nii.gz
echo $ctSmooth

cd /opt/model
mkdir workdir
cd workdir

# Smooths the Cortical Thickness before generating all of the output needed to make wscores
SmoothImage 3 ${ct} 1 ${ctSmooth} 0 0

# wscore equation
ImageMath 3 ageTerm.nii.gz m ${beta1} ${age}
ImageMath 3 sexTerm.nii.gz m ${beta2} ${sex}
fslmaths ageTerm.nii.gz -add sexTerm.nii.gz -add ${beta3} predicted.nii.gz
fslmaths ${ctSmooth} -sub predicted.nii.gz num.nii.gz
fslmaths num.nii.gz -div ${residualsSD} wscore_tmp.nii.gz
fslmaths wscore_tmp.nii.gz -mul -1 ${prefix}_invZ.nii.gz

if [[ $clustersize != 0 ]];then

	# Compute connected components Doesn't this have to be a binary image?
	c3d ${prefix}_invZ.nii.gz -comp -o ${prefix}_comp.nii.gz # ????

	#Change minextent for changing cluster sizes!
	last=`${FSLDIR}/bin/cluster -i ${prefix}_comp.nii.gz -t 1 --minextent=$clustersize --mm | tail -1 | awk '{print $1}'`
	first=`${FSLDIR}/bin/cluster -i ${prefix}_comp.nii.gz -t 1 --minextent=$clustersize --mm | head -2 | tail -1 | awk '{print $1}'`

	echo
	echo $first
	echo

	fslmaths ${prefix}_comp.nii.gz -thr $last -uthr $first -bin -mul ${prefix}_invZ.nii.gz ${prefix}_indivHeatmap.nii.gz


fi

# apply transform
antsApplyTransforms \
 -d 3 \
 -i ${prefix}_indivHeatmap.nii.gz \
 -r /opt/resources/mni152.nii.gz \
 -n linear \
 -o ${prefix}_indivHeatmapMNI.nii.gz \
 -t [/opt/resources/Template_to_MNI_1Warp.nii.gz] \
 -t [/opt/resources/Template_to_MNI_0GenericAffine.mat] \
 -v


cp num.nii.gz ${outputdir}/
cp predicted.nii.gz ${outputdir}/
cp ${prefix}_invZ.nii.gz ${outputdir}/
cp ${prefix}_indivHeatmap.nii.gz ${outputdir}/
cp ${prefix}_indivHeatmapMNI.nii.gz ${outputdir}/
cp ${ct} ${outputdir}/
cp ${ctSmooth} ${outputdir}/





