#!/bin/awk -f

# 从传递给awk的变量里，判断当前日志类型，及需分析的栏位
# 接受参数列表
#   av_LOGTYPE          日志类型，可选值 iis, apache
#   av_FS               awk 的 FS 变量
#   av_FPAT             awk 的 FPAT 变量，要求gawk 4.0+以上版本
#   av_field_index      做统计数等时，依照的字段编号，即 awk 中$1,$2,$9等的下标
#   av_dbg              debug参数，定义几个级别？
#
#
# 关于字段分隔之定义
# FS, FPAT 两个变量，按gawk的习惯，首选FS，若为空，则使用FPAT，亦无，FS=" "
# 如果有 av_LOGTYPE 则按预定义的分隔符号执行
#   iis     -> 空格分隔字符
#   apache  -> 双引号括起来字段，或非空格字符组成的字段
#    传参时注意bash本身的转义
#
# 示例
#   $ head -20 access.log |awk -f analytics.awk -v av_FPAT='([^ ]+)|\\\"([^\\\"]+)\\\"'  


#运行前
BEGIN {
    #debug
    if(av_dbg > 0){
        dbg=av_dbg+0
    }else{
        dbg=0
    }

    if(av_dbg){
        printf "\n---- raw arguments -------\n"
        printf "av_FPAT:        %s\n",av_FPAT
        printf "av_field_index: %s\n",av_FIELD_INDEX
    }

    if(av_LOGTYPE=="iis"){
        FS=" "
    }else if(av_LOGTYPE=="apache"){
        FPAT="([^ ]+)|\"([^\"]+)\""
    }else if(av_FS!=""){
        FS=av_FS
    }else if(av_FPAT!=""){
        FPAT=av_FPAT
    }else{
        FS=" "
    }
    
    if(av_FIELD_INDEX > 0){
        av_FIELD_INDEX=av_FIELD_INDEX+0
    }else{
        av_FIELD_INDEX=0
    }

    if(av_dbg){
        printf "\n---- checked ---------\n"
        printf "FS:             %s\n",FS
        printf "FPAT:           %s\n",FPAT
        printf "av_FIELD_INDEX: %s\n",av_FIELD_INDEX
        printf "av_dbg:         %s\n",av_dbg
        printf "---- BEGIN finished ---------\n\n"
    }
}


#运行中
{
    foo=$((av_FIELD_INDEX));
    printf "line field: %s\n",foo
}


#运行后
END {

}
