FROM pandoc/latex:latest
#RUN apk --no-cache add texlive-xetex texmf-dist-pictures texmf-dist-latexextra poppler-utils && texhash
ADD http://mirror.ctan.org/systems/texlive/tlnet/update-tlmgr-latest.sh /tmp
RUN sh /tmp/update-tlmgr-latest.sh -- --upgrade
RUN tlmgr update --self --all 
RUN tlmgr install ifoddpage tikzpagenodes blindtext textpos && luaotfload-tool -fu