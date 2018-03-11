PDFLATEX=pdflatex -output-directory=tmp/ -file-line-error
BIBTEX=bibtex --terse

all: build

build-to-tmp:
	@ mkdir -p tmp/
	@ ./shared/convert_literate_files.sh makamcode generated
	@ $(PDFLATEX) main.tex
	@ $(BIBTEX) tmp/main.aux
	@ $(PDFLATEX) main.tex
	@ $(PDFLATEX) main.tex

build: build-to-tmp
	@ cp tmp/main.pdf .

docker-build:
	@ docker-compose run -e _UID=$(id -u) -e _GID=$(id -g) -w /code texlive bash -c 'cat /dev/null | make build-to-tmp fix-permissions'
	@ cp tmp/main.pdf .

fix-permissions:
	@ chown $$_UID:$$_GID generated/* tmp/* generated tmp

clean:
	@ rm -rf tmp/
	@ rm -f *.pdf

tmpclean:
	@ rm -rf tmp/

watch:
	@ (find makamcode -name \*.md; find . -name main.tex) | entr make test docker-build

test:
	@ ./shared/run_tests.sh

.PHONY: all build build-to-tmp clean tmpclean watch test docker-build
