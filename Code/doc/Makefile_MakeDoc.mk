#------------------------------------------------------------------------------
#          Harvard University Atmospheric Chemistry Modeling Group            !
#------------------------------------------------------------------------------
#BOP
#
# !IROUTINE: Makefile_MakeDoc.mk (in doc subdirectory)
#
# !DESCRIPTION: This Makefile fragment contains commands to build the 
#  documentation for the GEOS-Chem Makefiles  It is inlined into
#  the Makefile (in the doc subdirectory) by an "include" command.
#\\
#\\
# !REMARKS:
# To build the documentation, call "make" with the following syntax:
#
#   make TARGET [ OPTIONAL-FLAGS ]
#
# To display a complete list of options, type "make help".
#
# You must have the LaTeX utilities (latex, dvips, dvipdf) installed
# on your system in order to build the documentation.
#
# !REVISION HISTORY: 
#  14 Sep 2010 - R. Yantosca - Initial version, split off from Makefile
#  16 Dec 2010 - R. Yantosca - Renamed output files to "GC_Ref_Vol_1.*"
#EOP
#------------------------------------------------------------------------------
#BOC


# List of source code files (order is important)
SRC2 :=                        \
./intro.make                   \
$(ROOTDIR)/Makefile            \
$(ROOTDIR)/Makefile_header.mk  \
$(UTIL)/Makefile               \
$(ISO)/Makefile                \
$(CODE)/Makefile               \
$(KPP)/Makefile                \
$(KPP)/standard/Makefile       \
$(KPP)/SOA/Makefile            \
$(TOM)/Makefile                \
$(GTMM)/Makefile               \
$(DOC)/Makefile                \
$(DOC)/Makefile_SrcDoc.mk      \
$(DOC)/Makefile_UtilDoc.mk     \
$(DOC)/Makefile_GtmmDoc.mk     \
$(DOC)/Makefile_MakeDoc.mk     \
$(HELP)/Makefile


# Output file names
TEX2 := GC_Ref_Vol_1.tex
DVI2 := GC_Ref_Vol_1.dvi
PDF2 := GC_Ref_Vol_1.pdf
PS2  := GC_Ref_Vol_1.ps


# Make command
makedoc: 
	rm -f $(TEX2)
	protex -fS $(SRC2) > $(TEX2)
	latex $(TEX2)
	latex $(TEX2)
	latex $(TEX2)
	dvipdf $(DVI2) $(PDF2)
	dvips $(DVI2) -o $(PS2)
	rm -f *.aux *.dvi *.log *.toc

#EOC
