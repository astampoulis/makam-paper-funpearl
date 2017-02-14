PDFLATEX=pdflatex -output-directory=tmp/
BIBTEX=bibtex


all:
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
