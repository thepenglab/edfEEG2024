%remove big noise
function dat=clipNoise(dat,th)
th2=mean(dat)+6*std(dat);
th=min(th,th2);
dat(abs(dat)>th)=0;