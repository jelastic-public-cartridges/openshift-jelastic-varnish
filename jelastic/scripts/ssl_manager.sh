#!/bin/bash
#  $Id$
#  $Revision$
#  $Date$
#  $Author$
#  $HeadURL$

_SED=`which sed`;
_CAT=`which cat`;
SSL_XML_CONFIG="/etc/nginx/conf.d/ssl.conf";
DOMAIN_CERTIFICATE_FILE="/var/lib/jelastic/SSL/jelastic.crt";
CA_CERTIFICATE_FILE="/var/lib/jelastic/SSL/jelastic-ca.crt";
CHAIN_CERTIFICATE_FILE="/var/lib/jelastic/SSL/jelastic.chain";
SERVICE="nginx";
include output;

function createChain(){
[ -f $DOMAIN_CERTIFICATE_FILE ] && [ -f $CA_CERTIFICATE_FILE ] &&
        {
                $_CAT $DOMAIN_CERTIFICATE_FILE > $CHAIN_CERTIFICATE_FILE;
                echo "" >> $CHAIN_CERTIFICATE_FILE;
                $_CAT $CA_CERTIFICATE_FILE >> $CHAIN_CERTIFICATE_FILE;

        }
}

function removeChain(){
        [ -f $CHAIN_CERTIFICATE_FILE ] && rm -Rf $CHAIN_CERTIFICATE_FILE;
}


function _enableSSL(){
        local err;
        stopService ${SERVICE} > /dev/null 2>&1;
        doAction keystore DownloadKeys;
        err=$?; [[ ${err} -gt 0 ]] && exit ${err};
        createChain;
        sed  -i "/#sudo service nginx start.*/ s/#sudo/sudo/" /opt/repo/bin/control ||  { writeJSONResponceErr "result=>4020" "message=>Cannot enable SSL module!"; return 4020; };
        startService ${SERVICE} > /dev/null 2>&1;
}

function _disableSSL(){
        local err;
        stopService ${SERVICE} > /dev/null 2>&1;
        doAction keystore remove;
        err=$?; [[ ${err} -gt 0 ]] && exit ${err};
        sed  -i "/sudo service nginx start.*/ s/sudo/#sudo/" /opt/repo/bin/control ||  { writeJSONResponceErr "result=>4020" "message=>Cannot enable SSL module!"; return 4020; };
        removeChain;
}
