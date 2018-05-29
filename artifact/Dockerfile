FROM ocaml/opam:alpine_ocaml-4.06.0 as makam
RUN sudo apk update && sudo apk add git m4
RUN git clone https://github.com/astampoulis/makam.git makam-code
WORKDIR makam-code
RUN git checkout 1b03c699c1d30b9a69d8c24ed4ccbf57cb695bc4
RUN opam pin add makam . --no-action && opam install makam --deps-only && opam config exec make

FROM node:9-alpine
RUN apk update && apk add bash
RUN mkdir makam
COPY --from=makam /home/opam/makam-code/makam /home/opam/makam-code/nativerepl.native makam/
COPY --from=makam /home/opam/makam-code/stdlib makam/stdlib
RUN sed -i -e "s/%extend peg/(\* %extend peg/" -e 's/%use "syntax\/init"./%use "syntax.init". \*)/' makam/stdlib/init.makam
RUN ln -s $(pwd)/makam/makam /usr/local/bin/makam
WORKDIR /code
CMD bash
