PDFLATEX=pdflatex -output-directory=tmp/
BIBTEX=bibtex

all:
	@ mkdir -p tmp/
	@ ./convert_literate_files.sh makamcode generated
	@ $(PDFLATEX) main.tex
	@ $(BIBTEX) tmp/main.aux
	@ $(PDFLATEX) main.tex
	@ $(PDFLATEX) main.tex
	@ cp tmp/main.pdf .

clean:
	@ rm -rf tmp/
	@ rm -f *.pdf

tmpclean:
	@ rm -rf tmp/

watch:
	@ shared/watch-pdflatex -c main.tex
	@ shared/watch-pdflatex main.tex

.PHONY: all clean tmpclean watch
