FROM ocaml/opam:alpine_ocaml-4.06.0 as makam
RUN sudo apk update && sudo apk add git m4
RUN git clone https://github.com/astampoulis/makam.git makam-code # need 520ab701f9ae8b4beb56c53eaa22cdb776af5dc3
WORKDIR makam-code
# switch to makam version 0.7.13:
RUN git checkout 520ab701f9ae8b4beb56c53eaa22cdb776af5dc3
RUN opam pin add makam . --no-action && opam install makam --deps-only && opam config exec make

# Compile rlwrap for alpine, no package exists in the repositories
FROM alpine:3.6 as rlwrap
RUN apk update && apk add --update openssl build-base readline-dev ncurses-dev
RUN wget https://github.com/hanslub42/rlwrap/releases/download/v0.43/rlwrap-0.43.tar.gz && tar xvzf rlwrap-0.43.tar.gz
WORKDIR rlwrap-0.43
RUN ./configure && make && make install

FROM node:9-alpine
RUN apk update && apk add bash
RUN mkdir makam
COPY --from=makam /home/opam/makam-code/makam /home/opam/makam-code/nativerepl.native makam/
COPY --from=makam /home/opam/makam-code/stdlib makam/stdlib
COPY --from=rlwrap /usr/local/bin/rlwrap /usr/bin/rlwrap
RUN sed -i -e "s/%extend peg/(\* %extend peg/" -e 's/%use "syntax\/init"./%use "syntax\/init". \*)/' makam/stdlib/init.makam
RUN ln -s $(pwd)/makam/makam /usr/local/bin/makam
ADD code /static

WORKDIR /static
CMD bash
