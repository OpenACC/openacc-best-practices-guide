FROM ubuntu:18.04
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt update &&                            \
    apt dist-upgrade -y &&                   \
    apt install -y locales &&                \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen &&                            \
    export LANG=en_US.UTF-8 &&               \
    export LANGUAGE=en_US:en &&              \
    export LC_ALL=en_US.UTF-8 &&             \
    apt install -y                           \
                pandoc pandoc-citeproc       \
                texlive-latex-base           \
                python-pygments make         \
                texlive-latex-extra          \
                ca-certificates              \
                texlive-fonts-recommended && \
    rm -rf /var/lib/apt/lists/* 
WORKDIR /work
CMD /bin/bash
