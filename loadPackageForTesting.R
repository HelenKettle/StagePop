# This R file loads the package sources for testing

library(deSolve)
library(PBSddesolve)

package_name <- "stagePop"
DEVELOPMENT_MODE<-TRUE

src_files<-na.omit(
                  sapply(strsplit(gsub("'","",packageDescription(package_name,lib.loc=".",fields=c("Collate"))),"\n")[[1]],
                         function(file) {
                           target_file<-paste("stagePop/R/",file,sep="")
                           if (nchar(file) > 0 && file.exists(target_file)) {
                             return(target_file)
                           }
                           return(NA)
                         },
                         USE.NAMES=FALSE
                         )
                  )

for (file in src_files) {
  if (length(file) > 0) {
    source(file)
  }
}

# Alternatively if you have devtools installed:
#
# library(devtools)
# load_all("stagePop")                  
