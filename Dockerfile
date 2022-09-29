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

# Install ANTs 2.2.0 (NeuroDocker build)
ENV ANTSPATH=/usr/share/ants
RUN mkdir -p $ANTSPATH && \
    curl -sSL "https://dl.dropbox.com/s/2f4sui1z6lcgyek/ANTs-Linux-centos5_x86_64-v2.2.0-0740f91.tar.gz" \
   | tar -xzC $ANTSPATH --strip-components 1
ENV PATH=$ANTSPATH:$PATH

# Installing freesurfer
COPY docker/files/freesurfer7.2-exclude.txt /usr/local/etc/freesurfer7.2-exclude.txt
RUN curl -sSL https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.2.0/freesurfer-linux-ubuntu18_amd64-7.2.0.tar.gz | tar zxv --no-same-owner -C /opt --exclude-from=/usr/local/etc/freesurfer7.2-exclude.txt

# Simulate SetUpFreeSurfer.sh
ENV OS="Linux" \
    FS_OVERRIDE=0 \
    FIX_VERTEX_AREA="" \
    FSF_OUTPUT_FORMAT="nii.gz" \
    FREESURFER_HOME="/opt/freesurfer"
ENV SUBJECTS_DIR="$FREESURFER_HOME/subjects" \
    FUNCTIONALS_DIR="$FREESURFER_HOME/sessions" \
    MNI_DIR="$FREESURFER_HOME/mni" \
    LOCAL_DIR="$FREESURFER_HOME/local" \
    MINC_BIN_DIR="$FREESURFER_HOME/mni/bin" \
    MINC_LIB_DIR="$FREESURFER_HOME/mni/lib" \
    MNI_DATAPATH="$FREESURFER_HOME/mni/data"
ENV PERL5LIB="$MINC_LIB_DIR/perl5/5.8.5" \
    MNI_PERL5LIB="$MINC_LIB_DIR/perl5/5.8.5" \
    PATH="$FREESURFER_HOME/bin:$FREESURFER_HOME/tktools:$MINC_BIN_DIR:$PATH"


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
 && pip install svgutils==0.3.4 \
 && pip install pathlib \
 && pip install flywheel-sdk==12.4.0


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
COPY check_zipped.sh ${BASEDIR}/
RUN chmod -R 777 ${BASEDIR}


# Configure entrypoints-
ENTRYPOINT ["python3 /opt/base/batch_run.py"]
