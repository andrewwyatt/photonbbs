#!/bin/bash
### Kill defunct processes
kill `ps -ef | grep 'defunct' | awk '{print $3}'` >/dev/null 2>&1
### Kill sleeping processes that are not associated to a connected user
kill `ps aux | grep "0:00 in.telnetd -h -n -L /opt/photonbbs/bbs.pl" | grep -v grep | awk '{print $2}'` >/dev/null 2>&1
### If nobody is logged in, remove node and message data
(ps -ef | grep -v grep | grep bbs.pl) || rm /opt/photonbbs/data/nodes/* >/dev/null 2>&1
(ps -ef | grep -v grep | grep bbs.pl) || rm /opt/photonbbs/data/messages/* >/dev/null 2>&1
