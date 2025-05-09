#
# Dockerfile for SimNIBS with AFNI and FSL flirt
# Based on fmriprep / simnibs installer but with updated FreeSurfer and SimNIBS
#
ARG BASE_IMAGE=ubuntu:jammy


#
# Download stages
#

# Utilities for downloading packages
FROM ${BASE_IMAGE} AS downloader
# Bump the date to current to refresh curl/certificates/etc
RUN echo "2024.02.25"
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    binutils \
                    bzip2 \
                    ca-certificates \
                    curl \
                    unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# FreeSurfer 8
FROM downloader AS freesurfer
RUN mkdir /opt/tmp \
      && curl -sSL https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/8.0.0/freesurfer_ubuntu22-8.0.0_amd64.deb > /opt/tmp/freesurfer.deb \
      && dpkg-deb -x /opt/tmp/freesurfer.deb /opt/tmp/freesurfer

COPY docker/files/freesurfer8.0.0-exclude.txt /usr/local/etc/freesurfer8.0.0-exclude.txt

RUN cd /opt/tmp/freesurfer/usr/local \
    && rm -rf $(cat /usr/local/etc/freesurfer8.0.0-exclude.txt) \
    && mv /opt/tmp/freesurfer/usr/local/freesurfer/8.0.0 /opt/freesurfer \
    && rm -rf /opt/tmp

# Patch FS 8.0.0
# https://surfer.nmr.mgh.harvard.edu/fswiki/ReleaseNotes
RUN curl -sSL https://raw.githubusercontent.com/freesurfer/freesurfer/refs/heads/dev/scripts/csvprint > /opt/freesurfer/bin/csvprint

# AFNI
FROM downloader AS afni
# Bump the date to current to update AFNI
RUN echo "2024.03.12"
RUN mkdir -p /opt/afni-latest \
    && curl -fsSL --retry 5 https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz \
    | tar -xz -C /opt/afni-latest --strip-components 1 \
    --exclude "linux_openmp_64/*.gz" \
    --exclude "linux_openmp_64/funstuff" \
    --exclude "linux_openmp_64/shiny" \
    --exclude "linux_openmp_64/afnipy" \
    --exclude "linux_openmp_64/lib/RetroTS" \
    --exclude "linux_openmp_64/lib_RetroTS" \
    --exclude "linux_openmp_64/meica.libs"


# Micromamba
FROM downloader AS micromamba

# Install a C compiler to build extensions when needed.
# traits<6.4 wheels are not available for Python 3.11+, but build easily.
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /
# Bump the date to current to force update micromamba
RUN echo "2024.02.06"
RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba

ENV MAMBA_ROOT_PREFIX="/opt/conda"
COPY env.yml /tmp/env.yml
WORKDIR /tmp
RUN micromamba create -y -f /tmp/env.yml && \
    micromamba clean -y -a

#
# Main stage
#
FROM ${BASE_IMAGE} AS runtime

# Configure apt
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

# Some baseline tools; bc is needed for FreeSurfer, so don't drop it
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    bc \
                    ca-certificates \
                    curl \
                    git \
                    gnupg \
                    lsb-release \
                    netbase \
                    xvfb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure PPAs for libpng12 and libxp6
RUN GNUPGHOME=/tmp gpg --keyserver hkps://keyserver.ubuntu.com --no-default-keyring --keyring /usr/share/keyrings/linuxuprising.gpg --recv 0xEA8CACC073C3DB2A \
    && GNUPGHOME=/tmp gpg --keyserver hkps://keyserver.ubuntu.com --no-default-keyring --keyring /usr/share/keyrings/zeehio.gpg --recv 0xA1301338A3A48C4A \
    && echo "deb [signed-by=/usr/share/keyrings/linuxuprising.gpg] https://ppa.launchpadcontent.net/linuxuprising/libpng12/ubuntu jammy main" > /etc/apt/sources.list.d/linuxuprising.list \
    && echo "deb [signed-by=/usr/share/keyrings/zeehio.gpg] https://ppa.launchpadcontent.net/zeehio/libxp/ubuntu jammy main" > /etc/apt/sources.list.d/zeehio.list

# Dependencies for AFNI; requires a discontinued multiarch-support package from bionic (18.04)
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           ed \
           gsl-bin \
           libglib2.0-0 \
           libglu1-mesa-dev \
           libglw1-mesa \
           libgomp1 \
           libjpeg62 \
           libpng12-0 \
           libxm4 \
           libxp6 \
           netpbm \
           tcsh \
           xfonts-base \
           xvfb \
    && curl -sSL --retry 5 -o /tmp/multiarch.deb http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1.5_amd64.deb \
    && dpkg -i /tmp/multiarch.deb \
    && rm /tmp/multiarch.deb \
    && apt-get install -f \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && gsl2_path="$(find / -name 'libgsl.so.19' || printf '')" \
    && if [ -n "$gsl2_path" ]; then \
         ln -sfv "$gsl2_path" "$(dirname $gsl2_path)/libgsl.so.0"; \
    fi \
    && ldconfig

# Install files from stages
COPY --from=freesurfer /opt/freesurfer /opt/freesurfer
COPY --from=afni /opt/afni-latest /opt/afni-latest

# Simulate SetUpFreeSurfer.sh
ENV OS="Linux" \
    FS_OVERRIDE=0 \
    FIX_VERTEX_AREA="" \
    FSF_OUTPUT_FORMAT="nii.gz" \
    FREESURFER="/opt/freesurfer"
ENV FREESURFER_HOME="${FREESURFER}" \
    FREESURFER_HOME_FSPYTHON="${FREESURFER}"
ENV SUBJECTS_DIR="${FREESURFER_HOME}/subjects" \
    FUNCTIONALS_DIR="${FREESURFER_HOME}/sessions" \
    MNI_DIR="${FREESURFER_HOME}/mni" \
    LOCAL_DIR="${FREESURFER_HOME}/local" \
    MINC_BIN_DIR="${FREESURFER_HOME}/mni/bin" \
    MINC_LIB_DIR="${FREESURFER_HOME}/mni/lib" \
    MNI_DATAPATH="${FREESURFER_HOME}/mni/data"
ENV PERL5LIB="$MINC_LIB_DIR/perl5/5.8.5" \
    MNI_PERL5LIB="$MINC_LIB_DIR/perl5/5.8.5" \
    PATH="${FREESURFER_HOME}/bin:${FREESURFER_HOME}/tktools:$MINC_BIN_DIR:$PATH"

# AFNI config
ENV PATH="/opt/afni-latest:$PATH" \
    AFNI_IMSAVE_WARNINGS="NO" \
    AFNI_PLUGINPATH="/opt/afni-latest"

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users simnibs
WORKDIR /home/simnibs
ENV HOME="/home/simnibs" \
    LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

COPY --from=micromamba /bin/micromamba /bin/micromamba
COPY --from=micromamba /opt/conda/envs/simnibs_env /opt/conda/envs/simnibs_env

ENV MAMBA_ROOT_PREFIX="/opt/conda"
RUN micromamba shell init -s bash && \
    echo "micromamba activate simnibs_env" >> $HOME/.bashrc
ENV PATH="/opt/conda/envs/simnibs_env/bin:$PATH" \
    CPATH="/opt/conda/envs/simnibs_env/include:$CPATH" \
    LD_LIBRARY_PATH="/opt/conda/envs/simnibs_env/lib:$LD_LIBRARY_PATH"

# FSL environment
ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    PYTHONNOUSERSITE=1 \
    FSLDIR="/opt/conda/envs/simnibs" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLLOCKDIR="" \
    FSLMACHINELIST="" \
    FSLREMOTECALL="" \
    FSLGECUDAQ="cuda.q"

RUN find $HOME -type d -exec chmod go=u {} + && \
    find $HOME -type f -exec chmod go=u {} + && \
    rm -rf $HOME/.npm $HOME/.conda $HOME/.empty

RUN ldconfig
WORKDIR /tmp

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="cnds-simnibs" \
      org.label-schema.description="CNDS simnibs container" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/PennCNDS/simnibsContainer" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

WORKDIR /home/simnibs

# Copy efield scripts
COPY ef_code /opt/ef_code

ENV PATH=/opt/ef_code/bin:$PATH

ENTRYPOINT ["/bin/bash"]
