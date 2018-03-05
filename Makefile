PDFLATEX=pdflatex -output-directory=tmp/
BIBTEX=bibtex

all: build

build-to-tmp:
	@ mkdir -p tmp/
	@ ./convert_literate_files.sh makamcode generated
	@ $(PDFLATEX) main.tex
	@ $(BIBTEX) tmp/main.aux
	@ $(PDFLATEX) main.tex
	@ $(PDFLATEX) main.tex

build: build-to-tmp
	@ cp tmp/main.pdf .

docker-build:
	@ docker-compose run -e _UID=$(id -u) -e _GID=$(id -g) -w /code texlive make build-to-tmp fix-permissions
	@ cp tmp/main.pdf .

fix-permissions:
	@ chown $$_UID:$$_GID generated/* tmp/* generated tmp

clean:
	@ rm -rf tmp/
	@ rm -f *.pdf

tmpclean:
	@ rm -rf tmp/

watch:
	@ shared/watch-pdflatex -c main.tex
	@ shared/watch-pdflatex main.tex

test:
	@ bash -c "set -e; for i in makamcode/*.md; do makam --run-tests \$$i; done"

.PHONY: all build build-to-tmp clean tmpclean watch test docker-build
