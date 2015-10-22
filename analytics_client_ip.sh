#!/usr/bin/env bash


MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR}/src/bash/init.sh"

"${MYDIR}/pretreatment.sh" -t 2 $log_filepath | tee tmp_log_formated.log | awk -F "," \
    -v fi_cip="$field_index_clientip" \
    -v threshold="${suspect_client_ip_percent_threshold}" \
    'BEGIN{
        total=0
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




# 清理临时文件
rm tmp_suspect_ips.txt

