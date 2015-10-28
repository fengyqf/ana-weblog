#!/usr/bin/env bash


MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR}/src/bash/init.sh"

"${MYDIR}/pretreatment.sh" -t $LOGTYPE $log_filepath | tee tmp_log_formated.log | awk  \
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
        if [[ ! -z "${line}" ]]; then
            if [[ -z "${ips}" ]]; then
                ips=" "$line
            else
                ips=$ips" "$line
            fi
        fi
    done < tmp_suspect_ips.txt


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
awk -v fi_ua="${field_index_useragent}" \
    'BEGIN{FS="\t";OFS="\t"}
    {
        xcount[$fi_ua]++
    }
    END{
        print "total",NR
        for(it in xcount){
            print it,xcount[it]
        }
    }' \
    tmp_suspect_request.log |sort -t $'\t' -k2 -nr |
    awk \
    -v title="[suspect ip] most frequent user-agent, and times" \
    -v FS='\t' \
    -v OFS='\t' \
    -v output_rate=50 \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"
echo -e "\n"

#过滤出可疑请求的最多请求的 url 及请求次数
awk -v fi_url="${field_index_url}" \
    'BEGIN{FS="\t";OFS="\t"}
    {
        split($fi_url,arr,"?")
        xcount[arr[1]]++
    }
    END{
        print "total",NR
        for(it in xcount){
            print it,xcount[it]
        }
    }' \
    tmp_suspect_request.log |sort -t $'\t' -k2 -nr |
    awk \
    -v title="[suspect ip] most frequent url, and times" \
    -v FS='\t' \
    -v OFS='\t' \
    -v output_rate=80 \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"
echo -e "\n"

# 可疑ip请求的响应状态码
awk -v fi_status="${field_index_http_status}" \
    'BEGIN{FS="\t";OFS="\t"}
    {
        xcount[$fi_status]++
    }
    END{
        print "total",NR
        for(it in xcount){
            print it,xcount[it]
        }
    }' \
    tmp_suspect_request.log |sort -t $'\t' -k2 -nr |
    awk \
    -v title="[suspect ip] HTTP response status" \
    -v FS='\t' \
    -v OFS='\t' \
    -v output_rate=100 \
    -v output_at_least=10 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"
echo -e "\n"

# 可疑ip请求的最大请求字节数（按百字节计）
awk -v fi_r_bytes="${field_index_request_bytes}" \
    'BEGIN{FS="\t";OFS="\t"}
    {
        lkey=int($fi_r_bytes/100)"00"
        xcount[lkey]++
    }
    END{
        print "total",NR
        for(it in xcount){
            print it,xcount[it]
        }
    }' tmp_suspect_request.log |sort -t $'\t' -k2 -nr |
    awk \
    -v title="[suspect ip] request bytes (by 100 bytes)" \
    -v FS='\t' \
    -v OFS='\t' \
    -v output_rate=80 \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"
echo -e "\n"

# 可疑ip请求的响应状态
awk -v fi_r_bytes="${field_index_response_bytes}" \
    'BEGIN{FS="\t";OFS="\t"}
    {
        lkey=int($fi_r_bytes/1000)"000"
        xcount[lkey]++
    }
    END{
        print "total",NR
        for(it in xcount){
            print it,xcount[it]
        }
    }' \
    tmp_suspect_request.log |sort -t $'\t' -k2 -nr |
    awk \
    -v title="[suspect ip] HTTP response bytes (by 1000 bytes)" \
    -v FS='\t' \
    -v OFS='\t' \
    -v output_rate=80 \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"
echo -e "\n"

# 可疑ip请求的处理花费时间
awk -v fi_time="${field_index_time_taken}" \
    'BEGIN{FS="\t";OFS="\t"}
    {
        lkey=int($fi_time/10)"0"
        xcount[lkey]++
    }
    END{
        print "total",NR
        for(it in xcount){
            print it,xcount[it]
        }
    }' tmp_suspect_request.log | sort -t $'\t' -k2 -nr |
    awk \
    -v title="time taken to process request (by 10 seconds)" \
    -v FS='\t' \
    -v OFS='\t' \
    -v output_rate=80 \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"
echo -e "\n"

# 可疑ip请求的目标文件类型（按文件名后缀判断）
awk -v fi_file="${field_index_url}" \
    'BEGIN{FS="\t";OFS="\t"}
    {
        #这里根据url计算文件名后缀，算法应该有问题，待检查 TODO
        split($fi_file,arr,"?")
        pos=match(arr[1],/\.[a-zA-Z0-9]*(\/|$|\?)/)
        if(pos==0){
            cnt=split(arr[1],a2,"/")
            lkey=a2[cnt]
        }
        lkey=substr(arr[1],pos)
        xcount[lkey]++
    }
    END{
        print "total",NR
        for(it in xcount){
            print it,xcount[it]
        }
    }' tmp_suspect_request.log | sort -t $'\t' -k2 -nr |
    awk \
    -v title="[suspect ip] most popular file type" \
    -v FS='\t' \
    -v OFS='\t' \
    -v output_rate=80 \
    -v output_at_least=50 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"
echo -e "\n"

if [ "${av_keep_tmp_file}" == "Y" ]; then
    echo "tmp files keept"
else
    # 清理临时文件
    echo "removing. tmp files"
    rm tmp_suspect_ips.txt
    rm tmp_suspect_request.log
    rm tmp_log_formated.log
fi
