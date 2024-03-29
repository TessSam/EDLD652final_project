#******************************************************************************************************
#LetDriftGo

#******************************************************************************************************
#Removing evrything from workspace
rm(list = ls(all = TRUE))

#Setting up directory
# /Users/useruser/Dropbox/w_ONGOINGRFILES
Dir_R<-path.expand("~/Dropbox/w_ONGOINGRFILES/w_OTHERS")
Dir_Figure<-path.expand("~/Dropbox/w_ONGOINGRFILES/Graphs/Graphs")
Dir_Data<-path.expand("C:/Users/Tess/Dropbox/sharedprojects/P.LetDriftGo_series/LetDriftGo_expectation/Data")

# Libraries
library(foreign)
library(dplyr)
library(tidyr)
library(gridExtra)
library(ggplot2)
library(lme4)
library(RColorBrewer)
library(corrplot)
library(gee)
library(ez)
library(effects)

# Source Files
# setwd(Dir_R)
# source('basic_lib.R')

#======================================================================================================
#Process1-Data Reading
#======================================================================================================

# READING FILES
setwd(Dir_Data)#Change directory
Beh_Tx <- read.delim('LetDriftGo_expcCue_BehP.txt', header=TRUE, fill=TRUE)
ds<-Beh_Tx;

#Add trial grouping variable 
ds$BTRIAL = (max(ds$TRIAL)*ds$BLOCK-1)+ds$TRIAL

#Add category as correct answer
ds$Category<-ds$CATEGORY;
ds$Category[ds$Category==2]<-0;
ds$Category<-as.integer(ds$Category)

# # Cue-driven expectancy context
ds$CUETYPE<-dplyr::recode(ds$CUETYPE, `1` = "valid", `0` = "invalid")
ds$CUECATb<-ds$CUECAT;ds$CUECATb[ds$CUECATb==2]<--1

# Checking
# any(ds$CUECAT[ds$DVCP2CUE_1==1]==ds$DVCAT_1[ds$DVCP2CUE_1==1])

# #Evidence-driven expectancy

# Factorize
cols<-colnames(ds)
cols<-cols[grepl("DVCP2CUE",cols)]
ds[cols] <- lapply(ds[cols], factor)

# Exclude subjects
ds<-subset(ds,SUBID!=228 & SUBID!=231)

# PGROUP (1 = high performer 0 = low performer)
ds<-ds%>%group_by(SUBID)%>%summarize(ACC=mean(ACC))%>%
  mutate(PGROUP=as.numeric(ACC>median(ACC)))%>%
  dplyr::select(c(SUBID,PGROUP))%>%
  left_join(ds,by=("SUBID"))

# Aggregate and run ANOVA
# agg<-aggregate(ACC~SUBID+CUETYPE, data = ds, mean);
# ezANOVA(agg, dv=ACC, wid = SUBID,within=CUETYPE)


#======================================================================================================
#Process2-Behavior
#======================================================================================================
# Seperate group for later use

#Checking accuracy
acc_all<-aggregate(ACC ~ SUBID, data = ds, mean);print((acc_all))

# ACC:Cue efffect
# agg<-aggregate(ACC~SUBID+CUETYPE, data = ds, mean);
# aggG<-aggregate(ACC~CUETYPE, data = agg, mean);
acc_exp<-ds %>% group_by(SUBID,CUETYPE) %>% summarise(ACC=mean(ACC))%>%
  group_by(CUETYPE) %>% summarise_each(funs(mean,se=sd(.)/sqrt(n())),ACC)

# RT:Cue effect
# agg<-aggregate(RT~SUBID+CUETYPE, data = ds, mean)
# aggG<-aggregate(RT~CUETYPE, data = agg, mean);
rt_exp<-ds %>% group_by(SUBID,CUETYPE) %>% summarise(RT=mean(RT))%>%
  group_by(CUETYPE) %>% summarise_each(funs(mean,se=sd(.)/sqrt(n())),RT)

# Check individuals accuracy
acc_ind<-ds %>% group_by(SUBID,CUETYPE) %>% summarise(ACC=mean(ACC));print(acc_ind) 
cor(acc_ind$ACC[acc_ind$CUETYPE=="valid"],acc_ind$ACC[acc_ind$CUETYPE=="invalid"])
plot(acc_ind$ACC[acc_ind$CUETYPE=="valid"],acc_ind$ACC[acc_ind$CUETYPE=="invalid"])

#======================================================================================================
#Process2-Modeling
#======================================================================================================

# DV normal
m2_log_y=glmer(PCARD~1+DV_1+DV_2+DV_3+DV_4+(1|SUBID),family=binomial,data=ds)
# m2_log_o=glmer(PCARD~1+DV_1+DV_2+DV_3+DV_4+(1|SUBID),family=binomial,data=ds_old)
summary(m2_log_y)
summary(m2_log_c)

# DV expectacy (coarse way)
m2_exp_v=glmer(PCARD~1+(DV_1+DV_2+DV_3+DV_4)+(1|SUBID),family=binomial,data=subset(ds,CUETYPE=="valid"))
m2_exp_iv=glmer(PCARD~1+(DV_1+DV_2+DV_3+DV_4)+(1|SUBID),family=binomial,data=subset(ds,CUETYPE=="invalid"))
summary(m2_exp_v)
summary(m2_exp_iv)

# DV expectacy (element-wise focusing on matching trials!)
# DVCP2CUE (0=incongruent 1 = congruent)
m2_expcmp=glmer(PCARD~1+(DV_1*DVCP2CUE_1+DV_2*DVCP2CUE_2+DV_3*DVCP2CUE_3+DV_4*DVCP2CUE_4)+(1|SUBID),family=binomial,data=ds)
m2_expcmp_v=glmer(PCARD~1+(DV_1*DVCP2CUE_1+DV_2*DVCP2CUE_2+DV_3*DVCP2CUE_3+DV_4*DVCP2CUE_4)+(1|SUBID),family=binomial,data=subset(ds,CUETYPE=="valid"))
m2_expcmp_iv=glmer(PCARD~1+(DV_1*DVCP2CUE_1+DV_2*DVCP2CUE_2+DV_3*DVCP2CUE_3+DV_4*DVCP2CUE_4)+(1|SUBID),family=binomial,data=subset(ds,CUETYPE=="invalid"))
summary(m2_expcmp)
summary(m2_expcmp_v)
summary(m2_expcmp_iv)     

# DV expectacy (element-wise focusing on matching trials!) 2-way interactions
# DVCP2CUE (0=incongruent 1 = congruent)
m2_expcmp=glmer(PCARD~1+(DV_1+DV_2+DV_3+DV_4)+(DV_1:DVCP2CUE_1+DV_2:DVCP2CUE_2+DV_3:DVCP2CUE_3+DV_4:DVCP2CUE_4)+(1|SUBID),family=binomial,data=ds)
m2_expcmp_v=glmer(PCARD~1+(DV_1+DV_2+DV_3+DV_4)+(DV_1:DVCP2CUE_1+DV_2:DVCP2CUE_2+DV_3:DVCP2CUE_3+DV_4:DVCP2CUE_4)+(1|SUBID),family=binomial,data=subset(ds,CUETYPE=="valid"))
m2_expcmp_iv=glmer(PCARD~1+(DV_1+DV_2+DV_3+DV_4)+(DV_1:DVCP2CUE_1+DV_2:DVCP2CUE_2+DV_3:DVCP2CUE_3+DV_4:DVCP2CUE_4)+(1|SUBID),family=binomial,data=subset(ds,CUETYPE=="invalid"))
summary(m2_expcmp)
summary(m2_expcmp_v)
summary(m2_expcmp_iv)  
plot(allEffects(m2_expcmp_v))       

# Cue-expectancy 
# DVCP2CUE (0=incongruent 1 = congruent)
m2_expcmp=glmer(PCARD~1+CUECATb+(DV_1+DV_2+DV_3+DV_4)+(DV_1:DVCP2CUE_1+DV_2:DVCP2CUE_2+DV_3:DVCP2CUE_3+DV_4:DVCP2CUE_4)+(1|SUBID),family=binomial,data=subset(ds,PGROUP==0))
summary(m2_expcmp)
plot(allEffects(m2_expcmp)) 


#Deviation from last evidence
m=glmer(PCARD~1+CUECATb+(DV_1+DV_2+DV_3+DV_4)+
          (DV_1:DVCP2CUE_1+DV_2:DVCP2CUE_2+DV_3:DVCP2CUE_3+DV_4:DVCP2CUE_4)+
          (DV_2:DUab_2+DV_3:DUab_3+DV_4:DUab_4)+
          (DV_2:DVCP2CUE_2:DUab_2+DV_3:DVCP2CUE_3:DUab_3+DV_4:DVCP2CUE_4:DUab_4)+
          (1|SUBID),family=binomial,data=ds)
summary(m)

# Others
m=glmer(PCARD~1+CUECATb+(DV_1+DV_2+DV_3+DV_4)+
          (DV_1:DVCP2CUE_1+DV_2:DVCP2CUE_2+DV_3:DVCP2CUE_3+DV_4:DVCP2CUE_4)+
          (DV_2:DVCP2CUE_1+DV_3:DVCP2CUE_2+DV_4:DVCP2CUE_3)+(1|SUBID),family=binomial,data=ds)
summary(m)
#======================================================================================================
#Process3-Plotting-ggplot2
#======================================================================================================
CSCALE_PURD = rev(brewer.pal(9,"PuRd"));
CSCALE_BLUE = rev(brewer.pal(9,"Blues"));
CSCALE_PiYG = rev(brewer.pal(11,"PiYG"));
CSCALE_RdBu = rev(brewer.pal(11,"RdBu"));
CSCALE_PAIRED = rev(brewer.pal(12,"Paired"));
CSCALE_YlGnBu = rev(brewer.pal(9,"YlGnBu"));
CSCALE_BrBG = rev(brewer.pal(9,"BrBG"));
CSCALE_Greys = rev(brewer.pal(9,"Greys"));
CSCALE_Set1 = (brewer.pal(9,"Set1"));
CSET_AGE<-c(CSCALE_PAIRED[6],CSCALE_PAIRED[5])

#Add referece line data 
theme_set(theme_bw(base_size = 18))#32/28


a<-allEffects(m2_expcmp)

#format data for plots
m<-summary(m2_expcmp)
coefs<-fixef(m2_expcmp);
coefs<-c(coefs[2:5],coefs[2:5]+coefs[6:9]);
cond<-c(rep("incongruent",1,4),rep("congruent",1,4));
EVnum<-rep(seq(1,4,1),2);stde<-rep(NA,1,8);#stde<-m$coefficients[2:13,2]
ds_p<-data.frame(Estimate=c(coefs),cmp=cond,stderr=stde,EVnum=EVnum)

# # Decision Weights
quartz(width=5,height=4)
plot3<- ggplot(ds_p, aes(x=EVnum, y=Estimate,group=cond,color=cond)) + 
        geom_errorbar(aes(ymin=Estimate-stderr, ymax=Estimate+stderr), width=.25,size=.5)+
        geom_line(size=2)+geom_point(size=6)+
        #Aesthetics!-------------------------
        scale_y_continuous(limits=c(0,1.5),breaks=seq(0,1.5,0.25))+
        scale_x_continuous(breaks=1:8)+
        scale_color_manual(values=c("black","red"))+
        ylab("Decision Weight")+xlab("Element Position")+#ggtitle('')+
        theme(plot.title = element_text(size =20,face='bold'))+
        theme(legend.key = element_blank())+
        #theme(legend.position="none")+
        theme(legend.position=c(0.45,0.9),legend.text=element_text(size=15,face="bold"),legend.direction="horizontal",legend.title = element_blank(),legend.key.size=unit(1,"cm")) +
        theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())+
        theme(axis.text=element_text(size=14,face="bold"))+
        theme(axis.title=element_text(family="Helvetica", face="bold",vjust=0.8))+ 
        theme(strip.text=element_text(family="Helvetica", face="bold",vjust=0.4,size=10))+
        theme(strip.text=element_text(family="Helvetica", face="bold",vjust=0.4,size=12))+
        theme(strip.background=element_blank())
plot3

# Correlation of accuracy between valid and invalid
#Add referece line data 
theme_set(theme_bw(base_size=18))#32/28
acc_ind<-ds%>%group_by(SUBID,CUETYPE)%>%summarise(ACC=mean(ACC))%>%spread(CUETYPE,ACC);print(acc_ind) 
m1 =summary(lm(valid~invalid,acc_ind));
r1=paste('R^2=',round((m1$r.squared),digits=1));
r2=paste('R=',round((sqrt(m1$r.squared)),digits=1))

acc_ind
ggplot(acc_ind,aes(x=valid,y=invalid,size=1))+
  geom_point(size=5,colour="black")+
  scale_x_continuous(limits=c(0.5,1),breaks=seq(0.5,1,0.1))+
  scale_y_continuous(limits=c(0,0.72),breaks=seq(0,1,0.1))+
  geom_smooth(method=lm,se=FALSE,fullrange=T,alpha=0.2,size=2,color="red") +
  ggtitle(paste0("Correlations of Cueing Congruency, 6 Items:",r1,r2))+ylab("Invalid Cueing")+xlab("Valid Cueing")+
  #Bunch of setting for Axises
  theme(legend.key = element_blank())+
  theme(legend.position="none")+
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())+
  #   theme(legend.position=c(0.50,0.5),legend.text = element_text(size = 20,face="bold"),legend.title = element_blank(),legend.key.size=unit(1,"cm")) +
  theme(plot.title=element_text(family="Helvetica", face="bold", size=16,vjust=1.4,hjust=1))+
  #   theme(axis.text.x=element_blank(),axis.ticks.x=element_blank())+
  theme(axis.title=element_text(family="Helvetica", face="bold",vjust=0.8))

