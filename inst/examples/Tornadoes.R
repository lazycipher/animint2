#' NOAA SVRGIS data (Severe Report Database + Geographic Information System)
#' http://www.spc.noaa.gov/gis/svrgis/
#' Data - http://www.spc.noaa.gov/wcm/#data
#' Location Codes - http://www.spc.noaa.gov/wcm/loccodes.html
#' State FIPS Codes - http://www.spc.noaa.gov/wcm/fips_usa.gif
#' County FIPS Codes - http://www.spc.noaa.gov/wcm/stnindex_all.txt
#' State/County Area and Population - http://quickfacts.census.gov/qfd/download/DataSet.txt
#' 
#' Image Inspiration -  http://www.kulfoto.com/pic/0001/0033/b/h4n5832833.jpg
library(animint2)
data(UStornadoes)
stateOrder <- data.frame(state = unique(UStornadoes$state)[order(unique(UStornadoes$TornadoesSqMile), decreasing=T)], rank = 1:49) # order states by tornadoes per square mile
UStornadoes$state <- factor(UStornadoes$state, levels=stateOrder$state, ordered=TRUE)
UStornadoes$weight <- 1/UStornadoes$LandArea
# useful for stat_bin, etc. 

USpolygons <- map_data("state")
USpolygons$state = state.abb[match(USpolygons$region, tolower(state.name))]

statemap <- ggplot() + geom_polygon(data=USpolygons, aes(x=long, y=lat, group=group), fill="black", colour="grey") +
  geom_segment(data=UStornadoes, aes(x=startLong, y=startLat, xend=endLong, yend=endLat, size=trackWidth), colour="#55B1F7", alpha=.2) +
  geom_segment(data=UStornadoes, aes(x=startLong, y=startLat, xend=endLong, yend=endLat, size=trackWidth, alpha=f), colour="#55B1F7") +
  scale_size_continuous("Width (yd)", range=c(.5, 2)) + 
  scale_alpha_continuous("Strength (F or EF scale)", range=c(.3, 1)) + 
  ggtitle("Tornado Paths, 1950-2006")

## ERROR: geom_bar + stat_bin + clickSelects does not make sense! We
## should stop with an error!
tornado.bar <-
  list(map=ggplot()+
       geom_polygon(aes(x=long, y=lat, group=group),
                    data=USpolygons, fill="black", colour="grey") +
       geom_segment(aes(x=startLong, y=startLat, xend=endLong, yend=endLat),
                    showSelected="year",
                    colour="#55B1F7", data=UStornadoes),
       ts=ggplot()+
       geom_bar(aes(year), clickSelects="year",data=UStornadoes))
animint2dir(tornado.bar, "tornado-bar")

## OK: stat_summary + clickSelects ensures unique x values.
tornado.bar <-
  list(map=ggplot()+
       geom_polygon(aes(x=long, y=lat, group=group),
                    data=USpolygons, fill="black", colour="grey") +
       geom_segment(aes(x=startLong, y=startLat, xend=endLong, yend=endLat),
                    showSelected="year",
                    colour="#55B1F7", data=UStornadoes),
       ts=ggplot()+
       stat_summary(aes(year, year),
                    clickSelects="year",
                    data=UStornadoes, fun.y=length, geom="bar"))
animint2dir(tornado.bar, "tornado-bar")

## Same plot, using make_bar abbreviation.
tornado.bar <-
  list(map=ggplot()+
       geom_polygon(aes(x=long, y=lat, group=group),
                    data=USpolygons, fill="black", colour="grey") +
       geom_segment(aes(x=startLong, y=startLat, xend=endLong, yend=endLat),
                    showSelected="year",
                    colour="#55B1F7", data=UStornadoes),
       ts=ggplot()+
       make_bar(UStornadoes, "year"))
animint2dir(tornado.bar, "tornado-bar")

UStornadoCounts <-
  ddply(UStornadoes, .(state, year), summarize, count=length(state))
## OK: select state to show that subset of bars!
tornado.ts.bar <-
  list(map=ggplot()+
       make_text(UStornadoCounts, -100, 50, "year", "Tornadoes in %d")+
       geom_polygon(aes(x=long, y=lat, group=group),
                    clickSelects="state",
                    data=USpolygons, fill="black", colour="grey") +
       geom_segment(aes(x=startLong, y=startLat, xend=endLong, yend=endLat),
                    showSelected="year",
                    colour="#55B1F7", data=UStornadoes),
       ts=ggplot()+
       make_text(UStornadoes, 1980, 200, "state")+
       geom_bar(aes(year, count),
                clickSelects="year", showSelected="state",
                data=UStornadoCounts, stat="identity", position="identity"))
animint2dir(tornado.ts.bar, "tornado-ts-bar")
## also show points.
seg.color <- "#55B1F7"
tornado.points <-
  list(map=ggplot()+
       make_text(UStornadoCounts, -100, 50, "year", "Tornadoes in %d")+
       geom_polygon(aes(x=long, y=lat, group=group),
                    clickSelects="state",
                    data=USpolygons, fill="black", colour="grey") +
       geom_segment(aes(x=startLong, y=startLat, xend=endLong, yend=endLat),
                    showSelected="year",
                    colour=seg.color, data=UStornadoes)+
       ## geom_point(aes(startLong, startLat, fill=place, showSelected=year),
       ##              colour=seg.color,
       ##            data=data.frame(UStornadoes,place="start"))+
       scale_fill_manual(values=c(end=seg.color))+
       geom_point(aes(endLong, endLat, fill=place),
                  showSelected="year",
                  colour=seg.color,
                  data=data.frame(UStornadoes,place="end")),
       width=list(map=1500, ts=300),
       height=list(map=1000, ts=300),
       ts=ggplot()+
       make_text(UStornadoes, 1980, 200, "state")+
       geom_bar(aes(year, count),
                clickSelects="year", showSelected="state",
                data=UStornadoCounts, stat="identity", position="identity"))
animint2dir(tornado.points, "tornado-points")

## It would be nice to be able to specify the width/height using
## animint.* theme options, but this currently gives an error... is
## there any work-around?
tornado.points <-
  list(map=ggplot()+
       make_text(UStornadoCounts, -100, 50, "year", "Tornadoes in %d")+
       geom_polygon(aes(x=long, y=lat, group=group),
                    clickSelects="state",
                    data=USpolygons, fill="black", colour="grey") +
       geom_segment(aes(x=startLong, y=startLat, xend=endLong, yend=endLat),
                    showSelected="year",
                    colour=seg.color, data=UStornadoes)+
       scale_fill_manual(values=c(end=seg.color))+
       theme_animint(width=750, height=500)+
       geom_point(aes(endLong, endLat, fill=place),
                  showSelected="year",
                  colour=seg.color,
                  data=data.frame(UStornadoes,place="end")),
       ts=ggplot()+
       make_text(UStornadoes, 1980, 200, "state")+
       geom_bar(aes(year, count),
                clickSelects="year", showSelected="state",
                data=UStornadoCounts, stat="identity", position="identity"))
animint2dir(tornado.points, "tornado-points")

tornado.points.anim <-
  list(map=ggplot()+
       make_text(UStornadoes, -100, 50, "year",
                 "Tornado paths and endpoints in %d")+
       geom_segment(aes(x=startLong, y=startLat, xend=endLong, yend=endLat),
                    showSelected="year",
                    colour=seg.color, data=UStornadoes)+
       geom_point(aes(endLong, endLat),
                  showSelected="year",
                  colour=seg.color,
                  data=UStornadoes)+
       geom_polygon(aes(x=long, y=lat, group=group),
                    clickSelects="state",
                    data=USpolygons, fill="grey", colour="black", alpha=3/4)+
       theme(axis.line=element_blank(), axis.text=element_blank(), 
             axis.ticks=element_blank(), axis.title=element_blank()),
       width=list(map=750, ts=300),
       height=list(map=500, ts=400),
       ##time=list(variable="year", ms=2000),
       ts=ggplot()+
       xlab("year")+
       ylab("Number of tornadoes")+
       geom_bar(aes(year, count),
                clickSelects="year", showSelected="state",
                data=UStornadoCounts, stat="identity", position="identity")+
       make_text(UStornadoes, 1980, 200, "state")+
       geom_text(aes(year, count + 5, label=count),
                 showSelected=c("state", "year"),
                 data=UStornadoCounts, size=20))
animint2dir(tornado.points.anim, "tornado-points-anim")

## OK: interactive version with lines instead of bars!
tornado.ts.line <-
  list(map=ggplot()+
       geom_polygon(aes(x=long, y=lat, group=group),
                    clickSelects="state",
                    data=USpolygons, fill="black", colour="grey") +
       geom_segment(aes(x=startLong, y=startLat, xend=endLong, yend=endLat),
                    showSelected="year",
                    colour="#55B1F7", data=UStornadoes),
       ts=ggplot()+
       make_tallrect(UStornadoCounts, "year")+
       geom_line(aes(year, count, group=state),
                 clickSelects="state",
                 data=UStornadoCounts, alpha=3/5, size=4))
animint2dir(tornado.ts.line, "tornado-ts-line")


tornado.anim <-
  list(map=ggplot()+
       geom_polygon(aes(x=long, y=lat, group=group),
                    clickSelects="state",
                    data=USpolygons, fill="black", colour="grey") +
       geom_segment(aes(x=startLong, y=startLat, xend=endLong, yend=endLat),
                    showSelected="year",
                    colour="#55B1F7", data=UStornadoes),
       ts=ggplot()+
       make_tallrect(UStornadoCounts, "year")+
       geom_line(aes(year, count, group=state),
                 clickSelects="state",
                 data=UStornadoCounts, alpha=3/5, size=4),
       time=list(variable="year",ms=2000))
animint2dir(tornado.anim, "tornado-anim")
