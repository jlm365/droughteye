cat('\n\n=============================================================================================\n')

cat(Sys.time(), '\t updating summaries ...\n')
source('required_libs.R')
source('env_vars.R')
source('app/funcs.R')


phys <- raster::shapefile(paste0(data_repo, 'physio/physio.shp'))

this_month <- month(Sys.Date())
this_year <- year(Sys.Date())

summDT <- data.table()

for(y in 2001:this_year){
  for(m in 1:12){
    if(y==this_year&m>=this_month) next()
    for(type in c('temporal', 'normal', 'anomaly')){
      cat('getting summaries for', type, y, m, '\n')
      path <- switch (type,
                      'temporal' = sprintf(fmt = '%sTEMPORAL/DELTAT.TEMPORAL.%04d.%02d.01.tif', deltat_repo, y, m),
                      'normal' = sprintf(fmt = '%sNORMAL/DELTAT.NORMAL.%02d.01.tif', deltat_repo, m),
                      'anomaly' = sprintf(fmt = '%sANOMALY/DELTAT.ANOMALY.%04d.%02d.01.tif', deltat_repo, y, m)
      )
      if(!file.exists(path)) {
        cat(path, ' does not exist!\n')
        next()
      }
      
      summ_path <- sprintf(fmt = '%sSUMM.%s.%04d.%02d.01.rds', summ_repo, toupper(type), y, m)
      
      
      if(file.exists(summ_path)){
        zonal_stats <- readRDS(summ_path)
        cat(summ_path, ' already exists!\n')
        
      }else{
        cat('creating', summ_path,  '...\n')
        map_raster <- raster(path)
        zonal_stats <- raster::extract(map_raster, phys)
        names(zonal_stats) <- tools::toTitleCase(tolower(phys$PROVINCE))
        saveRDS(zonal_stats, file = summ_path)
      }
      quant <- t(sapply(zonal_stats, quantile, na.rm = TRUE, probs = c(0.025, 0.25, 0.50, 0.75, 0.975)))
      qsd <- sapply(zonal_stats, sd, na.rm = TRUE)
      qmean <- sapply(zonal_stats, mean, na.rm = TRUE)
      
      quantDT <- data.table(year = y, month = m, type = type, Ecoregion = rownames(quant), mean = qmean, sd = qsd, quant)
      quantDT <- melt(quantDT, id.vars = 1:4)
      
      summDT <- rbind(summDT, quantDT)
    }
  }
}

summDT[,date:=as.Date(sprintf(fmt = '%04d-%02d-01', year, month))]

saveRDS(file = sprintf(fmt = '%sSUMM.ALL.rds', summ_repo), object = summDT)

cat(Sys.time(), '\t summaries done!\n')

