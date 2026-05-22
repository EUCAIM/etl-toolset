FROM harbor.eucaim-node.i3m.upv.es/library/ubuntu-python-tensorflow-desktop:3.17

LABEL name="desktop"
LABEL description="Container with ubuntu 22.04, python 3.10.6, lxde desktop, vnc and ssh services."

############## Things done by the root user ##############
USER root

# Install certutil to add the self-signed nifi cert to the firefox store
RUN apt update && \
    apt install -y --no-install-recommends libnss3-tools && \
    rm -rf /var/lib/apt/lists/*

COPY rootfs/usr /usr/
COPY --chown=ds:ds rootfs/home/ds /home/ds/

# - Add execution permission to the scripts
# - Autostart firefox with the web page of the nifi service
RUN chmod +x /home/ds/.init/startup_etl.sh /home/ds/.local/bin/open-nifi /home/ds/.local/bin/open-dbeaver \
 && echo '@/home/ds/.local/bin/open-nifi' >> /etc/xdg/lxsession/LXDE/autostart

## Install send etl logs
#RUN ...

#EXPOSE 8888

############### Now change to normal user ################
USER ds:ds
WORKDIR /home/ds
    

ENTRYPOINT ["/home/ds/.init/startup_etl.sh"]
