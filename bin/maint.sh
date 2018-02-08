#!/bin/bash
kill `ps -ef | grep 'defunct' | awk '{print $3}'` >/dev/null 2>&1
(ps -ef | grep -v grep | grep bbs.pl) || rm /opt/photonbbs/data/nodes/* >/dev/null 2>&1
(ps -ef | grep -v grep | grep bbs.pl) || rm /opt/photonbbs/data/messages/* >/dev/null 2>&1
