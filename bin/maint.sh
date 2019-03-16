#!/bin/bash
### Kill defunct processes
kill `ps -ef | grep '[d]efunct' | awk '{print $3}'` >/dev/null 2>&1
### Kill sleeping processes that are not associated to a connected user
kill `ps aux | grep "0:00 in.[t]elnetd.*/opt/photonbbs/bbs.pl" | awk '{print $2}'` >/dev/null 2>&1

### Check that node activity has occurred in the past 30 minutes or that the PID still exists.
IP=$(hostname -i)
TIME=$(date +%s)
TIMEOUT=1800

for node in /opt/photonbbs/data/nodes/*
do
  NIP=$(awk 'BEGIN {FS="|"}; {print $1}' ${node})
  NODE=$(awk 'BEGIN {FS="|"}; {print $2}' ${node})
  NPID=$(awk 'BEGIN {FS="|"}; {print $3}' ${node})
  NTIME=$(awk 'BEGIN {FS="|"}; {print $4}' ${node})

  if [ ${IP} == ${NIP} ]
  then

    ### Does this pid still exist?
    ps ${NPID} >/dev/null 2>&1
    if [ ! $? = 0 ]
    then
      rm -f /opt/photonbbs/data/nodes/${NODE}
      rm -f /opt/photonbbs/data/messages/${NODE}.page
      rm -f /opt/photonbbs/data/messages/TELEPUB_/${NODE}
      rm -f $(find /opt/photonbbs/data/messages/teleconf -type f -name ${NODE})
    else
      ### Has the process exceeded the timeout period?
      TIMECHK=$( expr ${TIME} - ${NTIME} )
      if (( ${TIMECHK} > ${TIMEOUT} ))
      then
        kill -HUP $NPID
        rm -f /opt/photonbbs/data/nodes/${NODE}
        rm -f /opt/photonbbs/data/messages/${NODE}.page
        rm -f /opt/photonbbs/data/messages/TELEPUB_/${NODE}
        rm -f $(find /opt/photonbbs/data/messages/teleconf -type f -name ${NODE})
      fi
    fi
  fi
done
