# client_ip.sh [OPTION]... [FILE]...

# TODO 待清理 -----------
# 参数列表
# 这些参数列表，应该是没什么用的，有用的主要是计算分析出文件名；参数格式的，忽略 
#   -t      type, 日志文件类型，供选值 iis, apache
#   -k      keep 保留临时文件
#   -p      pattern, 字段模式 av_FPAT
#   -f      field, 字段编号位置 av_FIELD_INDEX
#   -i      interval, 分时间段计数时的时间间隔 count_interval
#   -d      debug, 输出调试信息 dbg

dbg=0
#echo "init OPTIND:" $OPTIND
while getopts "t:kp:f:i:d" arg
do
    case $arg in
        t)
            av_LOGTYPE=$OPTARG
            ;;
        k)
            av_keep_tmp_file="Y"
            ;;
        p)
            av_FPAT=$OPTARG
            ;;
        f)
            av_FIELD_INDEX=$OPTARG
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

LOGTYPE=$av_LOGTYPE

if [ "${dbg}" == "1" ]; then
    echo "---- debug ---------"
    echo "av_LOGTYPE:        ["$av_LOGTYPE"]"
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

#计数时间段长度，秒
if [ -z $count_interval ]; then
    count_interval=60
fi




# 单个ip请求数超过指定百分比，警告消息
suspect_client_ip_percent_threshold=1



