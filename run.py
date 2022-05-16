"""
Run script for calculating w-scores in Schaefer 200x17 atlas labels for a single patient.

Inputs
------
        label_index_file (str): path to csv indexing labels (e.g. V1 is 1)
        label_image_file (str): path to segmentation image in subject space
        ct_image_file (str): path to cortical thickness file in subject space
        t1_image_file (str): path to T1 image
        patient_age (float): age of patient in years
        patient_sex (int): sex of patient (0 for M, 1 for F)
        thresholds (str): space-separated 'list' of lower limit(s) to display w-scores in render
        prefix (str): string to use as file prefix
        output_dir (str): path to output directory


Contains the following functions:
    * get_parser - Creates an argument parser with appropriate input
    * get_vals - Generates a csv containing mean, median, etc. for cortical thickness outcomes.
    * main - Main function of the script


"""

import pandas as pd
import numpy as np
import ants
import os
import glob
import argparse
import logging
from joblib import load

# logging stuff
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('')


def get_parser():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--label_index_file",
        required=False
    )
    parser.add_argument(
        "--label_image_file",
        required=True
    )
    parser.add_argument(
        "--ct_image_file",
        required=True
    )
    parser.add_argument(
        "--t1_image_file"
    )
    parser.add_argument(
        "--patient_age",
        type=float,
        required=True
    )
    parser.add_argument(
        "--patient_sex",
        type=int,
        required=True
    )
    parser.add_argument(
        "--thresholds",
        type=str,
        required=True
    )
    parser.add_argument(
        "--prefix",
        required=True
    )
    parser.add_argument(
        "--output_dir"
    )

    return parser


def get_vals(label_index_file, label_image_file, ct_image_file):
    """
    Generate a csv containing mean, median, etc. for cortical thickness outcomes.

    Args:
        label_index_file (str): path to csv indexing labels (e.g. V1 is 1)
        label_image_file (str): path to segmentation image in subject space
        ct_image_file (str): path to outcome file (i.e. cortical thickness) in subject space

    Returns:
        A pandas DataFrame containing the appropriate data

    """

    labs_df = pd.read_csv(label_index_file)  # read in label index file
    header_list = list(labs_df)  # get names of columns already in dataframe
    summvar = ['mean', 'std', 'min', '25%', '50%', '75%',
               'max']  # order is CRUCIAL and dependent on order of pandas df.describe()
    labs_df = labs_df.reindex(columns=header_list + summvar + ['volume'])  # add summvar columns with NaNs
    nround = 6  # digits to round to

    # load images with ANTs
    label_mask = ants.image_read(label_image_file, 3)
    outcome = ants.image_read(ct_image_file, 3)
    hdr = ants.image_header_info(label_image_file)
    voxvol = np.prod(hdr['spacing'])  # volume of a voxel (e.g. 1mm^3)

    for i in range(len(labs_df)):
        labind = labs_df['label_number'][i]  # get label index, e.g. V1 is 1, etc.
        # flatten label image to 1D array (order=Fortran), create array
        w = np.where(label_mask.numpy().flatten(order='F') == labind)[0]
        if len(w) > 0:
            x = outcome.numpy().flatten(order='F')[w]  # get cortical thickness vals for voxels in current label
            # write summary variables into label dataframe
            desc = pd.DataFrame(x).describe()
            desc_list = desc[0].to_list()[1:]  # omit 'count' field
            labs_df.loc[i, summvar] = desc_list
            labs_df["volume"][i] = voxvol * len(w)  # volume for label is voxel volume times number of voxels
        else:
            # pad with 0s
            labs_df.loca[i, summvar] = [0] * len(summvar)
            labs_df["volume"][i] = 0

    #         print("{} {} ".format(labs_df["label_number"][i], labs_df["volume"][i]))

    # Round summary metrics
    for v in summvar:
        labs_df.loc[:, v] = round(labs_df.loc[:, v], nround)

    # un-pivot dataframe so each statistic (value_vars) has its own row, keeping id_vars the same
    labs_df_melt = pd.melt(labs_df, id_vars=['label_number', 'label_abbrev_name',
                                             'label_full_name', 'hemisphere'], value_vars=summvar + ['volume'], var_name='type')

    return labs_df_melt


def predict_ct(pt_age, pt_sex, pt_data):
    # w-score calculation | outputs a pd DataSeries
    logger.info("Predicting ct for each region of atlas...")

    # The new data to predict on, the age and sex of the patient
    new_data = np.array([pt_age,pt_sex]).reshape(1, -1)

    indices = []
    ct_vals = []
    modeldir = '/opt/model'
    idx=1
    for model in sorted(os.listdir(modeldir)):
        linear_regressor = load(os.path.join(modeldir,model))
        y_pred = linear_regressor.predict(new_data) # make the prediction
        ct_vals.append(y_pred[0])
        indices.append(idx)
        idx = idx + 1

    # save to DataFrame
    logger.info("Saving predicted CT values to Dataframe and csv...")
    d = {'label_number': indices, 'predictedCT': ct_vals}
    ct_df = pd.DataFrame(data=d)

    # add ROI names and actual CT values to spreadsheet
    ct_df.insert(1, "label_full_name", pt_data['label_full_name'], True)
    ct_df.insert(2, "actualCT", pt_data['value'], True)

    # calculate difference of predicted vs actual
    ct_df['diff'] = ct_df['predictedCT'] - ct_df['actualCT']

    return ct_df


def main():

    # Parse command line arguments
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    output_dir = args.output_dir
    logger.info("Set output directory to {}".format(output_dir))

    # define label index file
    label_index_file = '/opt/labelset/Schaefer2018_200Parcels_17Networks_order.csv'
    logger.info("Set label index file as {}".format(label_index_file))
    # Calculate ct metrics for patient and save to csv
    logger.info("Calculating cortical thickness metrics...")
    pt_data = get_vals(label_index_file, args.label_image_file, args.ct_image_file)
    pt_data = pt_data[pt_data.type == "mean"]  # just use the mean
    #pt_data.to_csv(os.path.join(output_dir, args.prefix + "_schaefer.csv"), index=False)
    # pt_data = pd.read_csv(metrics_csv)
    # get index label numbers
    label_idxs = pd.read_csv(label_index_file)
    indices = list()
    for ind in range(0, len(label_idxs)):
        i = label_idxs.label_number[ind]
        indices.append(i)

    # GENERATE PREDICTED CORTICAL THICKNESS VALUES
    pt_age = args.patient_age
    pt_sex = args.patient_sex
    ct_df = predict_ct(pt_age, pt_sex, pt_data)
    ct_csv_path = os.path.join(output_dir, args.prefix + "_predictedCT.csv")
    ct_df.to_csv(ct_csv_path, index=False)

    # Render images
    logger.info("Rendering heatmap...")
    # convert csv to text
    logger.info("Converting predicted cortical thickness csv to space-separated txt file.")
    ct_txt_path = os.path.splitext(ct_csv_path)[0] + '.txt'
    # remove middle column (region names) and convert commas to spaces
    convert_cmd = "cut -d, -f2-4 --complement {} | tr ',' ' ' > {}".format(ct_csv_path, ct_txt_path)
    logger.info(convert_cmd)
    os.system(convert_cmd)
    os.system("sed -i '1 d' {}".format(ct_txt_path))
    # project wscore data onto surface
    logger.info("Projecting cortical thickness values onto surface...")
    schaefer_scale = 'schaefer200x17'  # in case this becomes flexible later

    thresholds = args.thresholds.split(' ')
    for i in thresholds:
        render_cmd = "bash -x /opt/rendering/schaeferTableToFigure.sh -f {} -r {} -s 1 -c 'red_yellow' -h 1.75 -l {} -k 0".format(ct_txt_path, schaefer_scale, i)
        logger.info(render_cmd)
        os.system(render_cmd)
    # add the full spectrum
    render_cmd = "bash -x /opt/rendering/schaeferTableToFigure.sh -f {} -r {} -s 1 -h 1.75 -c 'red_yellow' -k 0".format(ct_txt_path, schaefer_scale)
    logger.info(render_cmd)
    os.system(render_cmd)
    logger.info("Done rendering.")


if __name__ == "__main__":
    main()
