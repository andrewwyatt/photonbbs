#!/bin/bash
(ps -ef | grep -v grep | grep bbs.pl) || rm /opt/photonbbs/data/nodes/* 2>&1 >/dev/null
(ps -ef | grep -v grep | grep bbs.pl) || rm /opt/photonbbs/data/messages/* 2>&1 >/dev/null
