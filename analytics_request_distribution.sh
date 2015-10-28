#!/usr/bin/env bash


MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR}/src/bash/init.sh"

"${MYDIR}/pretreatment.sh" -t $LOGTYPE $log_filepath > tmp_log_formated.log

echo ""
echo "[Notice] MOST frequent static requests, move them to CDN, for better performance"
echo ""

log_count=`wc -l tmp_log_formated.log |awk '{print $1}'`
awk -v FS='\t' -v OFS='\t' \
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
    tmp_log_formated.log |sort -t $'\t' -k2 -rn |
    awk -v FS='\t' -v OFS='\t' \
    -v title="MOST frequent static request" \
    -v output_rate=80 \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"


echo -e "\n"


#对日志做预处理，时间格式兼容

awk -v FS='\t' -v OFS='\t' \
    -v count_interval="$count_interval" \
    -v config_timezone="$config_timezone" \
    -v config_time_format="$config_time_format" \
    -i "${MYDIR}/lib/awk/fs_function.awk" \
    'BEGIN{
        #print strftime("%Y-%m-%d %H:%M:%S")
    }
    {
        uxtime=fs_str2time($10,config_time_format,+8)
        uxtime_t=sprintf("%d",uxtime / count_interval) * count_interval
        print uxtime_t
    }' \
    tmp_log_formated.log |sort |uniq -c |sort -rnk2 | \
    awk \
    -i "${MYDIR}/lib/awk/fs_function.awk" \
    'BEGIN{
        printf "\n---- request count flow (interval:%s seconds, use `-i n` to change) ----------------\n",count_interval
        printf "%20s%10s\n","[time]","[count]"
    }
    {
        printf "%20s%10s\n",fs_strftime($2),$1
    }'

echo '~~~~~~~~~~~~~~~~~~'
echo "[Notice] time interval: $count_interval seconds, "
echo "    shell parameters -i, eg for 10 minutes:"
echo "    \$./$(basename $0) -i 600"



# 清理临时文件
echo ""
if [ "${av_keep_tmp_file}" == "Y" ]; then
    echo "tmp files kept"
else
    echo "removing. tmp files"
    rm tmp_log_formated.log
fi




