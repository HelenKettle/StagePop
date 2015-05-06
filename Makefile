# Utility makefile for doing things with this R package

PACKAGE:=stagePop
VERSION:=$(shell sed -e 's/Version: \([[:digit:]]*\)/\1/ p' -e 'd' $(PACKAGE)/DESCRIPTION)
#PLATFORM:=$(shell uname | sed -e 's/[[:space:]]*//g') #For compatibility with Windows without MinGW use gcc -dumpmachine and change conditionals accordingly. Could also use the RPlatform below
PLATFORM:=$(strip $(shell uname)) #For compatibility with Windows without MinGW use gcc -dumpmachine and change conditionals accordingly. Could also use the RPlatform below
RPLATFORM:=$(shell Rscript -e 'cat(R.Version()$$platform)')
SOURCE_TARBALL=$(PACKAGE)_$(VERSION).tar.gz
VIGNETTEDIR=$(PACKAGE)/vignettes/
VIGNETTEPDFS:=$(shell for file in $(VIGNETTEDIR)/*.Rnw; do echo "$(PACKAGE)/inst/doc/"`basename $$file .Rnw`.pdf; done)

SWEAVE_OPTIONS=--options=eval=FALSE

TESTINSTALLTREE=testinstall
MOST_RECENT=$(shell ./mostrecent.sh)

OUT_TARBALL="ShouldNotExist"

ifeq ($(PLATFORM), Linux )
OUT_TARBALL=$(PACKAGE)_$(VERSION)_R_$(RPLATFORM).tar.gz
endif 

ifeq ($(PLATFORM), MINGW32_NT-6.1 )
OUT_TARBALL=$(PACKAGE)_$(VERSION).zip
endif 

.default: build

doc.stamp: $(MOST_RECENT)
	R CMD BATCH roxygenise.Rbatch
	touch doc.stamp

doc: doc.stamp

#Used for quickly checking the vignettes will build (without R being evaluated)
vignette:
	cd $(VIGNETTEDIR); \
	for file in $(VIGNETTEDIR)/*.Rnw; do \
		R CMD Sweave $(SWEAVE_OPTIONS) $$file; \
		pdflatex `basename $$file .Rnw`.tex; \
	done

#Extract the vignette files from the tarball 
fullvignette: build
	tar zxf $(SOURCE_TARBALL) $(VIGNETTEPDFS)

check: doc.stamp build
	R CMD check $(SOURCE_TARBALL)

cran-check: doc.stamp build
	R CMD check --as-cran $(SOURCE_TARBALL)

#Clean out the Vignette PDFs otherwise the build process collects them up
$(SOURCE_TARBALL): $(MOST_RECENT) doc.stamp
	rm -f $(VIGNETTEPDFS)
	R CMD build $(PACKAGE)

build: $(SOURCE_TARBALL)

install:
	R CMD INSTALL ${PACKAGE}

dist: $(SOURCE_TARBALL)
	mkdir -p $(TESTINSTALLTREE)
	R CMD INSTALL -l ${TESTINSTALLTREE} --build $(SOURCE_TARBALL)
	@@echo ""
	@@echo ""
	@@if [ -f $(OUT_TARBALL) ]; then \
           echo "*** Installable package name is $(OUT_TARBALL)"; \
           echo "*** From within R run 'install.packages(\"$(OUT_TARBALL)\",repos=NULL)'"; \
           echo "*** Or from the shell, run 'R CMD INSTALL $(OUT_TARBALL)'"; \
	else \
	   echo "*** Hmm, the expected package output file $(OUT_TARBALL) does not exist."; \
	   echo "*** It's likely you are building on an unusual platform. "; \
	   echo "*** Above, look for a line beginning \"packaged installation of 'stagePop'\" to identify the output file name."; \
	   echo "*** Then install this binary package from within an R session using 'install.packages(\"PKG_FILE_NAME\",repos=NULL)'"; \
	fi 

testinstall: 
	mkdir -p $(TESTINSTALLTREE)	
	R CMD INSTALL -l ${TESTINSTALLTREE} ${PACKAGE}

updatebuildstamp:
	touch -r $(BUILD_STAMP)

clean:
	rm -f ${PACKAGE}/man/*.Rd
	rm -f ${PACKAGE}/inst/doc/*.pdf
	rm -f $(VIGNETTEDIR)/*.aux
	rm -f $(VIGNETTEDIR)/*.log
	#rm -f $(VIGNETTEDIR)/*.pdf
	rm -rf ${PACKAGE}.Rcheck
	rm -f *.Rbatch.Rout
	rm -f doc.stamp

distclean: clean
	rm -rf ${TESTINSTALLTREE}
	rm -f ${PACKAGE}_*.tar.gz
	rm -f ${PACKAGE}_*.zip
