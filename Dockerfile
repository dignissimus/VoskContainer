FROM ubuntu:22.04
WORKDIR /model
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git intel-mkl make gcc g++ python3-pip zlib1g zlib1g-dev automake sox gfortran libtool subversion python2.7 python3-pip wget unzip
RUN pip3 install phonetisaurus
RUN git clone https://github.com/dignissimus/SRILM
RUN make -C SRILM SRILM=$(pwd)/SRILM
RUN for file in SRILM/bin/**/* ; do if [ -f "$file" ]; then cp "$file" /usr/bin ; fi done
RUN rm -rf SRILM
RUN git clone https://github.com/alphacep/kaldi -b vosk
WORKDIR /model/kaldi/tools/
RUN make -j6
WORKDIR /model/kaldi/tools/openfst/
RUN ./configure --enable-static --enable-shared --enable-far --enable-ngram-fsts --enable-lookahead-fsts --with-pic --disable-bin
RUN make
WORKDIR /model/kaldi/tools/
RUN ./extras/install_opengrm.sh
WORKDIR /model/kaldi/src
RUN ./configure --shared && make depend -j6 && make -j6
WORKDIR /model/

# Model compilation
RUN wget https://alphacephei.com/vosk/models/vosk-model-en-us-0.22-compile.zip
RUN unzip vosk-model-en-us-0.22-compile.zip && rm vosk-model-en-us-0.22-compile.zip
WORKDIR /model/vosk-model-en-us-0.22-compile/

# Speed up build for testing
RUN sed -i 's/-order 4/-order 1/g' compile-graph.sh
RUN ./compile-graph.sh
