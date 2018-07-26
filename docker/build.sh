#!/bin/bash

###
### Create the persistent volume if it doesn't exist.
###

docker volume inspect appdata 2>&1 >/dev/null
if [ ! $? = 0 ]
then
  docker volume create appdata
fi

###
### Build the image
###

docker image build -t photonbbs .

###
### Describe how to start the container.
###

echo -e "\n\nTo use this container, run:\n\ndocker container run -dti --net host --device=/dev/tty0 -v appdata:/appdata:rw -v /dev:/dev -v /lib/modules:/lib/modules --privileged -p 23:23 photonbbs"
