#!/usr/bin/env bash



# client_ip.sh [OPTION]... [FILE]...

# 参数列表
#   -t      type, 日志文件类型，供选值 iis, apache
#   -s      separate 字段分隔符 av_FS
#   -p      pattern, 字段模式 av_FPAT
#   -f      field, 字段编号位置 av_FIELD_INDEX
#   -d      debug, 输出调试信息 dbg

dbg=0
#echo "init OPTIND:" $OPTIND
while getopts "t:s:p:f:d" arg
do
    case $arg in
        t)
            av_LOGTYPE=$OPTARG
            ;;
        s)
            av_FS=$OPTARG
            ;;
        p)
            av_FPAT=$OPTARG
            ;;
        f)
            av_FIELD_INDEX=$OPTARG
            ;;
        d)
            dbg=1
            ;;
        ?)
    esac
done

LOGTYPE=$av_LOGTYPE

if [ "${dbg}" == "1" ]; then
    echo "---- debug ---------"
    echo "av_LOGTYPE:        ["$av_LOGTYPE"]"
    echo "av_FS:             ["$av_FS"]"
    echo "av_FPAT:           ["$av_FPAT"]"
    echo "av_FIELD_INDEX:    ["$av_FIELD_INDEX"]"
    echo "---- debug done ---------"
fi


#if [ "${av_FS}" == "  " ]; then
#    echo 'av_FS is blank'
#else
#    echo "av_FS not"
#fi


shift $((OPTIND-1))

#for file in $@
#do
#    echo "file: " $file
#done

if [ -n "${av_LOGTYPE}" ]; then
    parameters="-v av_LOGTYPE=\""$av_LOGTYPE"\""
elif [ -n "${av_FS}" ]; then
    parameters="-v av_FS=\""$av_FS"\""
elif [ -n "${av_FPAT}" ]; then
    parameters="-v av_FPAT=\""$av_FPAT"\""
elif [ -n "${av_FIELD_INDEX}" ]; then
    parameters="-v av_FIELD_INDEX=\""$av_FIELD_INDEX"\""
fi

echo $parameters


MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"





# 总记录条数
log_filepath=$@


echo "log file log_filepath: "$log_filepath

if [[ ! -f $log_filepath ]]; then
    echo "[Error] log file ["$log_filepath"] not found."
    exit 501;
fi


#检查awk版本号，必须是gawk 4.x版本
#  TODO: gawk版本检测的测试
#  如下的检测命令，只在cygwin上通过，其它平台未测试，待测试
awk_test=`awk -V |head -1 |awk 'BEGIN{FS=",";IGNORECASE=1} $1 ~ /GNU awk 4\..*/ {print $1}'`
if [[ -z awk_test ]]; then
    echo "[Error] require gawk 4.0+"
    echo "You can comment the below line, but as you risk."
    exit 502
fi



#定义web日志文件中字段位置
field_index_clientip=10
field_index_useragent=11
field_index_method=5
# url, withOUT get-querystring
field_index_url=6
field_index_refer=12
field_index_http_status=14
field_index_response_bytes=17
field_index_request_bytes=18
field_index_time_taken=19

#输出高频404地址时，从高到低覆盖范围百分比
not_found_url_output_rate=80
http_500_output_rate=50
http_405_output_rate=50

#计数时间段长度，秒
count_interval=60

config_timezone=8


#两种计算行数的方式，
#   第一种 wc -l 似乎更快一点
#   第二种 awk 更准确，文件结尾无空行（非换行符结尾的文件）不会少算一行

#log_count=`wc -l ${log_filepath}`
log_count=`awk 'END{print NR}' ${log_filepath}`

echo "log file lines: "$log_count


echo "[Notice] MOST frequent static requests, move them to CDN, for better performance"
awk -F " " \
    -v fi_file="${field_index_url}" \
    -v total="$log_count" \
    'BEGIN{
        IGNORECASE=1
    }
    $fi_file ~ /\.(jpg|gif|png|js|css|pwf)$/ {
        xcount[$fi_file]++
    }
    END{
        print "total",total
        for(it in xcount){
            print it,xcount[it]
        }
    }' \
    $log_filepath |sort -k2 -rn |
    awk -F " " \
    -v title="MOST frequent static request" \
    -v output_rate=80 \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"


echo -e "\n"


#对日志做预处理，时间格式兼容

awk -F" " \
    -v count_interval="$count_interval" \
    -i "${MYDIR}/lib/awk/fs_function.awk" \
    'BEGIN{
        #print strftime("%Y-%m-%d %H:%M:%S")
    }
    {
        uxtime=fs_str2time(sprintf("%s %s",$1,$2),3,+8)
        uxtime_t=sprintf("%d",uxtime / count_interval) * count_interval
        print uxtime_t
    }' \
    $log_filepath |sort |uniq -c |sort -nk2 | \
    awk -F " " \
    -i "${MYDIR}/lib/awk/fs_function.awk" \
    'BEGIN{
        print "\n---- request count flow  ----------------"
        printf "%20s%10s\n","[time]","[count]"
    }
    {
        printf "%20s%10s\n",fs_strftime($2),$1
    }'





# 清理临时文件
#rm tmp_xxx.txt



