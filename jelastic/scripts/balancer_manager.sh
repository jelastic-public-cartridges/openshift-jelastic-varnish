#!/bin/sh

source /etc/jelastic/environment;

function _set_neighbors(){
    return 0;
}

function _rebuild_common(){
    local RELOAD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16`;
    $CARTRIDGE_HOME/versions/$Version/usr/bin/varnishadm -T 127.0.0.1:81 -S $CARTRIDGE_HOME/secret vcl.load $RELOAD $CARTRIDGE_HOME/vcl/default.vcl > /dev/null 2>&1;
    $CARTRIDGE_HOME/versions/$Version/usr/bin/varnishadm -T 127.0.0.1:81 -S $CARTRIDGE_HOME/secret vcl.use $RELOAD > /dev/null 2>&1;
}

function _add_common_host(){
    local existing_host=`cat $CARTRIDGE_HOME/vcl/default.vcl | grep $host`;
    [ -n "$existing_host" ] && return 0;
    local host_num=`cat $CARTRIDGE_HOME/vcl/default.vcl | grep "backend serv" | awk '{print $2}' | sed 's/serv//g' | sort -n | tail -n1`;
    let "host_num+=1";
    sed -i '/import directors;/a backend serv'$host_num' { .host = "'${host}'"; .port = "80"; .probe = { .url = "\/"; .timeout = 30s; .interval = 60s; .window = 5; .threshold = 2;  .expected_response = 200; } }' $CARTRIDGE_HOME/vcl/default.vcl;
    sed -i '/new myclust = directors.*;/a myclust.add_backend(serv'$host_num', 1);' $CARTRIDGE_HOME/vcl/default.vcl;
    sed -i '/backend default { .host = "127.0.0.1"/d' $CARTRIDGE_HOME/vcl/default.vcl;
    local RELOAD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16`;
    $CARTRIDGE_HOME/versions/$Version/usr/bin/varnishadm -T 127.0.0.1:81 -S $CARTRIDGE_HOME/secret vcl.load $RELOAD $CARTRIDGE_HOME/vcl/default.vcl > /dev/null 2>&1;
    $CARTRIDGE_HOME/versions/$Version/usr/bin/varnishadm -T 127.0.0.1:81 -S $CARTRIDGE_HOME/secret vcl.use $RELOAD > /dev/null 2>&1;
}

function _remove_common_host(){
    local target_host=`cat $CARTRIDGE_HOME/vcl/default.vcl | grep ${host} | awk '{print $2}'`;
    [ -z "$target_host" ] && return 0;
    sed -i '/'${target_host}'/d' $CARTRIDGE_HOME/vcl/default.vcl;
    local least_hosts=`cat $CARTRIDGE_HOME/vcl/default.vcl | grep "backend serv"`;
    [ -z "$least_hosts" ] && sed -i '/import directors;/a backend default { .host = "127.0.0.1"; .port = "80"; }' $CARTRIDGE_HOME/vcl/default.vcl;
}

function _add_host_to_group(){
    return 0;
}

function _build_cluster(){
    return 0;
}

function _unbuild_cluster(){
    return 0;
}

function _clear_hosts(){
    return 0;
}

function _reload_configs(){
    return 0;
}
