#! /usr/bin/env python

import os
import sys
import optparse
import datetime
import subprocess
import io

from glob import glob

usage = "usage: python split_LHE.py -i SingleLQ_ueLQue_M2000_Lambda1p0/SingleLQ_ueLQue_M2000_Lambda1p0.lhe -o /afs/cern.ch/work/s/santanas/Workspace/CMS/LQGen/TEST_1 -n 1000"

parser = optparse.OptionParser(usage)

parser.add_option("-i", "--inputfile", dest="inputfile",
                  help="input LHE file")

parser.add_option("-o", "--output", dest="outputdir",
                  help="the directory contains the output of the program. Can be AFS or EOS directory.")

parser.add_option("-n","--nEventsPerFile", dest="nEventsPerFile", type=int,
                  help="number of events for each file",
                  default=-1)
parser.add_option("-v","--verbose", dest="verbose", action="store_true",
                  default=False)


(opt, args) = parser.parse_args()

if not opt.inputfile:   
    parser.error('input file not provided')

if not opt.outputdir:   
    parser.error('output dir not provided')

verbose = opt.verbose
################################################

# create outputdir
lhefilename = ((opt.inputfile).split("/")[-1]).split(".")[0]
if verbose:
    print (lhefilename)

if verbose:
    print ("mkdir -p "+opt.outputdir)
os.system("mkdir -p "+opt.outputdir)

# Count number of events in LHE 
nevTot = 0
for line in open(opt.inputfile,'r'):
    if '<event>' in line:
        nevTot += 1

if (opt.nEventsPerFile == -1):
    opt.nEventsPerFile = nevTot

if verbose:
    print ("Number of events per file: ", opt.nEventsPerFile)


# Find start of lhe file
nameFileStart="fileStart.txt"
fileStart = open(nameFileStart,'w')
for line in open(opt.inputfile,'r'):
    if '<event>' in line:
        break
    fileStart.write(line)
fileStart.close()

# Find end of lhe file
nEnd=0
nameFileEnd="fileEnd.txt"
fileEnd = open(nameFileEnd,'w')
for line in open(opt.inputfile,'r'):
    if (nEnd == nevTot):
        fileEnd.write(line)
    if '</event>' in line:
        nEnd += 1
fileEnd.close()

# Split LHE file
nevtmp = 0
nev = 0 
nfile = 1
evtStart = False
currentfilename = None
currentfile = None

for line in open(opt.inputfile,'r'):

    if(nev == nevTot):
        currentfile.close()
        break;

    if(nevtmp == opt.nEventsPerFile):        
        nfile+=1
        nevtmp=0
        currentfile.close()

    #currentline = "===> nfile="+str(nfile)+" nevtmp="+str(nevtmp)+" "+line
    currentline = line

    if '<event>' in line:
        evtStart = True

    if evtStart:

        if(nevtmp == 0 and ('<event>' in line) ):
            #print (currentline)
            currentfilename = lhefilename+"__"+str(nfile)+".lhe"
            if verbose:
                print ("creating a new file: ", currentfilename)
            currentfile = open(opt.outputdir+"/"+currentfilename,'w')

        currentfile.write(currentline)

        if '</event>' in line:
            nevtmp += 1
            nev += 1
            evtStart = False

if verbose:
    print ("Original LHE file split into "+str(nfile)+" files")

namelistlhe = opt.outputdir+"/"+lhefilename+".list"
namelistlhemod = opt.outputdir+"/"+lhefilename+"_mod.list"
listlhe = open(namelistlhe,"w")
listlhemod = open(namelistlhemod,"w")

for k in range(1,nfile+1):
    if verbose:
        print("cat "+nameFileStart+" "+opt.outputdir+"/"+lhefilename+"__"+str(k)+".lhe"+" "+nameFileEnd+" >> tmp_"+str(k)+".lhe")
    os.system("cat "+nameFileStart+" "+opt.outputdir+"/"+lhefilename+"__"+str(k)+".lhe"+" "+nameFileEnd+" >> tmp_"+str(k)+".lhe")
    if verbose:
        print("mv tmp_"+str(k)+".lhe"+" "+opt.outputdir+"/"+lhefilename+"__"+str(k)+".lhe")
    os.system("mv tmp_"+str(k)+".lhe"+" "+opt.outputdir+"/"+lhefilename+"__"+str(k)+".lhe")
    listlhe.write(opt.outputdir+"/"+lhefilename+"__"+str(k)+".lhe"+"\n")

    #Edit LHE file (from Cecile's code)
    fin = open(opt.outputdir+"/"+lhefilename+"__"+str(k)+".lhe", "rt")
    #output file to write the result to
    fout = open(opt.outputdir+"/"+lhefilename+"_mod__"+str(k)+".lhe", "wt")
    #for each line in the input file
    i=-1

    for line in fin:
        #read replace the string and write to output file
        if '#------------------------------------------------' in line:
            fout.write(line.replace('#------------------------------------------------', '#'))
        elif '<weights>' in line:
            fout.write(line.replace('<weights>', '<rwgt>'))
            i=0
        elif '</weights>' in line:
            fout.write(line.replace('</weights>', '</rwgt>'))
            i=-1
        elif i>=0:
            i=i+1
            if i==1 : fout.write("<wgt id='101'> " + line.rstrip('\n') + " </wgt> \n")
            elif i==2 : fout.write("<wgt id='102'> " + line.rstrip('\n') + " </wgt> \n")
            elif i==3 : fout.write("<wgt id='103'> " + line.rstrip('\n') + " </wgt> \n")
            elif i==4 : fout.write("<wgt id='104'> " + line.rstrip('\n') + " </wgt> \n")
            elif i==5 : fout.write("<wgt id='105'> " + line.rstrip('\n') + " </wgt> \n")
            elif i==6 : fout.write("<wgt id='106'> " + line.rstrip('\n') + " </wgt> \n")
            elif i==7 : fout.write("<wgt id='107'> " + line.rstrip('\n') + " </wgt> \n")
            else : fout.write("<wgt id='"+str(i-8)+"'> " + line.rstrip('\n') + " </wgt> \n")
        else:
            fout.write(line)
    #close input and output files
    fin.close()
    fout.close()
    listlhemod.write(opt.outputdir+"/"+lhefilename+"_mod__"+str(k)+".lhe"+"\n")

listlhe.close()
listlhemod.close()

# clean
os.system("rm -f "+nameFileStart)
os.system("rm -f "+nameFileEnd)
