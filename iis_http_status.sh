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



#两种计算行数的方式，
#   第一种 wc -l 似乎更快一点
#   第二种 awk 更准确，文件结尾无空行（非换行符结尾的文件）不会少算一行

#log_count=`wc -l ${log_filepath}`
log_count=`awk 'END{print NR}' ${log_filepath}`

echo "log file lines: "$log_count

#awk -v fi_method="$field_index_method" \
#    'BEGIN{FS=" "}
#    $fi_method!="" {print $fi_method}' \
#    $log_filepath |sort |uniq -c |sort -nr |head -20

awk -v fi_method="$field_index_method" \
    'BEGIN{
        print "\n---- HTTP request method, and count ------------"
        FS=" "
        #按 HTTP/1.1 的method定义awk数组 http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
        #输出时按下面定义的顺序
        method[1]="GET"
        method[2]="POST"
        method[3]="HEAD"
        method[4]="PUT"
        method[5]="DELETE"
        method[6]="TRACE"
        method[7]="CONNECT"
        method[8]="OPTIONS"

        count["OPTIONS"]=0
        count["GET"]=0
        count["HEAD"]=0
        count["POST"]=0
        count["PUT"]=0
        count["DELETE"]=0
        count["TRACE"]=0
        count["CONNECT"]=0
        total=0
    }
    $fi_method!="" {
        if($fi_method in count){
            count[$fi_method]+=1
        }else if($fi_method in xcount){
            xcount[$fi_method]+=1
        }else{
            xcount[$fi_method]=1
        }
        total+=1
    }
    END{
        printf "%10s%10s\n","[method]","[count]"
        for(i in method){
            if(method[i] in count){
                printf "%10s%10s\n",method[i],count[method[i]]
            }
        }
        #awk array size...
        xcount_size=0
        for(i in xcount){
            xcount_size+=1
        }
        if(xcount_size > 0){
            print "\n---- abnormal  method ----------------"
            printf "%10s%10s\n","[method]","[count]"
            for(i in xcount){
                printf "%10s%10s\n",i,xcount[i]
            }
        }
        #printf "%\n","HEAD","GET","HEAD","POST","PUT","DELETE","TRACE","CONNECT"
        #print count["HEAD"],count["GET"],count["HEAD"],count["POST"],count["PUT"],count["DELETE"],count["TRACE"],count["CONNECT"]
    }' \
    $log_filepath
    #|sort |uniq -c |sort -nr |head -20

# 清理临时文件
#rm tmp_xxx.txt



