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

## Launch CC7 container
```
cmssw-cc7
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

### Test
```
mkdir /tmp/testing
cd /tmp/testing
tar -xzf [tarballCreatedAbove]
./runcmsgrid.sh 10 1 1 > runPowheg.log
```
Check the output for errors.


