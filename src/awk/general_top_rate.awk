#!/bin/awk -f

#
# 按一定比例，输出占最大百分比的数据
#awk -F " " -v output_rate=80 -v title="most frequent foobar" -f general_top_rate.awk "file.csv"
#
# 脚本脚本时，需要传入的变量
#   output_rate         输出百分比
#   output_at_least     无条件的输出前output_at_least条，主要应对处理数据条数过少的情况，默认20条
#   output_at_most     最多输出output_at_least条，防止输出过长，影响阅读，默认100
#   title               输出标题文字
#
#
# -- 举例 --
# （在显式定义 output_at_least 为 0 的情况下）
# 接受处理数据文件 file.csv 格式：
# -----------------
# total  20
# a1 9
# a2 3
# a3 3
# a4 2
# a5 1
# a6 1
# a7 1
# -----------------
# 其中第一行为total总数，其它行为条目及其数目，并且从大到小排序
# 按比例 output_rate 输出数据,、
# 如 设置50，则输出前两条，即 9+3=12 刚好达到 20*50%=10 的总计数
# 如设置为65，则输出前3条，前两条已经到达65%，但第3条的数目与第二条一样，所以继续输出，往后直到不同数目
# 

BEGIN{
        lc_sum=0
        total=0
        to_output=1
        #在输出时，到达阈值的一行n，如果n+1行的第二字段（出现频次）相等，n+1条也应该输出
        #  因此定义变量last_f2，暂存上一条数据第二个字段值。
        #      定义变量output_end，标记彻底停止输出
        last_f2=0
        output_end=0
        output_at_least+=0
        if(output_at_least==0){
            output_at_least=20
        }
        output_at_most+=0
        if(output_at_most==0){
            output_at_most=100
        }
    }
    {
        if(NR==1){
            total=$2+0
            printf "---- %s (top %d% && at least %d, at most %d) ----------------\n" \
                , title, output_rate, output_at_least ,output_at_most
            printf "%10s   %4s    %s\n","[count]","[rate%]","[subject]"
            lc_sum_in_rate=total*output_rate/100
            #print "total: ",total
            #print "output_rate: ",output_rate
            #print "lc_sum_in_rate: ",lc_sum_in_rate
        }else{
            lc_sum+=$2
            #小于阈值，输出
            #  未彻底终结输出，检查与上条是否相同
            #       相同，则输出
            #       不同，标记彻底终结输出
            if(lc_sum < lc_sum_in_rate){
                to_output=1
            }else if(output_end==0){
                if($2==last_f2){
                    #不小于阈值，检查上一条的f2是否与本条相同
                    to_output=1
                }else{
                    to_output=0
                    output_end=1
                }
            }
            if( (to_output==1 || count_output < output_at_least) && count_output < output_at_most){
                count_output+=1
                printf "%10s   %7.2f    %s\n",$2,$2/total*100,$1
            }
            last_f2=$2
        }
    }

