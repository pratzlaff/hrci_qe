#import numarray
import math

set_xsabund("wilm")
set_xsxsect("vern")

g21_obs=0.541
g21_obs_err=0.008

casA_obs=0.0312
casA_obs_err=0.0036

load_pha(1, "/data/neo/HRCI_QE_Jan10/G21.5-0.9/pha.fits")
load_arf(1, "/data/neo/HRCI_QE_Jan10/G21.5-0.9/caldb_arf.fits")
load_rmf(1, "/data/CALDB/ciao/data/chandra/hrc/rmf/hrciD1999-07-22samprmfN0001.fits")

load_pha(2, "/data/neo/HRCI_QE_Jan10/CasA/Hrc/pha.fits")
load_arf(2, "/data/neo/HRCI_QE_Jan10/CasA/Hrc/caldb_arf.fits")
load_rmf(2, "/data/CALDB/ciao/data/chandra/hrc/rmf/hrciD1999-07-22samprmfN0001.fits")

set_source(1,(xstbabs.abs1*xspegpwrlw.p1)*(xsstep.s1 - xsstep.s2 + xsstep.s3 + xsconstant.c1))

# G21.5-0.9 parameters from ACIS-S3 fit
abs1.nH=3.23466
p1.PhoIndex=1.79686
p1.eMin=2.0
p1.eMax=8.0
p1.norm=54.9971 

g21_pred_err=0.03 # ~3% error

set_source(2,(xstbabs.abs2*xspegpwrlw.p2)*(s1 - s2 + s3 + c1))

# Cas A parameters: avg of ACIS I3 and S3 fits
abs2.nH=3.2
p2.PhoIndex=4.0
p2.eMin=1.0
p2.eMax=5.0
p2.norm=3.02

casA_pred_err=0.2 # ~20% error

# note: need to change value of offset if these numbers change
s1.Energy=2.0
s2.Energy=1.0
s3.Energy=3.0

s1.Sigma=0.5
s2.Sigma=0.5
s3.Sigma=0.5

f1=-0.999937 # erf(-e1/(sqrt(2)*s1)) for e1=3,s1=0.5
f2=-0.9545 # erf(-e2/(sqrt(2)*s2)) for e2=1,s2=0.5
f3=-1.0 # erf(-e3/(sqrt(2)*s3)) for e3=5,s3=0.5

#norm1=range(100)
#norm3=range(100)

#g21_pred=zeros([100,100],Float)
#casA_pred=zeros([100,100],Float)

out = open('adjust_qe_out.txt', 'w')
out.write('# norm1   norm2  g21_pred   casA_pred   g21_diff   casA_diff   g21_chisq   casA_chisq\n')


# test norm values from 0 to 1
for i in range(100):
    n1=i/100. 
    n2=n1
#    norm1[i]=n1
    for j in range(100):
        n3=j/100.
#        norm3[j]=n3
        s1.norm=n1
        s2.norm=n2
        s3.norm=n3
        offset=1.0-((n1/2.0)*(1.0-f1) - (n2/2.0)*(1.0-f2) + (n3/2.0)*(1.0-f3))
        if offset > 0:
            c1.factor=offset

            g21_pred=calc_model_sum(id=1)/get_exposure(id=1)
            casA_pred=calc_model_sum(id=2)/get_exposure(id=2)

            g21_diff=(g21_pred - g21_obs)/g21_obs
            casA_diff=(casA_pred - casA_obs)/casA_obs
            casA_chisq=(casA_pred - casA_obs)**2/(casA_obs_err**2 + casA_pred_err**2)
            g21_chisq=(g21_pred - g21_obs)**2/(g21_obs_err**2 + g21_pred_err**2)

            line=str(round(n1,2))+' '+str(round(n3,2))+' '+str(round(g21_pred,6))+' '+str(round(casA_pred,6))+' '+str(round(g21_diff,4))+' '+str(round(casA_diff,4))+' '+str(round(g21_chisq,4))+' '+str(round(casA_chisq,4))+'\n'
        else:
            line=str(n1)+' '+str(n3)+' '+str(999)+' '+str(999)+' '+str(999)+' '+str(999)+' '+str(999)+' '+str(999)+'\n'
        out.write(line)

out.close()
        
