#!/usr/bin/env bash

#  根据 LOGTYPE 选择相应的 av_FS, av_FPAT


echo "configure: \$LOGTYPE: "$LOGTYPE

case ${LOGTYPE} in
    "iis" )
        av_FS=" "
        field_index_clientip=1
        field_index_httpstatus=7
        field_index_responsesize=8
        field_index_useragent=10
        ;;
    "apache" )
        av_FPAT="([^ ]+)|\"([^\"]+)\""
        field_index_clientip=1
        field_index_httpstatus=7
        field_index_responsesize=8
        field_index_useragent=10
        ;;
    *)
        echo "[*Error*] undefind LOGTYPE: $LOGTYPE. "
        echo "[tip]  You can define it in configure.sh as customer define"
esac

