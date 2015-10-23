#!/usr/bin/env bash


MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR}/src/bash/init.sh"

"${MYDIR}/pretreatment.sh" -t 2 $log_filepath | tee tmp_log_formated.log | awk  \
    -v fi_cip="$field_index_clientip" \
    -v threshold="${suspect_client_ip_percent_threshold}" \
    'BEGIN{
        total=0
        FS="\t"
        OFS="\t"
    }
    {
        xcount[$fi_cip]++
    }
    END{
        for(it in xcount){
            #a_cnt = threshold * NR / 100
            rate= xcount[it] / NR * 100;
            if(rate > threshold){
                printf "%16s  %6d %8.3f%\n",it,xcount[it],rate;
                suspect_count += 1;
                if(suspect_ips==""){
                    suspect_ips = it;
                }else{
                    suspect_ips = suspect_ips"\n"it;
                }
            }
        }
        # 将可疑ip地址写文件 tmp_suspect_ips.txt ,脚本结束后，注意清理这些临时文件
        print suspect_ips > "tmp_suspect_ips.txt"
    }' | \
    sort -k2 -nr | \
    awk 'BEGIN{
        print "----- suspect client ip (threshold rate >",threshold,"%) ----------"
        printf "%16s  %6s %6s(%)\n","client_ip","count","rate";
    }
    {
        printf "%16s  %6d %8.3f%\n",$1,$2,$3;
    }
    END{
        print "----- suspect client ip END (count:",NR,")----------\n\n";
    }'


# 检查异常ip的 useragent, 及最频繁的请求地址

# awk 中筛选client ip地址的部分
ips=""

while read line
    do
        echo 'ip: '$line
        if [[ ! -z "${line}" ]]; then
            if [[ -z "${ips}" ]]; then
                ips=" "$line
            else
                ips=$ips" "$line
            fi
        fi
    done < tmp_suspect_ips.txt

echo "ips: "$ips

#筛选出可疑ip请求的日志，输出到文件 tmp_suspect_request.log
awk -F "," -v ips="${ips}" -v fi_cip="$field_index_clientip" \
    -i "${MYDIR}/lib/awk/fs_function.awk" \
    'BEGIN{
        FS="\t"
        OFS="\t"
        split(ips,ip_a," ")
        #for(i in ip_a){
        #    print "ip: ",i," -> ",ip_a[i]
        #}
    }

     $fi_cip!="" && $1!="#Fields:" && in_array(ip_a,$fi_cip) == 1 {
        print $0
    }' tmp_log_formated.log > tmp_suspect_request.log



echo -e "\n"
#过滤出可疑请求的最多请求的useragent
echo "---- [suspect ip] most frequent user-agent, and times ------------"
awk -v fi_ua="${field_index_useragent}" \
    'BEGIN{FS="\t";OFS="\t"}
    {print $fi_ua}' \
    tmp_suspect_request.log |sort |uniq -c |sort -nr |head -20
echo -e "\n"

#过滤出可疑请求的最多请求的 url 及请求次数
echo "---- [suspect ip] most frequent url, and times ------------"
awk -v fi_url="${field_index_url}" \
    'BEGIN{FS="\t";OFS="\t"}
    {print $fi_url}' \
    tmp_suspect_request.log |sort |uniq -c |sort -nr |head -20
echo -e "\n"

# 可疑ip请求的响应状态码
echo "---- [suspect ip] HTTP response status ------------"
awk -v fi_status="${field_index_http_status}" \
    'BEGIN{FS="\t";OFS="\t"}
    {print $fi_status}' \
    tmp_suspect_request.log |sort |uniq -c |sort -nr |head -20
echo -e "\n"

# 可疑ip请求的最大请求字节数（按百字节计）
echo "---- [suspect ip] request bytes (by 100 bytes) ------------"
awk -v fi_r_bytes="${field_index_request_bytes}" \
    'BEGIN{FS="\t";OFS="\t"}
    {printf "%d\n",$fi_r_bytes/100}' \
    tmp_suspect_request.log |\
  awk 'BEGIN{"\t";OFS="\t"}
    {printf "%5d\n",$1*100}' |sort |uniq -c |sort -nr |head -20
echo -e "\n"

# 可疑ip请求的响应状态
echo "---- [suspect ip] HTTP response bytes (by 1000 bytes) ------------"
awk -v fi_r_bytes="${field_index_response_bytes}" \
    'BEGIN{FS="\t";OFS="\t"}
    {printf "%d\n",$fi_r_bytes/1000}' \
    tmp_suspect_request.log |\
  awk 'BEGIN{"\t";OFS="\t"}
    {printf "%10d\n",$1*1000}' |sort -t $'\t' |uniq -c |sort -nr |head -20
echo -e "\n"

# 可疑ip请求的处理花费时间
echo "---- [suspect ip] time taken to process request (by 10 seconds) ------------"
awk -v fi_time="${field_index_time_taken}" \
    'BEGIN{FS="\t";OFS="\t"}
    {printf "%d\n",$fi_time/10}' \
    tmp_suspect_request.log |\
  awk 'BEGIN{FS=" ";OFS="\t"}
    {printf "%8d\n",$1*10}' |sort -t $'\t' |uniq -c |sort -nr |head -20
echo -e "\n"

# 可疑ip请求的目标文件类型（按文件名后缀判断）
echo "---- [suspect ip] most popular file type ------------"
awk -v fi_file="${field_index_url}" \
    'BEGIN{FS="\t";OFS="\t"}
    {
        pos=match($fi_file,/\.[a-zA-Z0-9]*(\/|$)/)
        print substr($fi_file,pos)
    }' \
    tmp_suspect_request.log |\
    awk -F "/" '{print $1}' |\
    sort |uniq -c |sort -nr |head -20
echo -e "\n"
# 处理缺陷
#   对于形式如 /index.php/list/123/ 的请求，
#     - 提到到的文件名后缀，只保留斜线（如果有）后面附加部分
#     - 是否还有其它形式的缺陷，暂时未知
#     - 如果能在 awk 内部提取到文件名，最好；但暂时没有方法

if [ "${av_keep_tmp_file}" == "Y" ]; then
    echo "tmp files keept"
else
    # 清理临时文件
    echo "removing. tmp files"
    rm tmp_suspect_ips.txt
    rm tmp_suspect_request.log
    rm tmp_log_formated.log
fi
