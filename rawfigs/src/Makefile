vectorsources := $(shell find rawfigs/ -maxdepth 1 -name '*.dia' -o -name '*.eps' -o -name '*.m' -o -name '*.ps' -o -name '*.py' -o -name '*.svg' 2>/dev/null)
rastersources := $(shell find rawfigs/ -maxdepth 1 -name '*.gif' -o -name '*.png' 2>/dev/null)
readysources  := $(shell find rawfigs/ -maxdepth 1 -name '*.jpg' -o -name '*.pdf' -o -name '*mpg' -o -name '*.mpeg' 2>/dev/null)

vectorfigs := $(shell echo ' ' $(patsubst %_fm.eps,%.eps,$(vectorsources)) ' ' | sed -e 's> \(../common/\)*raw> >g' -e 's/\.[^. ]* /.pdf /g')
rasterfigs := $(shell echo ' ' $(rastersources) ' ' | sed -e 's> \(../common/\)*raw> >g' -e 's/\.[^. ]* /.jpg /g')
readyfigs  := $(shell echo ' ' $(readysources) ' ' | sed -e 's> \(../common/\)*raw> >g')

figures    := $(vectorfigs) $(rasterfigs) $(readyfigs)

texsource := $(filter-out %preamble.tex, $(wildcard *.tex))
texfinal := $(patsubst %.tex,../fromtex/%.pdf,$(texsource))

dirname  := $(shell basename $(shell pwd))

alldeps := $(figures)

PDFLATEX ?= lualatex

MYPDFLATEX   = TEXINPUTS=$(abspath ../common):$$TEXINPUTS $(PDFLATEX) --halt-on-error --interaction=batchmode
MYFRAGMASTER = TEXINPUTS=$(abspath ../common):$$TEXINPUTS $(FRAGMASTER)

.PHONY: all cleanlatex cleanfigs figures

all: $(texfinal) $(alldeps)

clean: cleantexfigs cleanfigs

cleantexfigs:
	@rm -f ./*.aux ./*.log ./*.bbl ./*.blg ./*.dvi ./*.nav ./*.out ./*.snm ./*.toc ./*.vrb ./*.lof ./*.lot ./*.gnuplot ./*.table
	@rm -rf ../fromtex

cleanfigs:
	@rm -rf figs/

continuous: all
	while true; do \
	  inotifywait -e close_write -e delete_self -e move $(all) || break; \
          $(MAKE) all; \
        done

../fromtex/%.pdf: %.tex $(figures)
	@mkdir -p ../fromtex
	@echo "$@ <- $?"
	$(MYPDFLATEX) --draftmode $? && rm $(shell echo $@ | cut -d'/' -f3) && $(MYPDFLATEX) $? && mv $(shell echo $@ | cut -d'/' -f3) ../fromtex


figs/%.pdf: rawfigs/%.dia
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@dia -t eps-builtin -e $?_roytemp.eps $? && epstopdf $?_roytemp.eps -o=$@
	@rm -f $?_roytemp.eps

figs/%.pdf: rawfigs/%.eps
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@epstopdf $? -o=$@ || (rm $@; exit 1)

figs/%.pdf: rawfigs/%_fm rawfigs/%_fm.eps  # fragmaster(1) with optional control file
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@(test -f rawfigs/fragmaster.dfm && (cd $(dir $@) && ln -sf -t . ../rawfigs/fragmaster.dfm) || true)
	@(cd $(dir $@) && ln -sf -t . $(addprefix ../,$+) && $(MYFRAGMASTER))

figs/%.pdf: rawfigs/%.m
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@cd $(dir $?) && $(OCTAVE) $(notdir $?)
	@(test -f $(dir $?)/$*.eps && (epstopdf $(dir $?)/$*.eps -o=$@; rm -f $(dir $?)/$*.eps) || true)
	@(test -f $(dir $?)/$*.pdf && mv $(dir $?)/$*.pdf $@ || true)

figs/%.pdf: rawfigs/%.py
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@cd $(dir $?) && $(PYTHON) $(notdir $?)
	@(test -f $(dir $?)/$*.eps && (epstopdf $(dir $?)/$*.eps -o=$@; rm -f $(dir $?)/$*.eps) || true)
	@(test -f $(dir $?)/$*.pdf && mv $(dir $?)/$*.pdf $@ || true)

figs/%.pdf: rawfigs/%.ps
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@ps2pdf $? $@

figs/%.pdf: rawfigs/%.svg
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@$(INKSCAPE) $? --export-area-drawing --export-filename=$@

figs/%.jpg: rawfigs/%.png
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@gm convert -channel opacity -fill white $? - | gm composite -compose over $? - -geometry "1920x1100>" $@

figs/%.jpg: rawfigs/%.gif
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@gm convert -geometry "1920x1100>" $? $@

figs/%.mpeg: rawfigs/%.mpeg
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@reldir=`echo $(dir $@) | sed -e 's>[^/]*/*>../>g'`; ln -sf $${reldir}$? $@

figs/%.mpg: rawfigs/%.mpg
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@reldir=`echo $(dir $@) | sed -e 's>[^/]*/*>../>g'`; ln -sf $${reldir}$? $@

figs/%.pdf: rawfigs/%.pdf
	@echo "$@ <- $(shell echo $? | cut -d' ' -f 1)"
	@mkdir -p $(dir $@)
	@reldir=`echo $(dir $@) | sed -e 's>[^/]*/*>../>g'`; ln -sf $${reldir}$(shell echo $? | cut -d' ' -f 1) $@

figs/%.jpg: rawfigs/%.jpg
	@echo "$@ <- $?"
	@mkdir -p $(dir $@)
	@gm convert -geometry "1920x1100>" $? $@

