#!/bin/bash

RUNPWD=${PWD}
SCRIPTDIR="$( cd "$( dirname "$0" )" && pwd )"
LQPROCESS=LeptonInducedLQ_uele
INPUTPOWHEG=${SCRIPTDIR}/../powheg/inputNLO/powheg.input-NLO-LQToUEle_M-1000
#Mass=( 1000 1500 2000 2500 3000 )
#Y=(1p0 2p0 3p0)
#Mass=( 600 800 1000 1200 1400 1600 2000 )
#Y=(0p5 1p0 1p5 2p0 3p0)
#Mass=( 2000 )
Y=( 1p0 )
Mass=( 1000 )

#Y=( 0p1 0p2 0p5 1p0 1p5 2p0 3p0 )

OUTPUTDIRBASE=/eos/cms/store/group/phys_exotica/leptonsPlusJets/LQ/scooper/leptonInduced/signalGen/powhegLHE
evts=100000
evtsperfile=20000

echo "Generating ${evts} events per mass/coupling. Will split into ${evtsperfile} events per LHE file"

for m in "${Mass[@]}"
do 
  echo "mass=${m}"
	for i in "${Y[@]}"
	do
	  LQNAME=${LQPROCESS}_M${m}_Lambda${i}
		LQDIR=/tmp/${USER}/${LQNAME}
		mkdir -p $LQDIR
    OUTPUTDIR=${OUTPUTDIRBASE}/${LQNAME}
		mkdir -p ${OUTPUTDIR}
		cp $INPUTPOWHEG $LQDIR/powheg.input
	  #cp weights.xml $LQDIR/.
		sed -i "s/^numevts.*/numevts ${evts} ! number of events to be generated/" $LQDIR/powheg.input
		sed -i "s/^mLQ .*/mLQ ${m}/" $LQDIR/powheg.input
		lambda=$(echo "${i}" | sed "s/p/./" )
		echo -n "    lambda=${lambda}"	
		sed -i "s/^y_1e.*/y_1e ${lambda}/" $LQDIR/powheg.input
		cd /tmp/${USER}/${LQNAME}
		${RUNPWD}/pwhg_main > ${LQNAME}.log
		mv pwgevents.lhe ${LQNAME}.lhe
		echo "    split LHE files and copy to ${OUTPUTDIR}; list in ${LQNAME}.list"	
		python ${SCRIPTDIR}/split_LHE.py -i ${LQDIR}/${LQNAME}.lhe -o ${LQDIR}/split -n ${evtsperfile}		
    mv ${LQDIR}/split/*mod*.lhe ${OUTPUTDIR}
    listFile=${RUNPWD}/${LQNAME}.list
    rm -f ${listFile}
    for f in `/usr/bin/ls ${OUTPUTDIR}/*.lhe `; do
      # echo "root://eoscms.cern.ch/${f}" >> ${listFile}
      echo ${f}" >> ${listFile}
    done
	done 
done
