#!/bin/bash
# Copyright 2010 Thomas Walters <tom@acousticscale.org>
#
# Run a series of experiments which compare MFCC features generated by HTK to
# AIM features generated using AIM-C using a series of syllable recogntiton
# tasks.
# This script expects to be run from within the AIM-C source tree.
# It builds the HTK binaries and AIM-C AIMCopy binary if they're not 
# present. 
# The following environment varaibles should be set before this script is run:
# SYLLABLES_DATABASE_URL - URL of a tar file containing the CNBH syllables
# database in FLAC format
# HTK_USERNAME and HTK_PASSWORD - username and password for the site at 
# http://htk.eng.cam.ac.uk/
# NUMBER_OF_CORES - total number of machine cores

# Set these to be the location of your input database, and desired output
# locations.
SYLLABLES_DATABASE_TAR=/mnt/sounds/cnbh-syllables.tar
SOUNDS_ROOT=/mnt/experiments/sounds/
FEATURES_ROOT=/mnt/experiments/features/
HMMS_ROOT=/mnt/experiments/hmms/

# Number of cores on the experimental machine. Various scripts will try to use
# this if it's set.
# NUMBER_OF_CORES=8

# Fail if any command fails
set -e

# Fail if any variable is unset
set -u

if [ ! -e $SYLLABLES_DATABASE_TAR ]; then
  sudo mkdir -p `dirname $SYLLABLES_DATABASE_TAR`
  sudo chown `whoami` `dirname $SYLLABLES_DATABASE_TAR`
  wget -O $SYLLABLES_DATABASE_TAR $SYLLABLES_DATABASE_URL
fi

if [ ! -d $SOUNDS_ROOT ]; then
  sudo mkdir -p $SOUNDS_ROOT
  sudo chown `whoami` $SOUNDS_ROOT
fi

# Untar the CNBH syllables database, and convert the files from FLAC to WAV
if [ ! -e $SOUNDS_ROOT/.untar_db_success ]; then
  tar -x -C $SOUNDS_ROOT -f $SYLLABLES_DATABASE_TAR
  touch $SOUNDS_ROOT/.untar_db_success
fi

# Convert the database to .WAV format and place it in $SOUNDS_ROOT/clean
echo "Converting CNBH-syllables database from FLAC to WAV..."
./cnbh-syllables/feature_generation/convert_flac_to_wav.sh $SOUNDS_ROOT

# Generate versions of the CNBH syllables spoke pattern with a range of
# signal-to-noise ratios (SNRs). The versions are put in the directory
# ${SOUNDS_ROOT}/${SNR}_dB/ for each SNR in $SNRS.
SNRS="30 27 24 21 18 15 12 9 6 3 0"
#SNRS="30" # For testing
./cnbh-syllables/feature_generation/pink_noise.sh $SOUNDS_ROOT/clean/ "$SNRS"

# Make the list of all feature drectories
FEATURE_DIRS="clean"
for SNR in $SNRS; do
  FEATURE_DIRS="$FEATURE_DIRS snr_${SNR}dB"
done

# Generate feature sets (for the full range of SNRs in $FEATURE_DIRS)
# 1. Standard MFCC features
# 2. AIM features
# 3. MFCC features with optimal VTLN 


if [ ! -d $FEATURES_ROOT ]; then
  sudo mkdir -p $FEATURES_ROOT
  sudo chown `whoami` $FEATURES_ROOT
fi

if [ ! -e /mnt/experiments/htk/.htk_installed_success ]; then
  ./HTK/install_htk.sh
fi

if [ ! -e /mnt/experiments/aimc/.aimc_build_success ]; then
# ./aimc/build_aimc.sh
  cd ../../
  scons
  export PATH=$PATH:`pwd`/build/posix-release/
  cd -
fi

for SOURCE_SNR in $FEATURE_DIRS; do
  
  if [ ! -e $FEATURES_ROOT/mfcc/$SOURCE_SNR/.make_mfcc_features_success ]; then
    mkdir -p $FEATURES_ROOT/mfcc/$SOURCE_SNR/
    # Generate the list of files to convert
    ./cnbh-syllables/feature_generation/gen_hcopy_aimcopy_script.sh $FEATURES_ROOT/mfcc/$SOURCE_SNR/ $SOUNDS_ROOT/$SOURCE_SNR/ htk
    # Run the conversion
    #./cnbh-syllables/feature_generation/run_hcopy.sh $FEATURES_ROOT/mfcc/$SOURCE_SNR/ $NUMBER_OF_CORES
    #touch $FEATURES_ROOT/mfcc/$SOURCE_SNR/.make_mfcc_features_success
  fi

  if [ ! -e $FEATURES_ROOT/mfcc_vtln/$SOURCE_SNR/.make_mfcc_vtln_features_success ]; then
    mkdir -p $FEATURES_ROOT/mfcc_vtln/$SOURCE_SNR/
    # Generate the file list and run the conversion (all one step, since this
    # version uses a different configuration for each talker)
    #./cnbh-syllables/feature_generation/run_mfcc_vtln_conversion.sh $FEATURES_ROOT/mfcc_vtln/$SOURCE_SNR/ $SOUNDS_ROOT/$SOURCE_SNR/
    #touch $FEATURES_ROOT/mfcc_vtln/$SOURCE_SNR/.make_mfcc_vtln_features_success
  fi

  if [ ! -e $FEATURES_ROOT/aim/$SOURCE_SNR/.make_aim_features_success ]; then
    mkdir -p $FEATURES_ROOT/aim/$SOURCE_SNR/ 
    ./cnbh-syllables/feature_generation/gen_hcopy_aimcopy_script.sh $FEATURES_ROOT/aim/$SOURCE_SNR/ $SOUNDS_ROOT/$SOURCE_SNR/ ""
    # Run the conversion
    ./cnbh-syllables/feature_generation/run_aimcopy.sh $FEATURES_ROOT/aim/$SOURCE_SNR/ $NUMBER_OF_CORES
    touch $FEATURES_ROOT/aim/$SOURCE_SNR/.make_aim_features_success
  fi
done 

sudo mkdir -p $HMMS_ROOT
sudo chown `whoami` $HMMS_ROOT

# Now run a bunch of experiments.
# For each of the feature types, we want to run HMMs with a bunch of
# parameters.
TRAINING_ITERATIONS="0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"
TESTING_ITERATIONS="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"
HMM_STATES="3 4 5 6 7 8"
HMM_OUTPUT_COMPONENTS="1 2 3 4 5 6 7"

return 0

run_train_test () {
# TODO(tom): Make sure that the training SNR is generated first
for SOURCE_SNR in $FEATURE_DIRS; do
WORK=$HMMS_ROOT/$FEATURE_CLASS/$FEATURE_SUFFIX/$SOURCE_SNR/$TALKERS/
mkdir -p $WORK
FEATURES_DIR=$FEATURES_ROOT/$FEATURE_CLASS/$SOURCE_SNR/

./cnbh-syllables/run_training_and_testing/train_test_sets/generate_train_test_lists.sh \
    $TALKERS \
    $WORK \
    $FEATURES_DIR \
    $FEATURE_SUFFIX

TRAINING_SCRIPT=$HMMS_ROOT/$FEATURE_CLASS/$FEATURE_SUFFIX/$TRAINING_SNR/$TALKERS/training_script
TRAINING_MASTER_LABEL_FILE=$HMMS_ROOT/$FEATURE_CLASS/$FEATURE_SUFFIX/$TRAINING_SNR/$TALKERS/training_master_label_file

TESTING_SCRIPT=$WORK/testing_script
TESTING_MASTER_LABEL_FILE=$WORK/testing_master_label_file

./cnbh-syllables/run_training_and_testing/gen_htk_base_files.sh $WORK

./cnbh-syllables/run_training_and_testing/test_features.sh \
    "$WORK" \
    "$FEATURES_ROOT/$FEATURE_CLASS/$SOURCE_SNR/" \
    "$FEATURE_SUFFIX" \
    "$HMM_STATES" \
    "$HMM_OUTPUT_COMPONENTS" \
    "$TRAINING_ITERATIONS" \
    "$TESTING_ITERATIONS" \
    "$FEATURE_SIZE" \
    "$FEATURE_TYPE" \
    "$TRAINING_SCRIPT" \
    "$TESTING_SCRIPT" \
    "$TRAINING_MASTER_LABEL_FILE" \
    "$TESTING_MASTER_LABEL_FILE"
done
}


########################
# Standard MFCCs
FEATURE_CLASS=mfcc
FEATURE_SUFFIX=htk
FEATURE_SIZE=39
FEATURE_TYPE=MFCC_0_D_A
TALKERS=inner_talkers
TRAINING_SNR=clean
run_train_test
########################

########################
# Standard MFCCs
# Train on extrema
FEATURE_CLASS=mfcc
FEATURE_SUFFIX=htk
FEATURE_SIZE=39
FEATURE_TYPE=MFCC_0_D_A
TALKERS=outer_talkers
TRAINING_SNR=clean
run_train_test
########################

########################
# MFCCs with VTLN
FEATURE_CLASS=mfcc_vtln
FEATURE_SUFFIX=htk
FEATURE_SIZE=39
FEATURE_TYPE=MFCC_0_D_A
TALKERS=inner_talkers
TRAINING_SNR=clean
run_train_test
########################

########################
# MFCCs with VTLN
# Train on extrema
FEATURE_CLASS=mfcc_vtln
FEATURE_SUFFIX=htk
FEATURE_SIZE=39
FEATURE_TYPE=MFCC_0_D_A
TALKERS=outer_talkers
TRAINING_SNR=clean
run_train_test
########################

########################
# AIM Features
# TODO (loop over all feature suffixes)
########################





