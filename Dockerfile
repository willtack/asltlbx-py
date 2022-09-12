FROM ubuntu:16.04
#FROM python:3.7

MAINTAINER Will Tackett <william.tackett@pennmedicine.upenn.edu>


# Prepare environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    curl \
                    bzip2 \
                    ca-certificates \
                    xvfb \
                    cython3 \
                    build-essential \
                    autoconf \
                    wget \
                    libtool \
                    pkg-config \
                    jq \
                    zip \
                    unzip \
                    nano \
                    zlib1g-dev \
                    default-jdk \
                    git && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends \
                    nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#Remove expired LetsEncrypt cert
RUN rm /usr/share/ca-certificates/mozilla/DST_Root_CA_X3.crt && \
 update-ca-certificates
ENV REQUESTS_CA_BUNDLE "/etc/ssl/certs/ca-certificates.crt"

# Installing Neurodebian packages (FSL, AFNI, git)
# Pre-cache neurodebian key
COPY neurodeb/neurodebian.gpg /usr/local/etc/neurodebian.gpg

#RUN curl -sSL "http://neuro.debian.net/lists/$( lsb_release -c | cut -f2 ).us-ca.full" >> /etc/apt/sources.list.d/neurodebian.sources.list && \
#    apt-key add /usr/local/etc/neurodebian.gpg && \
#    (apt-key adv --refresh-keys --keyserver hkp://ha.pool.sks-keyservers.net 0xA5D32F012649A5A9 || true)
#
#RUN apt-get update && \
#    apt-get install -y --no-install-recommends \
#                    fsl-core=5.0.9 \
#                    fsl-mni152-templates=5.0.7-2 \
#                    afni=16.2.07 \
#                    git-annex-standalone && \
#    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
#
#ENV FSLDIR=/usr/share/fsl/5.0 \
#    PATH=/usr/share/fsl/5.0:${PATH} \
#    PATH=/usr/share/fsl/5.0/bin:${PATH} \
#    FSLOUTPUTTYPE="NIFTI_GZ" \
#    FSLMULTIFILEQUIT="TRUE" \
#    LD_LIBRARY_PATH="/usr/lib/fsl/5.0:$LD_LIBRARY_PATH"

#ENV FSLDIR="/opt/fsl-6.0.3" \
#  PATH="/opt/fsl-6.0.3/bin:$PATH"
#RUN echo "Downloading FSL ..." \
#  && mkdir -p /opt/fsl-6.0.3 \
#  && curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.3-centos6_64.tar.gz \
#  | tar -xz -C /opt/fsl-6.0.3 --strip-components 1 \
#  --exclude='fsl/doc' \
#  --exclude='fsl/data/atlases' \
#  --exclude='fsl/data/possum' \
#  --exclude='fsl/src' \
#  --exclude='fsl/extras/src' \
#  --exclude='fsl/bin/fslview*' \
#  --exclude='fsl/bin/FSLeyes' \
#  && echo "Installing FSL conda environment ..." \
#  && sed -i -e "/fsleyes/d" -e "/wxpython/d" \
#     ${FSLDIR}/etc/fslconf/fslpython_environment.yml \
#  && bash /opt/fsl-6.0.3/etc/fslconf/fslpython_install.sh -f /opt/fsl-6.0.3 \
#  && find ${FSLDIR}/fslpython/envs/fslpython/lib/python3.7/site-packages/ -type d -name "tests"  -print0 | xargs -0 rm -r \
#  && ${FSLDIR}/fslpython/bin/conda clean --all

# Installing Neurodebian packages (FSL, AFNI, git)
RUN curl -sSL "http://neuro.debian.net/lists/$( lsb_release -c | cut -f2 ).us-ca.full" >> /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key add /usr/local/etc/neurodebian.gpg && \
    (apt-key adv --refresh-keys --keyserver hkp://ha.pool.sks-keyservers.net 0xA5D32F012649A5A9 || true)

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    fsl-core=5.0.9-5~nd16.04+1 \
                    afni=16.2.07~dfsg.1-5~nd16.04+1 \
                    git-annex-standalone && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV FSLDIR=/usr/share/fsl/5.0 \
    PATH=/usr/share/fsl/5.0:${PATH} \
    PATH=/usr/share/fsl/5.0/bin:${PATH} \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    LD_LIBRARY_PATH="/usr/lib/fsl/5.0:$LD_LIBRARY_PATH"

ENV AFNI_INSTALLDIR=/usr/lib/afni \
    PATH=${PATH}:/usr/lib/afni/bin \
    AFNI_PLUGINPATH=/usr/lib/afni/plugins \
    AFNI_MODELPATH=/usr/lib/afni/models \
    AFNI_TTATLAS_DATASET=/usr/share/afni/atlases \
    AFNI_IMSAVE_WARNINGS=NO \
    MRTRIX_NTHREADS=1 \
    IS_DOCKER_8395080871=1

# Installing ANTs latest from source
#ARG ANTS_SHA=e00e8164d7a92f048e5d06e388a15c1ee8e889c4
#ADD https://cmake.org/files/v3.11/cmake-3.11.4-Linux-x86_64.sh /cmake-3.11.4-Linux-x86_64.sh
#ENV ANTSPATH="/opt/ants-latest/bin" \
#    PATH="/opt/ants-latest/bin:$PATH" \
#    LD_LIBRARY_PATH="/opt/ants-latest/lib:$LD_LIBRARY_PATH"
#RUN mkdir /opt/cmake \
#  && sh /cmake-3.11.4-Linux-x86_64.sh --prefix=/opt/cmake --skip-license \
#  && ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake \
#  && apt-get update -qq \
#    && mkdir /tmp/ants \
#    && cd /tmp \
#    && git clone https://github.com/ANTsX/ANTs.git \
#    && mv ANTs /tmp/ants/source \
#    && cd /tmp/ants/source \
#    && git checkout ${ANTS_SHA} \
#    && mkdir -p /tmp/ants/build \
#    && cd /tmp/ants/build \
#    && mkdir -p /opt/ants-latest \
#    && git config --global url."https://".insteadOf git:// \
#    && cmake -DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/opt/ants-latest /tmp/ants/source \
#    && make -j2 \
#    && cd ANTS-build \
#    && make install \
#    && rm -rf /tmp/ants

#ENV PATH="${FSLDIR}/bin:$PATH"
#ENV FSLOUTPUTTYPE="NIFTI_GZ"

# Installing and setting up miniconda
RUN curl -sSLO https://repo.continuum.io/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh && \
    bash Miniconda3-4.5.11-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda3-4.5.11-Linux-x86_64.sh

ENV PATH=/usr/local/miniconda/bin:$PATH \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONNOUSERSITE=1

# Installing precomputed python packages
#RUN conda install -y python=3.7.1

RUN conda install -y python=3.7.4 \
                     pip=19.1 \
                     mkl=2018.0.3 \
                     mkl-service \
                     numpy=1.16.5 \
                     scipy=1.3.0 \
                     scikit-learn \
                     matplotlib \
                     pandas=0.23.4 \
                     libxml2=2.9.8 \
                     libxslt=1.1.32 \
                     graphviz=2.40.1 \
#                     traits=6.3.2 \
                     zlib; sync && \
    chmod -R a+rX /usr/local/miniconda; sync && \
    chmod +x /usr/local/miniconda/bin/*; sync && \
    conda build purge-all; sync && \
    conda clean -tipsy && sync


RUN pip install --upgrade pip
RUN pip install nibabel \
 && pip install transforms3d  \
 && pip install nipype==1.8.0 \
 && pip install traits==6.3.2 \
 && pip install pandas==0.23.4 \
 && pip install nilearn==0.8.0 \
 && pip install seaborn==0.11.1 \
 && pip install svgutils==0.3.4


# Install ANTs 2.2.0 (NeuroDocker build)
ENV ANTSPATH=/usr/share/ants
RUN mkdir -p $ANTSPATH && \
    curl -sSL "https://dl.dropbox.com/s/2f4sui1z6lcgyek/ANTs-Linux-centos5_x86_64-v2.2.0-0740f91.tar.gz" \
   | tar -xzC $ANTSPATH --strip-components 1
ENV PATH=$ANTSPATH:$PATH

# Install zip and jq
RUN apt-get install zip unzip -y
RUN apt-get install -y jq

# Make directory for code
ENV BASEDIR /opt/base
RUN mkdir -p ${BASEDIR}
RUN mkdir -p %{BASEDIR}/input

# Copy stuff over & change permissions
COPY neurodeb ${BASEDIR}/
COPY workflows/ ${BASEDIR}/workflows/
COPY batch_run.py ${BASEDIR}/
RUN chmod -R 777 ${BASEDIR}


# Configure entrypoints-
ENTRYPOINT ["python3 /opt/base/batch_run.py"]
