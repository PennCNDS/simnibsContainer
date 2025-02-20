FROM ubuntu:22.04

RUN apt-get update && \
    apt-get upgrade -y --with-new-pkgs && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /opt/downloads /opt/install && \
    useradd -m simnibs && \
    chown simnibs /opt/downloads /opt/install

WORKDIR /opt/install

USER simnibs

RUN wget -O /opt/downloads/simnibs_installer_linux.tar.gz \
        https://github.com/simnibs/simnibs/releases/download/v4.1.0/simnibs_installer_linux.tar.gz && \
    tar -xzf /opt/downloads/simnibs_installer_linux.tar.gz && \
    simnibs_installer/install -s && \
    rm -rf /opt/install/* /opt/downloads/*

WORKDIR /home/simnibs

ENTRYPOINT ["/bin/bash"]
