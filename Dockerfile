### PhotonBBS Container
###
### Building: docker image build -t photonbbs .
###
### Execution: docker container run -ti --net host --device=/dev/tty0 \
###                   --privileged -p 23:23 photonbbs
###
### TODO: Move /opt/photonbbs/data to a persistent volume.
###       Create a start script to start fail2ban and xinetd.
###       Figure out why libwrap isn't working in the container.
###

FROM centos:centos6
WORKDIR /

RUN yum -y install tcp_wrappers xinetd telnet-server perl git fail2ban
RUN yum -y install http://download1.rpmfusion.org/free/el/updates/6/i386/dosemu-1.4.0.8-15.20130205git.el6.i686.rpm

RUN chmod 0755 /opt
RUN cd /opt && git clone https://github.com/andrewwyatt/photonbbs.git

###
### Install the PhotonBBS Configuration files.
###

RUN cp /etc/skel/.* /opt/photonbbs ||:
RUN cp -rf /opt/photonbbs/configs/etc/cron.d/* /etc/cron.d
RUN cp -rf /opt/photonbbs/configs/etc/default/* /etc/default
RUN cp -rf /opt/photonbbs/configs/etc/xinetd.d/* /etc/xinetd.d
RUN cp -rf /opt/photonbbs/configs/etc/fail2ban /etc/fail2ban

###
### For some reason dosemu doesn't create the paths from inside the container
### but if they're created here, it works fine.
###

RUN mkdir -p /opt/photonbbs/.dosemu/drive_c
RUN mkdir -p /opt/photonbbs/.dosemu/drives
RUN ln -s /opt/photonbbs/.dosemu/drive_c /opt/photonbbs/.dosemu/drives/c
RUN ln -s /usr/share/dosemu/drive_z /opt/photonbbs/.dosemu/drives/d

###
### Some configuration changes (xinetd)
###

RUN sed -i 's#cps.*$#cps\t\t= 0 0#g' /etc/xinetd.conf
RUN sed -i 's#per_source.*$#per_source\t= 1#g' /etc/xinetd.conf

###
### Deviate from what's in the git repository until it can be updated.
###

RUN /usr/sbin/useradd -d /opt/photonbbs -s /opt/photonbbs/bbs.pl bbs
RUN chown -R bbs:bbs /opt/photonbbs
RUN chmod -R 755 /opt/photonbbs
RUN sed -i "s#REUSE#REUSE NOLIBWRAP#"g /etc/xinetd.d/photonbbs
RUN sed -i "s#service.*photonbbs#service telnet#g" /etc/xinetd.d/photonbbs
RUN sed -i "s#chat#bbs#g" /etc/xinetd.d/photonbbs

ENTRYPOINT ["/usr/sbin/xinetd", "-dontfork"]
