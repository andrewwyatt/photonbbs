### PhotonBBS Container
###
### Building: docker volume create appdata
###           docker image build -t photonbbs .
###
### Execution: docker container run -ti --net host --device=/dev/tty0 \
###                   -v appdata:/appdata:rw --privileged -p 23:23 photonbbs
###
### TODO: Figure out why libwrap isn't working in the container.
###
### Note: This container accepts parameters, pass 'bash' to start the container with a shell.
###

FROM centos:centos6
WORKDIR /

COPY appdeploy /
COPY startscript /

RUN bash /appdeploy

ENTRYPOINT [ "/startscript" ]
CMD []
