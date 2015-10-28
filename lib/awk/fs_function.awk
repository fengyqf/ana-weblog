#!/bin/awk -f

# 按指定格式将日期字符串转换为unix timestamp
#   为了避免在32位机器(?)上mktime()函数溢出问题(?)，故对不处理[1970-2038]之间年份，直接返回 0
#   使用时，可以依照情况注释掉该行

function fs_str2time(str,format,timezone)
{
    #format code
    # 1.  [10/May/2015:03:45:00 +0800]
    #       忽略timezone参数，而使用str中最后一节
    #
    # 2.  10/May/2015:03:45:00
    # 
    # 3.  2015-05-22 00:01:18
    #

    #year;  month;  day;    hour;   minute; second;
    p_y=0;  p_m=0;  p_d=0;  p_h=0;  P_n=0;  p_s=0;
    timezone=timezone+0;
    rtn=0

    if(format==1 || format==2){
        #mapping for month name to int month
        map_m["Jan"]=1
        map_m["Feb"]=2
        map_m["Mar"]=3
        map_m["Apr"]=4
        map_m["May"]=5
        map_m["Jun"]=6
        map_m["Jul"]=7
        map_m["Aug"]=8
        map_m["Sept"]=9
        map_m["Oct"]=10
        map_m["Nov"]=11
        map_m["Dec"]=12
        map_m["Sep"]=9

        if(format==1){
            str=substr(str,2,length(str)-2)
        }

        fs_num=split(str,arr," ")
        timezone=substr(arr[2],2,2)+0
        fs_num=split(arr[1],arr,"/")
        p_d=arr[1]
        p_m=map_m[arr[2]]
        p_y=split(arr[3],arr,":")
        p_y=arr[1]
        p_h=arr[2]
        p_n=arr[3]
        p_s=arr[4]
        str=sprintf("%04d %02d %02d %02d %02d %02d",p_y,p_m,p_d,p_h,p_n,p_s)
    }
    if(format==3){
        fs_num=split(str,arr," ")
        split(arr[1],arr_date,"-")
        split(arr[2],arr_time,":")
        p_y=arr_date[1]
        p_m=arr_date[2]
        p_d=arr_date[3]
        p_h=arr_time[1]
        p_n=arr_time[2]
        p_s=arr_time[3]
        str=sprintf("%04d %02d %02d %02d %02d %02d",p_y,p_m,p_d,p_h,p_n,p_s)
    }
    if(p_y+0 < 1970 || p_y > 2038){
        return 0
    }else{
        #return str
        return mktime(str)-timezone*3600
        #return mktime(str)
    }
}



function fs_strftime(uxtime,timezone)
{
    return strftime("%Y-%m-%d %H:%M:%S",uxtime+3600*timezone);
}


function in_array(arr,val){
    for(i in arr){
        if(arr[i]==val){
            return 1;
        }
    }
    return 0;
}
