# OS Name (Linux or Darwin)
OSLOWER = $(shell uname -s 2>/dev/null | tr "[:lower:]" "[:upper:]")
OS_ARCH = $(shell uname -m | sed -e "s/i386/i686/")

ifeq ($(ARMv7),1)
  OS_ARCH = armv7l
endif

# Project folders that contain CUDA samples
PROJECTS ?= $(shell find pnpoly -name Makefile)

FILTER-OUT :=

ifeq ($(OS_ARCH),armv7l)
FILTER-OUT += 3_Imaging/cudaDecodeGL/Makefile
FILTER-OUT += 7_CUDALibraries/imageSegmentationNPP/Makefile
FILTER-OUT += 7_CUDALibraries/boxFilterNPP/Makefile
FILTER-OUT += 7_CUDALibraries/grabcutNPP/Makefile
FILTER-OUT += 7_CUDALibraries/freeImageInteropNPP/Makefile
FILTER-OUT += 7_CUDALibraries/freeImageInteropNPP/out
FILTER-OUT += 7_CUDALibraries/histEqualizationNPP/Makefile
FILTER-OUT += 7_CUDALibraries/jpegNPP/Makefile
endif

PROJECTS := $(filter-out $(FILTER-OUT),$(PROJECTS))

%.ph_build :
	+@$(MAKE) -C $(dir $*) $(MAKECMDGOALS)

%.ph_clean : 
	+@$(MAKE) -C $(dir $*) clean $(USE_DEVICE)

%.ph_clobber :
	+@$(MAKE) -C $(dir $*) clobber $(USE_DEVICE)

all:  $(addsuffix .ph_build,$(PROJECTS))
	@echo "Finished building CUDA samples"

build: $(addsuffix .ph_build,$(PROJECTS))

tidy:
	@find * | egrep "#" | xargs rm -f
	@find * | egrep "\~" | xargs rm -f

clean: tidy $(addsuffix .ph_clean,$(PROJECTS))

clobber: clean $(addsuffix .ph_clobber,$(PROJECTS))
