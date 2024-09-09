#!/bin/bash
oc new-project sriov-test
sleep 1
oc create sa priviledged-sa
oc adm policy add-scc-to-user privileged -z priviledged-sa

