# LQPrivateGen
Private (for now) signal generation for resonant leptoquark production via the lepton-quark fusion process.
See: https://arxiv.org/abs/2209.02599

# Make directory
```
mkdir lqSignalGen
cd lqSignalGen
```

# Clone this repo
```
git clone git@github.com:CMSLQ/LQPrivateGen.git
```

# Produce gridpack with powheg-box-res
Following https://cms-generators.docs.cern.ch/how-to-produce-gridpacks/powheg-box/

## Launch apptainer
```
apptainer registry login --username [CERN username] oras://gitlab-registry.cern.ch
apptainer pull oras://gitlab-registry.cern.ch/cms-alabama/lq1/lqprivategencontainer/lqprivategen:latest
export APPTAINER_BINDPATH=/afs,/cvmfs,/cvmfs/grid.cern.ch/etc/grid-security:/etc/grid-security,/cvmfs/grid.cern.ch/etc/grid-security/vomses:/etc/vomses,/eos,/etc/pki/ca-trust,/etc/tnsnames.ora,/run/user,/tmp,/var/run/user,/etc/sysconfig,/etc:/orig/etc && apptainer exec --env KRB5CCNAME="FILE:${XDG_RUNTIME_DIR}/krb5cc" lqprivategen_latest.sif /bin/bash
```

## Set up CMSSW
```
export SCRAM_ARCH=slc7_amd64_gcc900
cmsrel CMSSW_12_0_4
cd CMSSW_12_0_4/src/
cmsenv
```

## Clone genproductions repo
```
git clone --depth=1 --single-branch https://github.com/cms-sw/genproductions.git
cd genproductions/bin/Powheg  
```

## Build powheg (need at least revision 3967)
### Use a process card from the LQPrivateGen repo
```
python3 ./run_pwg_condor.py -p 0 -i ../LQPrivateGen/powheg/inputNLO/powheg.input-save-NLO-cmssw-LQToDEle_M-1000 -m LQ-s-chan -f LQ-s-chan-nlo-dele-1000 -d 1 --svn 4128
```

## LHE file generation
### Modify the make_LHE.sh script
You will need to modify the signal name in the script, as well as the desired masses/couplings, and you must have the prepared the powheg input file.
The powheg input file needs to contain the correct electric charge of the LQ depending on the quark/lepton coupling desired.
You will also probably want to change the output directory specified in the script.
### Execute the make_LHE.sh script
The script will override the mass and coupling value in the powheg input file. Check to make sure you are modifying the desired coupling, and that the other couplings are nonzero in the powheg input file.
Then execute the script, which will run powheg interactively over the desired masses and couplings to produce the LHE files.
The LHE files are modified after production: split into the number of specified events per file, as well as being tweaked to be compatible with CMSSW.
```
[wherever LQPrivateGen repo is]/scripts/make_LHE.sh
```

# Showering the LHE events with Herwig
## Compile the custom Herwig
### Launch container (as before)
```
export APPTAINER_BINDPATH=/afs,/cvmfs,/cvmfs/grid.cern.ch/etc/grid-security:/etc/grid-security,/cvmfs/grid.cern.ch/etc/grid-security/vomses:/etc/vomses,/eos,/etc/pki/ca-trust,/etc/tnsnames.ora,/run/user,/tmp,/var/run/user,/etc/sysconfig,/etc:/orig/etc && apptainer exec --env KRB5CCNAME="FILE:${XDG_RUNTIME_DIR}/krb5cc" lqprivategen_latest.sif /bin/bash
```

### Create CMSSW area
```
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc7_amd64_gcc700
cmsrel CMSSW_10_6_28
cd CMSSW_10_6_28/src/
```

### Set up mercurial using venv in cmssw
```
cmsenv
scram-venv
cmsenv
pip3 install mercurial
```

### Setup the LHAPDF we need and compile patched Herwig (will take some time)
```
cd [wherever LQPrivateGen repo is]/herwig
source ../scripts/setup_LHAPDF.sh
./InstallationScript.sh
```

## Do the GEN step with Herwig
### Check out our fork of the EXO-MCsampleProductions repo
```
git clone git@gitlab.cern.ch:7999/cms-alabama/lq1/EXO-MCsampleProductions.git
```
### Setup CMSSW areas for sample generation
```
cd EXO-MCsampleProductions/
# copy gen fragment
cp -p [location of LQPrivateGen]/fragments/LQToUEle_leptonInduced_M-1000.py packages/FullSimulation/GEN/skeleton/genfragments/
python setup.py
```
### Install custom herwig7 into CMSSW
```
cd [wherever GEN CMSSW is inside the EXO-MCsampleProductions area]
# check default version as a baseline
scram tool list | grep herwig7
# create private tool file
cp config/toolbox/slc7_amd64_gcc700/tools/selected/herwig7.xml .
scram tool remove herwig7
# edit the file so that HERWIGPP_BASE is defined as [wherever LQPrivateGen repo is]/herwig and the version is something like 7.7.2custom
cp herwig7.xml config/toolbox/slc7_amd64_gcc700/tools/available/
scram setup herwig7
# check that it picked up the new version
scram tool list | grep herwig7
# and then pick it up in the cms env
cmsenv
```

### Run the showering
```
cd [wherever GEN CMSSW is inside the EXO-MCsampleProductions area]/src
cmsenv
source [wherever LQPrivateGen repo is]/scripts/setup_LHAPDF.sh
# modify csv file to contain the .list file that was produced as a result of the make_LHE.sh step
# copy csv file
cp -p [location of LQPrivateGen]/config/GEN/LQToUEle_leptonInduced_M-1000_lambda1p0.csv .
# create the cfg.py for CMSSW GEN production
python config_GEN.py --inputLHE LQToUEle_leptonInduced_M-1000_lambda1p0.csv
# Run the make_GEN.sh script to interactively run CMSSW
#   this will run over each LHE file sequentially
#   here we run 20000 events at a time, as that is what we had specified for each file in the make_LHE.sh script
python [location of LQPrivateGen]/scripts/make_GEN.py -i LeptonInducedLQ_uele_M1000_Lambda1p0.list -o [storage dir; can be EOS] -s LQToUEle_leptonInduced_M-1000_lambda1p0/LQToUEle_M-1000_lambda1p0_leptonInduced_TuneCH3_13TeV-powheg-herwig7/run_crab.py -n 20000
```

### Running cmsDriver manually (alternative)
```
cd [wherever CMSSW is]/src
cmsenv
source [wherever LQPrivateGen repo is]/scripts/setup_LHAPDF.sh
git cms-addpkg Configuration/Generator
mkdir -p Configuration/GenProduction/python
# copy fragment (example)
cp [wherever LQPrivateGen repo is]/fragments/LQToDEle_leptonInduced_M-2000.py Configuration/GenProduction/python/
scram b
# run cmsDriver; adjust number of events with -n argument
cmsDriver.py Configuration/GenProduction/python/LQToDEle_leptonInduced_M-2000.py --conditions 106X_mcRun2_asymptotic_preVFP_v8 --beamspot Realistic25ns13TeV2016Collision --geometry DB:Extended --era Run2_2016_HIPM  -s GEN --datatier GEN -n 10 --eventcontent RAWSIM --python_filename singleLQ_13TeV_Pow_Herwig7_cfg.py --no_exec --mc
# do the cmsRun
cmsRun singleLQ_13TeV_Pow_Herwig7_cfg.py
```

# Making a gridpack
## First, build powheg, following the steps above

## Make the MC sampling grids
### From outside the CC7 container:
```
python3 ./run_pwg_parallel_condor.py -p 123 -i ../LQPrivateGen/powheg/inputNLO/powheg.input-save-NLO-cmssw-LQToDEle_M-1000 -m LQ-s-chan -f LQ-s-chan-nlo-dele-1000 -x 5 -q 1:longlunch,2:longlunch,3:tomorrow -j 10
```

### To check job status
```
condor_q -dag -nobatch
```

### Once jobs are done, check dagman file for errors:
```
less *.dagman.out
```

### Run the modified reweight script
```
cd LQ-s-chan-nlo-dele-1000
python3 ../../LQPrivateGen/scripts/make_rwl.py 1 82400 0 0 Run2UL
cd ..
```

### Make tarball
```
python3 ./run_pwg_condor.py -p 9 -i ../LQPrivateGen/powheg/inputNLO/powheg.input-save-NLO-cmssw-LQToDEle_M-1000 -m LQ-s-chan -f LQ-s-chan-nlo-dele-1000
```

## Test
```
mkdir /tmp/testing
cd /tmp/testing
tar -xzf [tarballCreatedAbove]
./runcmsgrid.sh 10 1 1 > runPowheg.log
```
Check the output for errors.

## Generate the number of LHE events you want
### Inside the untagged gridpack (same as above)
```
./runcmsgrid.sh [events desired] 1 1 > runPowheg.log
```

