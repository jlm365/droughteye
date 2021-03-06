cat('\n\n=============================================================================================\n')

cat(Sys.time(), '\t updating delta_t_anomaly ...\n')

source('required_libs.R')
source('env_vars.R')
source('app/funcs.R')

this_month <- month(Sys.Date())
this_year <- year(Sys.Date())

for(y in 2001:this_year){
  for(m in 1:12){
    if(y==this_year&m>=this_month) next()
    cat('writing deltaT for', y, m, '\n')
    write_detla_t_anomaly(y, m, deltat_repo)
  }
}

cat(Sys.time(), '\t delta_t_anomaly done!\n')
