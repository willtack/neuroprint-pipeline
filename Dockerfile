FROM python:3.7
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
                    libtool \
                    pkg-config \
                    jq \
                    zip \
                    unzip \
                    bc \
                    nano \
                    libglu1 \
                    default-jdk \
                    git && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends \
                    nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install ANTs 2.2.0 (NeuroDocker build)
ENV ANTSPATH=/usr/share/ants
RUN mkdir -p $ANTSPATH && \
    curl -sSL "https://dl.dropbox.com/s/2f4sui1z6lcgyek/ANTs-Linux-centos5_x86_64-v2.2.0-0740f91.tar.gz" \
   | tar -xzC $ANTSPATH --strip-components 1
ENV PATH=$ANTSPATH:$PATH

# Install python packages
RUN pip install --no-cache flywheel-sdk==12.4.0 \
 && pip install --no-cache jinja2==2.10 \
 && pip install --no-cache nilearn==0.9.2 \
 && pip install --no-cache pathlib==1.0.1 \
 && pip install --no-cache matplotlib==3.03 \
 && pip install --no-cache antspyx==0.3.3 \
 && pip install --no-cache pytest==4.3.1 \
 && pip install --no-cache scikit-learn==0.22 \
 && pip install --no-cache pandas==1.2.3 \
 && pip install --no-cache numpy==1.20.1

# Install FSL
#ENV FSLDIR="/usr/share/fsl"
#RUN apt-get update -qq \
#  && apt-get install -y -q --no-install-recommends \
#         bc \
#         dc \
#         file \
#         libfontconfig1 \
#         libfreetype6 \
#         libgl1-mesa-dev \
#         libglu1-mesa-dev \
#         libgomp1 \
#         libice6 \
#         libxcursor1 \
#         libxft2 \
#         libxinerama1 \
#         libxrandr2 \
#         libxrender1 \
#         libxt6 \
#         wget \
#  && apt-get clean \
#  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
#  && echo "Downloading FSL ..." \
#  && mkdir -p /usr/share/fsl \
#  && curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-5.0.9-centos6_64.tar.gz \
#  | tar -xz -C /usr/share/fsl --strip-components 1

#ENV PATH="${FSLDIR}/bin:$PATH"
#ENV FSLOUTPUTTYPE="NIFTI_GZ"

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
        -name "cluster" -or \
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



# Install workbench
#ENV WBPATH=/usr/share/workbench
#RUN curl -ssL -o ${WBPATH}.zip "https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.5.0.zip"
#RUN unzip ${WBPATH}.zip -d /usr/share
#ENV PATH=$WBPATH/bin_linux64:$PATH

# Install r
RUN apt-get update && apt-get install -y r-base

ENV C3DDIR="/usr/share/c3d/bin"
RUN mkdir -p ${C3DDIR}
COPY resources/c3d/bin ${C3DDIR}/
ENV PATH="${C3DDIR}:$PATH"

# Move files
RUN mkdir /opt/scripts
COPY run.py /opt/scripts/run.py
RUN chmod +x /opt/scripts/*

RUN mkdir -p /opt/labelset
COPY labelset /opt/labelset

COPY wscore_eq.sh /opt/wscore_eq.sh

RUN mkdir /input
RUN mkdir /output

RUN mkdir -p /opt/rendering
COPY rendering /opt/rendering
COPY resources /opt/resources
RUN chmod +x /opt/rendering/*

RUN mkdir -p /opt/model
COPY model/* /opt/model/
RUN chmod +x /opt/model/*

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/python", "/opt/scripts/run.py"]
