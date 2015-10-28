# client_ip.sh [OPTION]... [FILE]...

# 参数列表
#   -t      type, 日志文件类型，供选值 iis, apache等，具体参看 pretreatment.sh 中的定义
#   -k      keep 保留临时文件
#   -m      time format, 日志中日期字段格式, 定义在 fs_function.awk 中 fs_str2time()
#   -i      interval, 分时间段计数时的时间间隔 count_interval
#   -d      debug, 输出调试信息 dbg

dbg=0
#echo "init OPTIND:" $OPTIND
while getopts "t:kp:m:i:d" arg
do
    case $arg in
        t)
            LOGTYPE=$OPTARG
            ;;
        k)
            av_keep_tmp_file="Y"
            ;;
        p)
            av_FPAT=$OPTARG
            ;;
        m)
            config_time_format=$OPTARG
            ;;
        i)
            count_interval=$OPTARG
            ;;
        d)
            dbg=1
            ;;
        ?)
    esac
done
shift $((OPTIND-1))


if [ "${dbg}" == "1" ]; then
    echo "---- debug ---------"
    echo "av_keep_tmp_file:  ["$av_keep_tmp_file"]"
    echo "av_FPAT:           ["$av_FPAT"]"
    echo "av_FIELD_INDEX:    ["$av_FIELD_INDEX"]"
    echo "---- debug done ---------"
fi

log_filepath=$@


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




# 定义预处理后web日志文件中字段位置，与 pretreatment.sh 中位置对应
# 字段内容通常是带双引号的
field_index_clientip=1
field_index_method=2
# url, withOUT get-querystring
field_index_url=3

field_index_http_status=4
field_index_refer=5
field_index_useragent=6

field_index_request_bytes=7
field_index_response_bytes=8
field_index_time_taken=9

field_index_time=10



# 下面是一些配置值，暂时先留着，可能用得到 ---------------

#输出高频404地址时，从高到低覆盖范围百分比
not_found_url_output_rate=80
http_500_output_rate=50
http_405_output_rate=50

config_timezone=8

#根据日志类型定义日期类型
if [[ -z "$config_time_format" ]]; then
    if [[ "$LOGTYPE" =~ ^iis-?.*$ ]]; then
        #iis ext, format: 2015-05-22 00:01:18
        config_time_format=3
    elif [[ "$LOGTYPE" =~ ^apache-?.*$ ]]; then
        #apache, format: [10/May/2015:03:45:00 +0800]
        config_time_format=1
    fi
    if [ -z $dbg ]; then
        echo "config_time_format empty, use LOGTYPE to parse; $config_time_format"
    fi
fi


#计数时间段长度，秒
if [ -z $count_interval ]; then
    count_interval=60
fi



# 单个ip请求数超过指定百分比，警告消息
suspect_client_ip_percent_threshold=1



