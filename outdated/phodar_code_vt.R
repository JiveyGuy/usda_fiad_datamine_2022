library("maptools")
library("sp")
library(rgeos)
library("raster")
library(spatstat)
library(plyr)
library("rgdal")
library("rgeos")

fn1= ""
fn1
# "T:\\FS\\RD\\NRS\\Science\\FIA\\Project\\Inventory\\GIS\\alisterRestricted\\admin\\grants\\Hurtt_CMS_feb2017\\FIA_summaries\\VT501701_CT91201_coords.csv"

fn2 = file.choose()
fn2
# "T:\\FS\\RD\\NRS\\Science\\FIA\\Project\\Inventory\\GIS\\alisterRestricted\\symposia\\FIAStakeholders2019\\phodar\\FIAdata\\VT_tree_locations.csv"

p4string = CRS("+init=epsg:26918") #this is for VT, UTM zone 18 North. I need to change for each state.
#gdalsrsinfo <shapefile>.prj if I want to get the proj4string from an existing shapefile.


vtCoords = read.csv(fn1,stringsAsFactors = 0)
vtCoords = vtCoords[vtCoords$state == "VT",] #subset to just VT here.

vtTrees = read.csv(fn2,stringsAsFactors = 0)
#join trees to the xy locations of the center subplot, in preparation for attaching xy coords to each tree.
vtTreeLocs = merge(vtCoords,vtTrees,by.x = "CN",by.y = "PLT_CN",all.y=1)

#turn into a spatial points object to begin process of getting UTM coords
coord.dec = SpatialPoints(cbind(vtTreeLocs$XCOORD, vtTreeLocs$YCOORD), proj4string = CRS("+proj=longlat")) #tell coord.dec that the coords are in lat/long 

#make a new object that has the UTMcoords in the "coords" attribute; 26917 is utm zone 18
coord.UTM <- spTransform(coord.dec, p4string)
str(coord.UTM)
treesUTM = as.data.frame(coord.UTM@coords)
names(treesUTM)=c("XUTM","YUTM")
#join the new UTM coords to the original file. 
vtTreeLocs= cbind(vtTreeLocs,treesUTM)

#now make a new column with the azimuth shifts that are, instead of 0, 360, 120, and 240, the shifts that are needed considering the 13.96 degree westerly shift due to magnetic declination in CT
dec = -14.61 #change this for each state. I just chose a point near the middle of VT and the 2014-ish declination from the Internet. Note the negative sign indicates west declination; if it's east, the dec is positive!

vtTreeLocs$AzSp = ifelse(vtTreeLocs$SUBP == 1,0,
                         ifelse(vtTreeLocs$SUBP == 2,360+ dec,
                                ifelse(vtTreeLocs$SUBP == 3,120+dec, 240+dec)))

#note I have to fix the subplot 1 trees by zeroing out the shift -- I want the original coordinate for sp1.
vtTreeLocs$XUTMsp[vtTreeLocs$SUBP ==1] = vtTreeLocs$XUTM[vtTreeLocs$SUBP ==1] + 0*sin(vtTreeLocs$AzSp[vtTreeLocs$SUBP ==1]*pi/180)
vtTreeLocs$YUTMsp[vtTreeLocs$SUBP ==1] = vtTreeLocs$YUTM[vtTreeLocs$SUBP ==1] + 0*cos(vtTreeLocs$AzSp[vtTreeLocs$SUBP ==1]*pi/180)
#for subplots 2-4, do the shift.
vtTreeLocs$XUTMsp[vtTreeLocs$SUBP !=1] = vtTreeLocs$XUTM[vtTreeLocs$SUBP !=1] + 36.6*sin(vtTreeLocs$AzSp[vtTreeLocs$SUBP !=1]*pi/180)
vtTreeLocs$YUTMsp[vtTreeLocs$SUBP !=1] = vtTreeLocs$YUTM[vtTreeLocs$SUBP !=1] + 36.6*cos(vtTreeLocs$AzSp[vtTreeLocs$SUBP !=1]*pi/180)


vtTreeLocs$XUTMtree = vtTreeLocs$XUTMsp + (vtTreeLocs$DIST/3.281)*sin((vtTreeLocs$AZIMUTH+dec)*pi/180)
vtTreeLocs$YUTMtree = vtTreeLocs$YUTMsp + (vtTreeLocs$DIST/3.281)*cos((vtTreeLocs$AZIMUTH+dec)*pi/180)


#I now, after the above, have the UTMzone 18 coordinates for each tree measured in CT.

#export it as a shapefile:
coordinates(vtTreeLocs)=~XUTMtree+YUTMtree
proj4string(vtTreeLocs)= p4string #this is for CT UTM Zone 18
outshp = file.choose()
#"T:\\FS\\RD\\NRS\\Science\\FIA\\Project\\Inventory\\GIS\\alisterRestricted\\symposia\\FIAStakeholders2019\\phodar\\FIAdata\\VT_lidar_metrics\\vtUTM18treeCoords.shp"
raster::shapefile(vtTreeLocs, "T:\\FS\\RD\\NRS\\Science\\FIA\\Project\\Inventory\\GIS\\alisterRestricted\\symposia\\FIAStakeholders2019\\phodar\\FIAdata\\VT_lidar_metrics\\vtUTM18treeCoords.shp",overwrite=1)


#####now make the subplots that will sit over the plots, using vtCoords#####

coord.dec = SpatialPoints(cbind(vtCoords$XCOORD, vtCoords$YCOORD), proj4string = CRS("+proj=longlat")) #tell coord.dec that the coords are in lat/long 

#make a new object that has the UTMcoords in the "coords" attribute; 26917 is utm zone 18
coord.UTM <- spTransform(coord.dec, p4string)
str(coord.UTM)
vtCoordsUTM = as.data.frame(coord.UTM@coords)
names(vtCoordsUTM)=c("XUTM","YUTM")
#join the new UTM coords to the original file. 
vtCoords= cbind(vtCoords,vtCoordsUTM)
#now make rows for subplots:
vtCoords$SUBP = 1
vtCoords2 = vtCoords
vtCoords2$SUBP = 2
vtCoords3 = vtCoords
vtCoords3$SUBP = 3
vtCoords4 = vtCoords
vtCoords4$SUBP = 4
vtCoordsSP=rbind.data.frame(vtCoords, vtCoords2, vtCoords3, vtCoords4)



#now make a new column with the azimuth shifts that are, instead of 0, 360, 120, and 240, the shifts that are needed considering the 13.96 degree westerly shift due to magnetic declination in CT


vtCoordsSP$AzSp = ifelse(vtCoordsSP$SUBP == 1,0,
                         ifelse(vtCoordsSP$SUBP == 2,360+ dec,
                                ifelse(vtCoordsSP$SUBP == 3,120+dec, 240+dec)))

vtCoordsSP$XUTMsp = vtCoordsSP$XUTM + 36.6*sin(vtCoordsSP$AzSp*pi/180)
vtCoordsSP$YUTMsp = vtCoordsSP$YUTM + 36.6*cos(vtCoordsSP$AzSp*pi/180)

#now I need to fix the fact that I don't want to shift subplot 1 -- the above formulas move it. I need to move it back to the original coordinate.
vtCoordsSP$XUTMsp[vtCoordsSP$SUBP==1] = vtCoordsSP$XUTM[vtCoordsSP$SUBP==1]
vtCoordsSP$YUTMsp[vtCoordsSP$SUBP==1] = vtCoordsSP$YUTM[vtCoordsSP$SUBP==1]
#I now, after the above, have the UTMzone 18 coordinates for each tree measured in CT.

#export it as a shapefile:
coordinates(vtCoordsSP)=~XUTMsp+YUTMsp
proj4string(vtCoordsSP)= p4string #this is for CT UTM Zone 18
typeof(vtCoordsSP)
vtCoordsSPbuf=gBuffer(vtCoordsSP,width=7.3)
outshpSubPbuf = file.choose()
# "T:\\FS\\RD\\NRS\\Science\\FIA\\Project\\Inventory\\GIS\\alisterRestricted\\symposia\\FIAStakeholders2019\\phodar\\FIAdata\\VT_lidar_metrics\\vtUTM18SubPbuf.shp"
raster::shapefile(vtCoordsSPbuf, outshpSubPbuf,overwrite=1)

