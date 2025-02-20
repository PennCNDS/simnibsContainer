FROM ubuntu:22.04

RUN apt-get update && \
    apt-get upgrade -y --with-new-pkgs && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/downloads /opt/install

WORKDIR /opt/install

RUN wget -O /opt/downloads/simnibs_installer_linux.tar.gz \
        https://github.com/simnibs/simnibs/releases/download/v4.1.0/simnibs_installer_linux.tar.gz && \
    tar -xzf /opt/downloads/simnibs_installer_linux.tar.gz && \
    simnibs_installer/install -s -t /opt/SimNIBS-4.1 && \
    rm -rf /opt/install /opt/downloads

ENTRYPOINT ["/bin/bash"]
