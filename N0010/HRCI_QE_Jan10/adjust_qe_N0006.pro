close,/all

center=findgen(200)/100. + 0.2
norm=findgen(500)/1000. 
w=0.1

g21_obs=5.41e-1
g21_obs_err=0.08e-1

hz_obs=3.88
hz_obs_err=0.07

pks_obs=1.537
pks_obs_err=0.014

g21_pred=fltarr(n_elements(center),n_elements(norm))
g21_pred_err=fltarr(n_elements(center),n_elements(norm))

pks_pred=fltarr(n_elements(center),n_elements(norm))
pks_pred_err=fltarr(n_elements(center),n_elements(norm))

hz_pred=fltarr(n_elements(center),n_elements(norm))
hz_pred_err=fltarr(n_elements(center),n_elements(norm))

chisq=fltarr(n_elements(center),n_elements(norm))

; hz43
restore,'/data/neo/HRCI_QE_Jan10/HZ43/hrcs_hz43_N0006prime.sav'

; pks2155
restore,'/data/neo/HRCI_QE_Jan10/PKS2155/3716/pks_model_N0006prime.sav'

; g21.5-0.9
readcol,'/data/neo/HRCI_QE_Jan10/G21.5-0.9/model.txt',e,de,f,skip=3
g21_arf=mrdfits('/data/neo/HRCI_QE_Jan10/G21.5-0.9/hrci_arf_N0006prime.fits',1,h)
g21_nrg=(g21_arf.energ_lo + g21_arf.energ_hi)/2.0
g21_mod=interpol(f*de,e,g21_nrg)

for i=0,n_elements(center)-1L do begin

   e=center[i]

   for j=0,n_elements(norm)-1L do begin

      n=norm[j]
      
      c=1.0 - (n/2.0)*(1.0 - erf((e-e)/(sqrt(2.0)*w)))
      
      ;hz43
      x=s_nrg
      f=(n/2.0)*(1.0-erf((x-e)/(sqrt(2.0)*w))) + c
      tmp=fltarr(nobs)
      for k=0,nobs-1 do begin
         pred=mod_avg_ind[k,good]*arf_i_int*f
         tmp[k]=total(pred,/nan)
      endfor
      hz_pred[i,j]=mean(tmp)
      hz_pred_err[i,j]=stddev(tmp)

      ; pks2155
      x=pks_nrg
      f=(n/2.0)*(1.0-erf((x-e)/(sqrt(2.0)*w))) + c
      tmp=fltarr(pks_nobs)
      for k=0,pks_nobs-1 do begin
         pred=pks_mod[k,pks_good]*pks_i_arf*f
         tmp[k]=total(pred,/nan)
      endfor

      pks_pred[i,j]=mean(tmp)
      pks_pred_err[i,j]=stddev(tmp)
 
      ; g21.5-0.9
      x=g21_nrg
      f=(n/2.0)*(1.0-erf((x-e)/(sqrt(2.0)*w))) + c
      g21_pred[i,j]=total(2.0*g21_mod*f*g21_arf.specresp)
      g21_pred_err[i,j]=0.03*g21_pred[i,j]
      
      chisq[i,j]=( $
     (g21_obs-g21_pred[i,j])^2/(g21_obs_err^2+g21_pred_err[i,j]^2) $
    + (pks_obs-pks_pred[i,j])^2/(pks_obs_err^2+pks_pred_err[i,j]^2)$
    + (hz_obs-hz_pred[i,j])^2/(hz_obs_err^2+hz_pred_err[i,j]^2) )

;
;      chisq[i,j]=( $
;     (g21_obs-g21_pred[i,j])^2/(g21_obs_err^2) $
;    + (pks_obs-pks_pred[i,j])^2/(pks_obs_err^2)$
;    + (hz_obs-hz_pred[i,j])^2/(hz_obs_err^2) )

   endfor
endfor


save,chisq,norm,center,g21_pred,g21_pred_err,pks_pred,pks_pred_err,hz_pred,hz_pred_err,filename="adjust_qe_N0006.sav"

print,"min chisq: ",min(chisq)

ind=where(chisq eq min(chisq))
tmp=array_indices(chisq,3935)

print,"center: ",center[tmp[0]]
print,"norm: ",norm[tmp[1]]

print,"g21 pred: ",g21_pred[tmp[0],tmp[1]],' ',100.*(g21_pred[tmp[0],tmp[1]]-g21_obs)/g21_obs,'%'
print,"pks pred: ",pks_pred[tmp[0],tmp[1]],' ',100.*(pks_pred[tmp[0],tmp[1]]-pks_obs)/pks_obs,'%'
print,"hz43 pred: ",hz_pred[tmp[0],tmp[1]],' ',100.*(hz_pred[tmp[0],tmp[1]]-hz_obs)/hz_obs,'%'


stop
return
end
