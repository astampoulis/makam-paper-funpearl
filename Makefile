PDFLATEX=pdflatex -output-directory=tmp/ -file-line-error
BIBTEX=bibtex --terse

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
	@ bash -c "set -ex; for i in 01 02 03 04 05 06 07; do echo \"run_tests test\$$i ? \" | makam makamcode/\$$i-*.md -; done"

.PHONY: all build build-to-tmp clean tmpclean watch test docker-build
