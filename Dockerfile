FROM ubuntu:18.04
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
#RUN rm /usr/share/ca-certificates/mozilla/DST_Root_CA_X3.crt && \
# update-ca-certificates
#ENV REQUESTS_CA_BUNDLE "/etc/ssl/certs/ca-certificates.crt"

# Installing Neurodebian packages (FSL, AFNI, git)
# Pre-cache neurodebian key
#COPY neurodeb/neurodebian.gpg /usr/local/etc/neurodebian.gpg

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
#RUN curl -sSL "http://neuro.debian.net/lists/$( lsb_release -c | cut -f2 ).us-ca.full" >> /etc/apt/sources.list.d/neurodebian.sources.list && \
#    apt-key add /usr/local/etc/neurodebian.gpg && \
#    (apt-key adv --refresh-keys --keyserver hkp://ha.pool.sks-keyservers.net 0xA5D32F012649A5A9 || true)
#
#RUN apt-get update && \
#    apt-get install -y --no-install-recommends \
#                    fsl-core=5.0.9-5~nd16.04+1 \
#                    afni=16.2.07~dfsg.1-5~nd16.04+1 \
#                    git-annex-standalone && \
#    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
#
#ENV FSLDIR=/usr/share/fsl/5.0 \
#    PATH=/usr/share/fsl/5.0:${PATH} \
#    PATH=/usr/share/fsl/5.0/bin:${PATH} \
#    FSLOUTPUTTYPE="NIFTI_GZ" \
#    FSLMULTIFILEQUIT="TRUE" \
#    LD_LIBRARY_PATH="/usr/lib/fsl/5.0:$LD_LIBRARY_PATH"
#
#ENV AFNI_INSTALLDIR=/usr/lib/afni \
#    PATH=${PATH}:/usr/lib/afni/bin \
#    AFNI_PLUGINPATH=/usr/lib/afni/plugins \
#    AFNI_MODELPATH=/usr/lib/afni/models \
#    AFNI_TTATLAS_DATASET=/usr/share/afni/atlases \
#    AFNI_IMSAVE_WARNINGS=NO \
#    MRTRIX_NTHREADS=1 \
#    IS_DOCKER_8395080871=1


ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"
# FSL 6.0.5.1
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bc \
           dc \
           file \
           libfontconfig1 \
           libfreetype6 \
           libgl1-mesa-dev \
           libgl1-mesa-dri \
           libglu1-mesa-dev \
           libgomp1 \
           libice6 \
           libxcursor1 \
           libxft2 \
           libxinerama1 \
           libxrandr2 \
           libxrender1 \
           libxt6 \
           sudo \
           wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Downloading FSL ..." \
    && mkdir -p /opt/fsl-6.0.5.1 \
    && curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.5.1-centos7_64.tar.gz \
    | tar -xz -C /opt/fsl-6.0.5.1 --strip-components 1 \
    --exclude "fsl/config" \
    --exclude "fsl/data/atlases" \
    --exclude "fsl/data/first" \
    --exclude "fsl/data/mist" \
    --exclude "fsl/data/possum" \
    --exclude "fsl/data/standard/bianca" \
    --exclude "fsl/data/standard/tissuepriors" \
    --exclude "fsl/doc" \
    --exclude "fsl/etc/default_flobs.flobs" \
    --exclude "fsl/etc/fslconf" \
    --exclude "fsl/etc/js" \
    --exclude "fsl/etc/luts" \
    --exclude "fsl/etc/matlab" \
    --exclude "fsl/extras" \
    --exclude "fsl/include" \
    --exclude "fsl/python" \
    --exclude "fsl/refdoc" \
    --exclude "fsl/src" \
    --exclude "fsl/tcl" \
    --exclude "fsl/bin/FSLeyes" \
    && find /opt/fsl-6.0.5.1/bin -type f -not \( \
        -name "applywarp" -or \
        -name "bet" -or \
        -name "bet2" -or \
        -name "convert_xfm" -or \
        -name "fast" -or \
        -name "flirt" -or \
        -name "fsl_regfilt" -or \
        -name "fslhd" -or \
        -name "fslinfo" -or \
        -name "fslmaths" -or \
        -name "fslmerge" -or \
        -name "fslroi" -or \
        -name "fslsplit" -or \
        -name "fslstats" -or \
        -name "imtest" -or \
        -name "mcflirt" -or \
        -name "melodic" -or \
        -name "prelude" -or \
        -name "remove_ext" -or \
        -name "susan" -or \
        -name "topup" -or \
        -name "zeropad" \) -delete \
    && find /opt/fsl-6.0.5.1/data/standard -type f -not -name "MNI152_T1_2mm_brain.nii.gz" -delete
ENV FSLDIR="/opt/fsl-6.0.5.1" \
    PATH="/opt/fsl-6.0.5.1/bin:$PATH" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLLOCKDIR="" \
    FSLMACHINELIST="" \
    FSLREMOTECALL="" \
    FSLGECUDAQ="cuda.q" \
    LD_LIBRARY_PATH="/opt/fsl-6.0.5.1/lib:$LD_LIBRARY_PATH"

# AFNI latest (neurodocker build)
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           ed \
           gsl-bin \
           libglib2.0-0 \
           libglu1-mesa-dev \
           libglw1-mesa \
           libgomp1 \
           libjpeg62 \
           libxm4 \
           netpbm \
           tcsh \
           xfonts-base \
           xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sSL --retry 5 -o /tmp/multiarch.deb http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1.5_amd64.deb \
    && dpkg -i /tmp/multiarch.deb \
    && rm /tmp/multiarch.deb \
    && curl -sSL --retry 5 -o /tmp/libxp6.deb http://mirrors.kernel.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb \
    && dpkg -i /tmp/libxp6.deb \
    && rm /tmp/libxp6.deb \
    && curl -sSL --retry 5 -o /tmp/libpng.deb http://snapshot.debian.org/archive/debian-security/20160113T213056Z/pool/updates/main/libp/libpng/libpng12-0_1.2.49-1%2Bdeb7u2_amd64.deb \
    && dpkg -i /tmp/libpng.deb \
    && rm /tmp/libpng.deb \
    && apt-get install -f \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && gsl2_path="$(find / -name 'libgsl.so.19' || printf '')" \
    && if [ -n "$gsl2_path" ]; then \
         ln -sfv "$gsl2_path" "$(dirname $gsl2_path)/libgsl.so.0"; \
    fi \
    && ldconfig \
    && echo "Downloading AFNI ..." \
    && mkdir -p /opt/afni-latest \
    && curl -fsSL --retry 5 https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz \
    | tar -xz -C /opt/afni-latest --strip-components 1 \
    --exclude "linux_openmp_64/*.gz" \
    --exclude "linux_openmp_64/funstuff" \
    --exclude "linux_openmp_64/shiny" \
    --exclude "linux_openmp_64/afnipy" \
    --exclude "linux_openmp_64/lib/RetroTS" \
    --exclude "linux_openmp_64/meica.libs" \
    # Keep only what we use
    && find /opt/afni-latest -type f -not \( \
        -name "3dTshift" -or \
        -name "3dUnifize" -or \
        -name "3dAutomask" -or \
        -name "3dvolreg" \) -delete

ENV PATH="/opt/afni-latest:$PATH" \
    AFNI_IMSAVE_WARNINGS="NO" \
    AFNI_PLUGINPATH="/opt/afni-latest"

# Install ANTs 2.2.0 (NeuroDocker build)
ENV ANTSPATH=/usr/share/ants
RUN mkdir -p $ANTSPATH && \
    curl -sSL "https://dl.dropbox.com/s/2f4sui1z6lcgyek/ANTs-Linux-centos5_x86_64-v2.2.0-0740f91.tar.gz" \
   | tar -xzC $ANTSPATH --strip-components 1
ENV PATH=$ANTSPATH:$PATH

RUN echo "Downloading freesurfer"
# Installing freesurfer
COPY docker/files/freesurfer7.3-exclude.txt /usr/local/etc/freesurfer7.3-exclude.txt
RUN curl -sSL https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.3.2/freesurfer-linux-ubuntu20_amd64-7.3.2.tar.gz | tar zxv --no-same-owner -C /opt --exclude-from=/usr/local/etc/freesurfer7.3-exclude.txt

# Simulate SetUpFreeSurfer.sh
ENV FSL_DIR="/opt/fsl-6.0.5.1" \
    OS="Linux" \
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
 && pip install nilearn==0.10.1 \
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
RUN mkdir -p ${BASEDIR}/input

# Copy stuff over & change permissions
COPY neurodeb ${BASEDIR}/
COPY workflows/ ${BASEDIR}/workflows/
COPY batch_run.py ${BASEDIR}/
COPY check_zipped.sh ${BASEDIR}/
RUN chmod -R 777 ${BASEDIR}


# Configure entrypoints-
ENTRYPOINT ["python3 /opt/base/batch_run.py"]
