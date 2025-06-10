vectorsources := $(shell find rawfigs/ -maxdepth 1 -name '*.dia' -o -name '*.eps' -o -name '*.m' -o -name '*.pdf' -o -name '*.ps' -o -name '*.py' -o -name '*.svg' 2>/dev/null)
rastersources := $(shell find rawfigs/ -maxdepth 1 -name '*.gif' -o -name '*.png' -not -name bonheur.png 2>/dev/null)
readysources  := $(shell find rawfigs/ -maxdepth 1 -name '*.jpg' -o -name '*.pdf' -o -name '*mpg' -o -name '*.mpeg' 2>/dev/null)
texsource     := $(wildcard abstract.tex main.tex paper.tex poster.tex proposal.tex report.tex talk.tex)
bonheur       := rawfigs/bonheur.png

vectorfigs := $(shell echo ' ' $(patsubst %_fm.eps,%.eps,$(vectorsources)) ' ' | sed -e 's> \(../common/\)*raw> >g' -e 's/\.[^. ]* /.pdf /g')
rasterfigs := $(shell echo ' ' $(rastersources) ' ' | sed -e 's> \(../common/\)*raw> >g' -e 's/\.[^. ]* /.jpg /g')
readyfigs  := $(shell echo ' ' $(readysources) ' ' | sed -e 's> \(../common/\)*raw> >g')
figsources := $(vectorsources) $(rastersources) $(readysources) $(texfigsources)
figs       := $(vectorfigs) $(rasterfigs) $(readyfigs) $(bonheur)
dirname    := $(shell basename $(shell pwd))
#ifeq ($(words $(texsource)),'1')
#    texfinal := $(dirname).pdf
#    texroot   = $(patsubst %.pdf,%,$(1))
#else
#    texfinal := $(patsubst %.tex,$(dirname)-%.pdf,$(texsource))
#    texroot   = $(patsubst $(dirname)-%,%,$(patsubst %.pdf,%,$(1)))
#endif
texfinal = theorie_N1.pdf
texroot = main

bibfiles := $(wildcard *.bib)
styfiles := $(wildcard *.sty ../common/*.sty)
clsfiles := $(wildcard *.cls ../common/*.cls)

alldeps := *.tex $(bibfiles) texfigs figures $(figsources) $(clsfiles) $(styfiles)

BIBTEX     ?= bibtex
PDFLATEX   ?= pdflatex
LATEX      ?= latex
PYTHON     ?= python
OCTAVE     ?= octave
INKSCAPE   ?= inkscape
FRAGMASTER ?= fragmaster
XINDY      ?= xindy
MAKEINDEX  ?= makeindex

MYPDFLATEX   = TEXINPUTS=$(abspath ../common):$$TEXINPUTS $(PDFLATEX) --halt-on-error --interaction=nonstopmode
MYLATEX      = TEXINPUTS=$(abspath ../common):$$TEXINPUTS $(LATEX) --halt-on-error --interaction=nonstopmode
MYFRAGMASTER = TEXINPUTS=$(abspath ../common):$$TEXINPUTS $(FRAGMASTER)

.PHONY: all texfigs figures clean cleanlatex cleanfigs

all: $(texfinal)

texfigstex:
	@cd rawfigs/src && make && make cleanlatex

cleanlatexsrc:
	@cd rawfigs/src && make clean

texfigs: texfigstex
	@mkdir -p figs
	@reldir=`echo $(wildcard rawfigs/fromtex/*.pdf) | sed -e 's>rawfigs/*>../rawfigs/>g'`; ln -sf $${reldir} figs/

figures: texfigs $(figs) bonheur

bonheur: figs/bonheur.png

figs/bonheur.png: rawfigs/bonheur.png
	@echo "figs/bonheur.png <- rawfigs/bonheur.png"
	@rm -f figs/bonheur.jpg
	@gm convert -geometry "1920x1100>" rawfigs/bonheur.png figs/bonheur.png

continuous: all
	while true; do \
	  inotifywait -e close_write -e delete_self -e move $(alldeps) || break; \
          $(MAKE) all; \
        done

$(texfinal): $(alldeps)
	$(MYPDFLATEX) --draftmode $(call texroot,$@) && $(MYPDFLATEX) $(call texroot,$@)
	if [ "$@" != "$(call texroot,$@).pdf" ]; then mv "$(call texroot,$@).pdf" "$@"; fi

clean: cleanlatex cleanfigs cleanlatexsrc

cleanlatex:
	rm -f $(patsubst %.tex, %.aux, $(wildcard *.tex))
	rm -f $(foreach ext,.bbl .blg .log .dvi .nav .nlo .out .pdf .snm .spl .toc .vrb .glo .ist .xdy .gls .glg .ilg,$(patsubst %.tex,%$(ext),$(texsource)))
	rm -f $(texfinal)

cleanfigs:
	rm -rf figs/

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

