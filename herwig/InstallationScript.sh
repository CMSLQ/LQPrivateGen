# Herwig + POWHEG analysis interface for lepton initiated processes
# The following should work on a linux system
# (this has been tested on a MacOs system and, so far, it does not work) 

# 1) Installation of ThePeg 2.2 from mercurial repository  (from Peter's email)

# $ hg clone https://phab.hepforge.org/source/thepeghg ThePEG

sss=`which hg`

if ! hg > /dev/null 2>&1
then
    echo "You must install mercurial"
    exit 1
fi

if ! autoreconf --help > /dev/null 2>&1
then
    echo "You must install autoreconf"
    echo " on a mac: brew install automake"
    exit 1
fi

if ! glibtoolize --help  > /dev/null 2>&1 | libtoolize --help > /dev/null 2>&1
then
    echo "You must install libtool"
    echo " on a mac: brew install libtool"
    exit 1
fi

if ! gsl-config --prefix   > /dev/null
then
    echo "You must install gsl"
    echo "on a mac: brew install gsl"
    exit 1
fi

if ! gengetopt  --help > /dev/null
then
    echo " must install gengetopt, needed by Herwig"
    exit 1
fi 

#if ! locate libHepMC.so   > /dev/null
#then
#    echo "You must install hepmc"
#    echo "on ubuntu do: sudo apt-get install libhepmc-dev"
#fi

PWD=`pwd`

INSTPATH=$PWD

#if [ -d ThePEG ]
#then
#    echo Remove previous ThePEG directory
#    \rm -rf ThePEG
#fi
#
#echo hg clone https://phab.hepforge.org/source/thepeghg ThePEG
#hg clone https://phab.hepforge.org/source/thepeghg ThePEG
#
#echo cd ThePEG
#cd ThePEG
#echo hg up release-2-2
#hg up release-2-2
#echo autoreconf -vi
#autoreconf -vi
#
#if ! ./configure --prefix=$INSTPATH --with-hepmc 
#then
#    echo configure fail
#    exit 1
#fi
#
#make
#
#make install

# 2) Installation of Herwig 7.2.2 from mercurial repository (from Peter's email)

cd $PWD

echo "********** Herwig installation ***********"

#if ! ./configure --prefix=$INSTPATH --with-hepmc 
#then
#    echo configure fail
#    exit 1
#fi

echo hg clone https://phab.hepforge.org/source/herwighg Herwig

if [ -d Herwig ]
then
    echo Remove previous Herwig directory
    \rm -rf Herwig
fi

echo hg clone https://phab.hepforge.org/source/herwighg Herwig
hg clone https://phab.hepforge.org/source/herwighg Herwig

echo changing directory to Herwig
cd Herwig

echo hg up herwig-7-2
hg up herwig-7-2

echo autoreconf  -vi
autoreconf  -vi


# - then usual ./configure && make && install
#if ! ./configure --prefix=$INSTPATH --with-thepeg=$INSTPATH
#if ! ./configure --prefix=$INSTPATH --with-thepeg=/cvmfs/sft.cern.ch/lcg/releases/LCG_99/MCGenerators/thepeg/2.2.1/x86_64-centos7-gcc8-opt --with-gsl=/cvmfs/sft.cern.ch/lcg/views/LCG_99/x86_64-centos7-gcc8-opt --with-boost=/cvmfs/sft.cern.ch/lcg/releases/LCG_99/Boost/1.73.0/x86_64-centos7-gcc8-opt --with-hepmc=/cvmfs/sft.cern.ch/lcg/releases/LCG_99/HepMC/2.06.11/x86_64-centos7-gcc8-opt --with-evtgen=/cvmfs/sft.cern.ch/lcg/releases/LCG_99/MCGenerators/evtgen/2.0.0/x86_64-centos7-gcc8-opt
#for CMSSW_10_6_28 (Paolo)
if ! ./configure --prefix=$INSTPATH --with-thepeg=/cvmfs/cms.cern.ch/slc7_amd64_gcc820/external/thepeg/2.2.2 --with-gsl=/cvmfs/cms.cern.ch/slc7_amd64_gcc820/external/gsl/2.2.1-pafccj2 --with-boost=/cvmfs/cms.cern.ch/slc7_amd64_gcc820/external/boost/1.67.0-pafccj --with-hepmc=/cvmfs/cms.cern.ch/slc7_amd64_gcc820/external/hepmc/2.06.07-pafccj --with-evtgen=/cvmfs/cms.cern.ch/slc7_amd64_gcc820/external/evtgen/1.6.0-pafccj7
then
    echo Herwig configuration failed
    exit -1
fi

#Luca Buonocore, allow non-zero transverse momentum for initial state photons 
#(comment out line 506, ( if(!particlesToShower[ix]->progenitor()->dataPtr()->coloured()) continue; ) inside function void QTildeShowerHandler::generateIntrinsicpT)
echo cp ../QTildeShowerHandler.cc Shower/QTilde/
cp ../QTildeShowerHandler.cc Shower/QTilde/


if ! make
then
    echo make failed
    exit -1
fi

make install

# Remarks:
# - if the ThePeg installation is not found automatically, add the following flag
# $ ./configure --prefix=path_installation --with-thepeg=path_to_thepeg_installation
# - your LHAPDF installation must contain CT14lo and CT14nlo pdfsets
# # -*-Paolo-*-   Added by Paolo:
# # -*-Paolo-*-   $ ./configure --prefix=path_installation --with-gsl=/home/nason/Pheno/Herwig7.2.1-inst/ --with-boost=/home/nason/Pheno/Herwig7.2.1-inst/  --with-lhapdf=/home/nason/Pheno/PDFpacks/LHAPDF-6.2.3-installed/share/LHAPDF
# # -*-Paolo-*-   here I point to my installation of LHAPDF with the lepton PDF's.
# # -*-Paolo-*-   If you have gls already installed the gsl line is not needed, same if you have the right version of boost installed.

# - Add path_installation/bin/ to your PATH

# 3) HepMC2 is required
# - if not available, get the latest one at http://hepmc.web.cern.ch/hepmc/
# and follow their instructions for compiling it. 


# 3) Compile the POWHEG-Herwig interface by Silvia and Tomas
# - Modify the available Makefile in the obvious way ( update paths for the  BOX folder, the process folder and the
# analysis source and add customary dependeces if required, check the paths to ThePeg, Herwig and HepMC)
# - compile
# $ make

# - This generates the dynamic library powhegHerwig.so

# 4) Run Shower+Analysis 
# - Create a folder (lets say testrun) with the powheginput file and the lhe events. The dynamic library powhegHerwig.so
# must be in ../testrun
# - Copy into the folder the new Herwig.in  template and
# the hw7.sh shell script (modified version  under herwig-mod directory).
# - Modify the number of events to be generated in the Herwig.in file
# set EventGenerator:NumberOfEvents 20000 -> set EventGenerator:NumberOfEvents XXX
# and check the name of PDF. 

# - To run
# $ ./hw7.sh
# from testrun directory

