#!/usr/bin/env bash


MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${MYDIR}/src/bash/init.sh"

echo ""

"${MYDIR}/pretreatment.sh" -t $LOGTYPE $log_filepath | tee tmp_log_formated.log | awk \
    -v fi_method="$field_index_method" \
    'BEGIN{
        print "---- HTTP request method, and count ------------"
        FS="\t"
        OFS="\t"
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
        printf "%10s%10s%10s\n","[status]","[count]","[rate%]"
        for(i in method){
            if(method[i] in count){
                printf "%10s%10s%9.2f\n",method[i],count[method[i]],count[method[i]]/total*100
            }
        }
        #awk array size...
        xcount_size=0
        for(i in xcount){
            xcount_size+=1
        }
        if(xcount_size > 0){
            print "\n---- abnormal  method ----------------"
            printf "%10s%10s%10s\n","[status]","[count]","[rate%]"
            for(i in xcount){
                printf "%10s%10s%9.2f\n",method[i],count[method[i]],count[method[i]]/total*100
            }
        }
        #printf "%\n","HEAD","GET","HEAD","POST","PUT","DELETE","TRACE","CONNECT"
        #print count["HEAD"],count["GET"],count["HEAD"],count["POST"],count["PUT"],count["DELETE"],count["TRACE"],count["CONNECT"]
    }' \


# [算法说明]
# 下面awk脚本，在BEGIN{}段中，构造三个数组
#   idx[1],idx[2],idx[3]...                         用于输出count[]数组时，按count[]元素下标在idx出现先后次序列出
#   count[idx[1]],count[idx[2]],count[idx[3]]...    用于存储每个idx[]元素值，在记录中出现的行数
#   xcount[1],xcount[2]...                          用于存储每个不在idx[]数组中的值，在记录中出现的行数
#   事实上，下面awk脚本是对单列值做计数，类似于bash脚本
#        ... |sort |uniq -c |sort
#       但又不仅于此，增加如下特性：
#          - 按idx[]值做分组，
#                    在idx[]数组中的值，做为一组，计数为count[idx[i]]...
#                    不在idx[]数组中的值，作为一组，计数为xcount[idx[i]]...
#          - 对count[]计数的输出，按idx[]中定义的次序依次输出
#        适全于：对非开放式字段的统计计数，把我们所关心的一些值计数，列到一组中，其它值计数，存储于xcount[]

awk -F " " \
   -v fi_status="$field_index_http_status" \
    'BEGIN{
        FS="\t"
        OFS="\t"
        idx_cs="200,206,301,302,304,400,403,404,405,406,500,501"
        num=split(idx_cs,idx,",")
        for(i=1;i<=num;i++){
            count[idx[i]]=0
        }
    }
    $fi_status!="" && $fi_status!="cs-host" {
        if($fi_status in count){
            count[$fi_status]+=1
        }else if($fi_status in xcount){
            xcount[$fi_status]+=1
        }else{
            xcount[$fi_status]=1
        }
        total+=1
    }
    END {
        print "\n---- HTTP  status ----------------"
        printf "%10s%10s%10s\n","[status]","[count]","[rate%]"
        for(i in idx){
            if(idx[i]+0 in count){
                printf "%10s%10s%9.2f\n",idx[i],count[idx[i]],count[idx[i]]/total*100
            }
        }
        #awk array size...
        xcount_size=0
        for(i in xcount){
            xcount_size+=1
        }
        if(xcount_size > 0){
            print "\n---- abnormal  status ----------------"
            printf "%10s%10s%10s\n","[status]","[count]","[rate%]"
            for(i in xcount){
                printf "%10s%10s%9.2f\n",i,xcount[i],xcount[i]/total*100
            }
        }
    }' \
    tmp_log_formated.log





echo ""
# most frequment 404 files
awk -F " " \
    -v fi_status="$field_index_http_status" \
    -v fi_url="$field_index_url" \
    'BEGIN{
        FS="\t"
        OFS="\t"
    }
    $fi_status=="404"{
        xcount[$fi_url]++
        total+=1
    }
    END{
        #输出数据，管道到下一步的awk处理；首行为“total {总行数}”，数据行为“{url} {数目}”
        print "total",total
        for(it in xcount){
            print it,xcount[it]
        }
    }' \
    tmp_log_formated.log | sort -k2 -nr | awk -F " " \
    -v title="MOST frequent 404 request" \
    -v output_rate="$not_found_url_output_rate" \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"


echo ""
# most frequment 500 files
awk -F " " \
    -v fi_status="$field_index_http_status" \
    -v fi_url="$field_index_url" \
    'BEGIN{}
    $fi_status=="500"{
        xcount[$fi_url]++
        total+=1
    }
    END{
        #输出数据，管道到下一步的awk处理；首行为“total {总行数}”，数据行为“{url} {数目}”
        print "total",total
        for(it in xcount){
            print it,xcount[it]
        }
    }' \
    tmp_log_formated.log | sort -k2 -nr | awk -F " " \
    -v title="MOST frequent 500 request" \
    -v output_rate="$http_500_output_rate" \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"


echo ""
# most frequment 405 files
awk -F " " \
    -v fi_status="$field_index_http_status" \
    -v fi_url="$field_index_url" \
    'BEGIN{}
    $fi_status=="405"{
        xcount[$fi_url]++
        total+=1
    }
    END{
        #输出数据，管道到下一步的awk处理；首行为“total {总行数}”，数据行为“{url} {数目}”
        print "total",total
        for(it in xcount){
            print it,xcount[it]
        }
    }' \
    tmp_log_formated.log | sort -k2 -nr | awk -F " " \
    -v title="MOST frequent 405 request" \
    -v output_rate="$http_405_output_rate" \
    -v output_at_least=5 -v output_at_most=20 \
    -f "${MYDIR}/src/awk/general_top_rate.awk"



# 清理临时文件
if [ "${av_keep_tmp_file}" == "Y" ]; then
    echo "tmp files kept"
else
    echo "removing. tmp files"
    rm tmp_log_formated.log
fi





