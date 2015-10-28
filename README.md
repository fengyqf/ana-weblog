# analytics-weblog
analytics weblog, to find something, such as ...

# require
bash(linux, osx, cygwin, etc...)
gawk 4.0.0+


# quick start

    ./analytics_client_ip.sh -t iis log_extend_iis_log.log
    ./analytics_client_ip.sh -dk -t apache log_site-access-20150517.log

# parameters

    -t      type, 日志文件类型，供选值 iis, apache等，具体参看 pretreatment.sh 中的定义
    -k      keep 保留临时文件
    -m      time format, 日志中日期字段格式, 定义在 fs_function.awk 中 fs_str2time()
    -i      interval, 分时间段计数时的时间间隔 count_interval
    -d      debug, 输出调试信息 dbg



