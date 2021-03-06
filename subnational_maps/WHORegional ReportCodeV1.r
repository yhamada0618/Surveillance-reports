##################################################
#  WHO WPRO TB Control Report Script		 #
#  Sept 2, 2013                      		 #
#  Author: ARSalvacion                 		 #
#                                      		 #
#  Some codes in this script were modified from: #
#  (1) TOM Hiatt scripts               		 #
#  (2) Stack Overflow Discussion		 #
#  (3) R-blogger.com	                         #
#  (4) Zia Ahmed        			 #
##################################################

## Loading the required libraries ##
library(xlsx)
library(maptools)
library(raster)


##############################################
## Create Directories for Different Datasets##
##############################################

dir.create(paste("~/TBSubnational"))
outfolder<-file.path(paste("~/TBSubnational"))
dir.create(file.path(outfolder,"Data"))
datafolder<-file.path(outfolder,"Data")
dir.create(file.path(outfolder,"Maps"))
mapfolder<-file.path(outfolder,"Maps")
dir.create(file.path(outfolder,"Excel Template"))
exclfolder<-file.path(outfolder,"Excel Template")
dir.create(file.path(outfolder,"Tables"))
tablesfolder<-file.path(outfolder,"Tables")
dir.create(file.path(outfolder,"Figures"))
figurefolder<-file.path(outfolder,"Figures")
dir.create(file.path(outfolder,"Shapefiles"))
shapefolder<-file.path(outfolder,"Shapefiles")
dir.create(file.path(outfolder,"WHOMapTemplate"))
whomapfolder<-file.path(outfolder,"WHOMapTemplate")
dir.create(file.path(outfolder,"AppendixTables"))
aptfolder<-file.path(outfolder,"AppendixTables")


###############################
## Variables to be collected ##
###############################

# Correct Province Names
# Population 2012 
# New and relapse cases 2012 
# Number of suspects (people with presumptive TB) screened 2012 
# Number of new treatment cohort 2011 
# Number successfully treated in new treatment cohort 2011 

subtbdat<-c("Population", "New and relapse cases 2012", 
"Number of suspects (people with presumptive TB) screened 2012",
"Number of new treatment cohort 2011",
"Number successfully treated in new treatment cohort 2011")


####################################
## Download Subnational Map Files ## 
## for 7 Burden Coutnries         ##
####################################

# Cambodia (KHM)
# China (CHN)
# Lao PDR (LAO)
# Mongolia (MNG)
# Papua New Guinea (PNG)
# Philippines (PHL)
# Vietnam (VNM)

countries<-c("KHM","CHN","LAO","MNG","PNG","PHL","VNM")

for (i in countries){
lev<-ifelse(i=="VNM",2,1)
getData('GADM', country=i, level=lev, path=mapfolder)
}



##### OR ###############################################################
# Cambodia<-getData("GADM",country="KHM", level=1, path=mapfolder)     #
# China<-getData("GADM",country="CHN", level=1, path=mapfolder)        #
# Lao<-getData("GADM",country="LAO", level=1, path=mapfolder)          #
# Mongolia<-getData("GADM",country="MNG", level=1, path=mapfolder)     #
# PNG<-getData("GADM",country="PNG", level=1, path=mapfolder)          #
# Philippines<-getData("GADM",country="PHL", level=1, path=mapfolder)  # 
# Vietnam<-getData("GADM",country="VNM", level=2, path=mapfolder)      #
########################################################################



###########################################
# Create Excel File Template for country  #
# Specific TB Notification data           #
###########################################

# Extracting/Creating Subnational Data Template 

# Change Names to Country, Province, etc, convert to excel instead

maps<-dir(mapfolder)  
for (i in maps[-7]){
name<-substring(i,1,3)
load(i)
dat<-subset(gadm@data, select=c("NAME_0","ID_1","NAME_1")) 
colnames(dat)<-c("Country","ID","Province")
dat[c(subtbdat)]<-" "
write.xlsx(x = dat, file=path.expand(file.path(exclfolder,paste(name,".xlsx", sep=""))),
        sheetName = "TBSubNat", row.names = FALSE)
}

# For Vietnam
for (i in maps[7]){
name<-substring(i,1,3)
load(i)
dat<-subset(gadm@data, select=c("NAME_0","ID_2","VARNAME_2")) 
colnames(dat)<-c("Country","ID","Province")
dat[c(subtbdat)]<-" "
write.xlsx(x = dat, file=path.expand(file.path(exclfolder,paste(name,".xlsx", sep=""))),
        sheetName = "TBSubNat", row.names = FALSE)
}

####################
# End of First Run #
####################


##########################################################
# Merging submitted subnational data with GADM map files #
# Note: Need to download and check submitted data from   #
#       country coordinators                             #
##########################################################

library (xlsx)
library (maptools)

datafolder<-file.path(outfolder,"Data")
mapfolder<-file.path(outfolder,"Maps")

## Load all the subnational data

subnat<-dir(datafolder,full.names=T)


for (i in subnat){
name<-substring(gsub(".*/","",i),1,3)
namex<-paste(name,"_subnat",sep="")
data<-read.xlsx(i,1)
assign(namex,data)
}

smaps<-dir(mapfolder,full.names=T)

for (i in smaps){
name<-substring(gsub(".*/","",i),1,3)
namex<-paste(name,"_map",sep="")
load(i)
assign(namex,gadm)
}

KHM_map@data<-KHM_subnat
CHN_map@data<-CHN_subnat
LAO_map@data<-LAO_subnat
MNG_map@data<-MNG_subnat
PHL_map@data<-PHL_subnat
PNG_map@data<-PNG_subnat
VNM_map@data<-VNM_subnat


##################################################
# Calculate and Creating Maps/shapefile of Rates # 
##################################################

library (rgdal)

### Function to calculate and create shapefile of rates
# map - refers to the R mapfile of country, country - refers to the country name
 
maprates<-function(maps,country){ 
shp<-maps
shp$notif<-(shp$New.and.relapse.cases.2012/shp$Population)*100000
shp$susp<-(shp$Number.of.suspects..people.with.presumptive.TB..screened.2012/shp$Population)*100000
shp$ns<-(shp$Number.of.suspects..people.with.presumptive.TB..screened.2012/shp$New.and.relapse.cases.2012)*100
shp$trt<-(shp$Number.successfully.treated.in.new.treatment.cohort.2011/shp$Number.of.new.treatment.cohort.2011)*100
rshp<-subset(shp,select=c("Province","notif","susp","ns","trt"))
return(writeOGR(rshp, dsn=path.expand(shapefolder), country, driver="ESRI Shapefile"))
}

maprates(KHM_map,"KHM")
maprates(CHN_map,"CHN")
maprates(LAO_map,"LAO")
maprates(MNG_map,"MNG")
maprates(PNG_map,"PNG")
maprates(PHL_map,"PHL")
maprates(VNM_map,"VNM")




#####################
# Plot using ggplot #
#####################
library(maptools)
library(lattice)
library(ggplot2)
library(plyr)
library(mapproj)
library(RColorBrewer)
library(rgdal)

rmaps<-dir(shapefolder,full.names=T, pattern=".shp")

# Map colors

# notif
nc1<-"#ff0000"
nc2<-"#4c0000"

#susp
sc1<-"#ff5105"
sc2<-"#4a1101"

#ns
nsc1<-"#ff09ff"
nsc2<-"#390237"

#trt
trtc1<-"#17ff44"
trtc2<-"#05400e"

# create map in ggplot


for (i in rmaps){
name<-substring(gsub(".*/","",i),1,3)
map<-readShapePoly(i, proj4string=CRS("+proj=longlat"))
map@data$id = rownames(map@data)
map1<-fortify(map,region="id")
map1.df <- join(map1, map@data, by="id")

## Mapping Notification Rates
theme_set(theme_classic())
n1<- ggplot(map1.df, aes(long,lat,group=group))+geom_polygon(aes(fill=notif), colour="white")+scale_fill_gradient("New and relapse\ncases per\n100 000\npopulation, 2012",low=nc1,high=nc2, space="Lab")
n2<-n1+theme(axis.text.x =element_blank(),axis.text.y= element_blank(), axis.line = element_blank(), axis.ticks=element_blank(),axis.title.x =element_blank(),axis.title.y= element_blank())
n3<-n2+coord_map()
#print map in jpeg format
jpeg(file=file.path(figurefolder, paste(name,"notif",".jpeg", sep="")),w=2115,h=2000,res=300)
print(n3)
dev.off()

## Mapping Number of suspect


s1<- ggplot(map1.df, aes(long,lat,group=group))+geom_polygon(aes(fill=susp), colour="white")+scale_fill_gradient("Suspects tested\nfor TB\nper 100 000\npopulation, 2012",low=sc1,high=sc2, space="Lab")
s2<-s1+theme(axis.text.x =element_blank(),axis.text.y= element_blank(), axis.line = element_blank(), axis.ticks=element_blank(),axis.title.x =element_blank(),axis.title.y= element_blank())
s3<-s2+coord_map()
#print map in jpeg format
jpeg(file=file.path(figurefolder, paste(name,"susp",".jpeg", sep="")),w=2115,h=2000,res=300)
print(s3)
dev.off()

## Mapping Number of suspect/relapse

ns1<- ggplot(map1.df, aes(long,lat,group=group))+geom_polygon(aes(fill=ns), colour="white")+scale_fill_gradient("Percentage of\nsuspects found\npositive for\nTB, 2012",low=nsc1,high=nsc2, space="Lab")
ns2<-ns1+theme(axis.text.x =element_blank(),axis.text.y= element_blank(), axis.line = element_blank(), axis.ticks=element_blank(),axis.title.x =element_blank(),axis.title.y= element_blank())
ns3<-ns2+coord_map()
jpeg(file=file.path(figurefolder, paste(name,"ns",".jpeg", sep="")),w=2115,h=2000,res=300)
print(ns3)
dev.off()

trt1<- ggplot(map1.df, aes(long,lat,group=group))+geom_polygon(aes(fill=trt), colour="white")+scale_fill_gradient("Percentage of\npatients successfully\ntreated, 2011",low=trtc1,high=trtc2, space="Lab")
trt2<-trt1+theme(axis.text.x =element_blank(),axis.text.y= element_blank(), axis.line = element_blank(), axis.ticks=element_blank(),axis.title.x =element_blank(),axis.title.y= element_blank())
trt3<-trt2+coord_map()
jpeg(file=file.path(figurefolder, paste(name,"trt",".jpeg", sep="")),w=2115,h=2000,res=300)
print(trt3)
dev.off()

}


# Creating regional maps/merging country's shapefile

files <- dir(shapefolder,recursive=TRUE,pattern="*.shp$", full.names=TRUE)
uid<-1

regnotifmap<- readOGR(files[1],gsub("^.*/(.*).shp$", "\\1", files[1]))
n <- length(slot(regnotifmap, "polygons"))
poly.data <- spChFIDs(regnotifmap, as.character(uid:(uid+n-1)))
uid <- uid + n

for (i in 2:length(files)) {
     temp.data <- readOGR(files[i], gsub("^.*/(.*).shp$", "\\1",files[i]))
     n <- length(slot(temp.data, "polygons"))
     temp.data <- spChFIDs(temp.data, as.character(uid:(uid+n-1)))
     uid <- uid + n
     regnotifmap <- spRbind(regnotifmap,temp.data)
}

# Creating regional notification rate map

regnotifmap@data$id = rownames(regnotifmap@data)
rnmap<-fortify(regnotifmap,region="id")
rnmap.df <- join(rnmap, regnotifmap@data, by="id")

data(wrld_simpl)
wrld_simpl@data$id<-rownames(wrld_simpl@data)
wmap<-fortify(wrld_simpl, region="id")

# Warning: this process will consume total memroy (3907Mb) allocation for R environment
theme_set(theme_classic())
wm<-ggplot(wmap, aes(long,lat,group=group))+geom_polygon()
rgtm<-wm+geom_polygon(data=rnmap.df,aes(long,lat, group=group, fill=ns))+scale_fill_gradient("New and relapse\ncases per\n100 000\npopulation, 2012",low=nc1,high=nc2, space="Lab")+xlim(c(73.55,157))+ylim(c(-11,53))+coord_map()
rgtm<-rgtm+theme(axis.text.x =element_blank(),axis.text.y= element_blank(), axis.line = element_blank(), axis.ticks=element_blank(),axis.title.x =element_blank(),axis.title.y= element_blank())


jpeg(file=file.path(figurefolder, paste("regionalns2",".jpeg", sep="")),w=2115,h=2000,res=300)
print(rgtm)
dev.off()



# Writing Appendix Tables

setwd(aptfolder)

subnat<-dir(datafolder,full.names=T)

for (i in subnat){
nameapt<-substring(gsub(".*/","",i),1,3)
data<-read.xlsx(i,1)
hwrite(data,paste(nameapt,".html", sep=""))
}

##################
# End of 2nd Run #
##################


