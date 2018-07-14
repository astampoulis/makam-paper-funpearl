PDFLATEX=pdflatex -output-directory=tmp/ -file-line-error
BIBTEX=bibtex --terse

all: build

build-to-tmp:
	@ mkdir -p tmp/
	@ ./shared/convert-literate-files.sh makamcode generated
	@ ./shared/convert-justcode.sh
	# @ shuf -n1 /usr/share/dict/words > generated/randomword.tex
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
	@ chown $$_UID:$$_GID generated/* justcode/* tmp/* generated justcode tmp

clean:
	@ rm -rf tmp/
	@ rm -f *.pdf

tmpclean:
	@ rm -rf tmp/

watch:
	@ (find makamcode -name \*.md; find . -name main.tex) | entr make test docker-build

watch-test:
	@ (find makamcode -name \*.md; find . -name main.tex) | entr make test

watch-build:
	@ (find makamcode -name \*.md; find . -name main.tex; find . -name makam-codemirror.js) | entr make docker-build

test:
	@ ./shared/run_tests.sh

test-artifact:
	@ rm -rf tmp/makam-funpearl-artifact/
	@ tar xvzf makam-funpearl-artifact.tgz -C tmp/
	@ tmp/makam-funpearl-artifact/run-makam.sh --run-tests literate/10-typgen.md
	@ tmp/makam-funpearl-artifact/run-makam.sh --run-tests 10-typgen

test-artifact-ci:
	@ rm -rf tmp/makam-funpearl-artifact/
	@ mkdir -p tmp/
	@ tar xvzf makam-funpearl-artifact.tgz -C tmp/
	@ tmp/makam-funpearl-artifact/run-makam.sh --run-tests /static/init /static/literate/10-typgen.md
	@ tmp/makam-funpearl-artifact/run-makam.sh --run-tests /static/init 10-typgen

artifact:
	@ ./shared/build-artifact.sh

sourcezip:
	@ rm -f source.zip
	@ bash -c "zip source.zip main.tex main.bib generated/{01*,02*,03*,04*,05-gadts,06-patterns,07*,08*,09*,10*,11*,12*}.tex acmart.cls shared/ACM-Reference-Format.bst"

.PHONY: all build build-to-tmp clean tmpclean watch test docker-build watch-test watch-build artifact sourcezip
