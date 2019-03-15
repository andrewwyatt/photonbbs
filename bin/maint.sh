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
      rm /opt/photonbbs/data/{nodes,messages}/${node} >/dev/null 2>&1
    fi

    ### Has the process exceeded the timeout period?
    TIMECHK=$( expr ${TIME} - ${NTIME} )
    if (( ${TIMECHK} > ${TIMEOUT} ))
    then
      kill -HUP $NPID
      rm /opt/photonbbs/data/{nodes,messages}/${node} >/dev/null 2>&1
    fi
  fi
done

### If nobody is logged in, remove node and message data
(ps -ef | grep [b]bs.pl) || rm /opt/photonbbs/data/{nodes,messages}/* >/dev/null 2>&1
