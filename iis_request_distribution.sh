#!/usr/bin/env bash


MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR}/src/bash/init.sh"


echo ""
echo "[Notice] MOST frequent static requests, move them to CDN, for better performance"
echo ""
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

echo ""
echo "[Notice] time interval: $count_interval seconds, "
echo "         shell parameters -i, eg for 10 minutes:"
echo "         \$./$(basename $0) -i 600"




# 清理临时文件
#rm tmp_xxx.txt



