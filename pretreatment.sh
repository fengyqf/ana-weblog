#!/usr/bin/env bash


# 脚本说明
# 对原始的web日志预处理，整理成统一的格式，用于使用同一套处理代码分析
# 通过传递参数-t 指定日志类型，
#   供选值：iis,iis-extend,apache,apache-combined
#           apache-combinedio,apache-common
#       (暂未全部实现) TODO
#   如果有其它格式的日志，参考已实现格式自行实现
# 输出格式
#   默认不输出表头字段名
#


# 参数列表
#   -t      type, 日志文件类型，指定数字编号，供选值参看下面case .... esac
#   -d      debug, 输出调试信息 dbg
#   -h      header, 输出表头字段名；默认不输出




MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

dbg=0
#echo "init OPTIND:" $OPTIND
while getopts "t:dh" arg
do
    case $arg in
        t)
            logtype_name=$OPTARG
            ;;
        h)
            output_header="Y"
            ;;
        d)
            dbg=1
            ;;
        ?)
    esac
done
shift $((OPTIND-1))
log_filepath=$@


if [[ ! -f $log_filepath ]]; then
    echo -e "\n[Error] log file ["$log_filepath"] not found."
    exit 501;
fi


#检查awk版本号，必须是gawk 4.x版本
#  TODO: gawk版本检测的测试
#  如下的检测命令，只在cygwin上通过，其它平台未测试，待测试
awk_test=`awk -V |head -1 |awk 'BEGIN{FS=",";IGNORECASE=1} $1 ~ /GNU awk 4\..*/ {print $1}'`
if [[ -z awk_test ]]; then
    echo "[Error] require gawk 4.0+"
    echo "You can comment the below line, but as your risk."
    exit 502
fi


if [ "${dbg}" == "1" ]; then
    echo ""
    echo "---- [$(basename $0)] debug---------"
   echo "logtype_name:         ["$logtype_name"]"
    echo "---- debug done ---------"
    echo ""
fi

if [ "${dbg}" == "1" -o "$output_header" == "Y" ]; then
    #输出表头字段名
    awk 'BEGIN{
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
                ,"clientip","method","url" \
                ,"status","refer","useragent" \
                ,"request_bytes","response_bytes","time_taken" \
                ,"time"
    }'
fi


if [[ "$logtype_name" == "iis" || "$logtype_name" == "iis-extend" ]]; then
    awk -F" " \
    'BEGIN{
        field_index_clientip=10
        field_index_method=5
        field_index_url=6
        field_index_http_status=14
        field_index_refer=12
        field_index_useragent=11
        field_index_request_bytes=18
        field_index_response_bytes=17
        field_index_time_taken=19
    }
    NR >5 || (NR < 5 && $1 !~ /^#.*/) {
            #日期/时间恒定位于1-2列
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s %s\n" \
                ,$field_index_clientip,$field_index_method,$field_index_url \
                ,$field_index_http_status,$field_index_refer,$field_index_useragent \
                ,$field_index_request_bytes,$field_index_response_bytes,$field_index_time_taken \
                ,$1,$2
    }' $log_filepath

elif [[ "$logtype_name" == "apache" || "$logtype_name" == "apache-combined" ]]; then
    awk 'BEGIN{
        FPAT="([^ ]+)|\"([^\"]+)\""

        field_index_clientip=1
        field_index_http_status=7
        fv_refer="-"                    #field_index_refer=9999
        field_index_useragent=10
        vf_bytes="-"                    #field_index_request_bytes=9999
        field_index_response_bytes=11
        vf_time_taken="-"               #field_index_time_taken=9999
    }
    {
        split(substr($6,2,length($6)-2),apache_r_piece," ")
        method=apache_r_piece[1]
        url=apache_r_piece[2]
        http_version=apache_r_piece[3]


        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s %s\n" \
            ,$field_index_clientip,method,url \
            ,$field_index_http_status,fv_refer,$field_index_useragent \
            ,vf_bytes,$field_index_response_bytes,vf_time_taken \
            ,$4,$5
    }
    ' $log_filepath
else
    echo "known logtype_name: $logtype_name"
fi








# 清理临时文件
#rm tmp_xxx.txt



