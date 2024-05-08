close,/all

orig=mrdfits('hrciD1999-07-22qeN0007.fits',1,h)

repst=mrdfits('hrciD1999-07-22qeN0007prime_renorm.fits',1,h)

x=repst.energy

n=0.099
e=0.35
w=0.1
c=1.0 - (n/2.0)*(1.0 - erf((0.0-e)/(sqrt(2.0)*w)))

f=(n/2.0)*(1.0-erf((x-e)/(sqrt(2.0)*w))) + c


peasecolr,white=white
set_plot,'ps'
!p.thick=5
!x.thick=5
!y.thick=5
!p.charsize=1.5
!x.charsize=1
!y.charsize=1
!p.charthick=5

device,filename="renormalization_function.ps",/landscape,/color

plot,x,f,/xs,/ys,xr=[0.06,10.],yr=[0.85,1.05],/xl,xtitle="Energy [keV]",ytitle="Adjustment Value",title="Renormalization of HRC-I QE Model"
oplot,repst.energy,repst.energy*0.0+1.0,linestyle=1
;xyouts,0.1,1.03,'Function applied to "repaste" model to get N0008'
device,/close

newqe=repst.qe

new=repst

newqe *= f

new.qe = newqe

;mwrfits,new,'hrciD1999-07-22qeN0008.fits',h,/create


device,filename="model_comparision.ps",/landscape,/color

plot,new.energy,new.qe,/xs,/ys,xr=[0.06,10.0],/xl,xtitle="Energy [keV]",ytitle="QE",title="Comparision of HRC-I QE Models",/nodata,yr=[0.0,0.4]
oplot,orig.energy,orig.qe,col=0
;oplot,repst.energy,repst.qe,col=1
oplot,new.energy,new.qe,col=2
legend,['NOOO7','NOOO8'],col=[0,2],linestyle=[0,0],box=0,/top,/right
;legend,['NOOO7','repaste','NOOO8'],col=[0,1,2],linestyle=[0,0,0],box=0,/top,/right
device,/close

device,filename="model_ratio.ps",/landscape,/color

plot,new.energy,new.qe/new.qe,/xs,/ys,xr=[0.06,10.0],yr=[-.5,.8],/xl,xtitle="Energy [keV]",ytitle="(N0008-N0007)/N0007",title="Comparision of HRC-I QE Models",/nodata
oplot,repst.energy,repst.energy*0.0,linestyle=1,col=0
;oplot,repst.energy,(repst.qe-orig.qe)/orig.qe,col=1
oplot,new.energy,(new.qe-orig.qe)/orig.qe,col=2
;legend,['repaste','NOOO8'],col=[1,2],linestyle=[0,0],box=0,/top,/right
device,/close

stop
return
end
