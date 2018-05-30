FROM ocaml/opam:alpine_ocaml-4.06.0 as makam
RUN sudo apk update && sudo apk add git m4
RUN git clone https://github.com/astampoulis/makam.git makam-code
WORKDIR makam-code
# switch to makam version 0.7.9:
RUN git checkout 6fda1ca006e0c98a6b15dd4542548174964eee7a
RUN opam pin add makam . --no-action && opam install makam --deps-only && opam config exec make

FROM node:9-alpine
RUN apk update && apk add bash
RUN mkdir makam
COPY --from=makam /home/opam/makam-code/makam /home/opam/makam-code/nativerepl.native makam/
COPY --from=makam /home/opam/makam-code/stdlib makam/stdlib
RUN sed -i -e "s/%extend peg/(\* %extend peg/" -e 's/%use "syntax\/init"./%use "syntax.init". \*)/' makam/stdlib/init.makam
RUN ln -s $(pwd)/makam/makam /usr/local/bin/makam
ADD code /static

WORKDIR /static
CMD bash
