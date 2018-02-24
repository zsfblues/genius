#!/bin/bash


startup(){
    pre=$(ps -ef | grep "$TOMCAT_NAME" | grep -v grep)


    if [[ ! -z $pre ]]; then
        echo -e "${ERRORTXTCOLOR} Tomcat已经启动，无需重复启动 ${TXTCOLOREND}"
        exit;
    fi
    
    # 删除过去几天tomcat的启动日志
    #today=$(date +%Y%m%d)
    #last_days=$(date -d"${today} -${STARTUP_LOG_EXPIRES} days" +"%Y%m%d")
    #rm -f ${STDOUT_LOG}_${last_days}*
    

    #now=$(date +%Y%m%d%H%M%S)
    #TOMCAT_TEMP_LOG=${STDOUT_LOG}_${now}
    #touch $TOMCAT_TEMP_LOG > /dev/null 2>&1
    cd "$TOMCAT_HOME"
    ./bin/startup.sh > /dev/null 2>&1
    echo "--------------------------开始部署war包, 启动容器-----------------------------"
    local start_time=0
    local interval=120
    local start_time_warning_threshold=$interval
    
    while true
    do
        check_log=$(tail -n 10 "$STDOUT_LOG" | grep -E "(startup failed due to previous errors|Cannot start server)")
        
        if [[ ! -z $check_log ]]; then
            MEM_USED=$(free -h | grep Mem | awk '{print $3}')
            MEM_FREE=$(free -h | grep Mem | awk '{print $4}')
            echo -e "${ERRORTXTCOLOR} Tomcat启动失败... ${TXTCOLOREND}"
            echo -e "当前内存已使用：${MEM_USED}，剩余：${MEM_FREE}"
	        exit
        else
            sleep 1
	        ex=$(tail -n 25 "$STDOUT_LOG" | grep "Caused by")
            stat=$(tail -n 10 "$STDOUT_LOG" | grep -w "Server startup in")
            
            if [[ ! -z $ex ]]; then
                echo -n -e "${REDTXTCOLOR} 启动过程抛出异常 ${TXTCOLOREND}"
            fi
            
            if [[ ! -z $stat ]]; then
                echo -e "[${REDTXTCOLOR} $PROJECT_NAME服务启动成功，正常上线 ${TXTCOLOREND}]"
                return
            else
                let "start_time++"
        	    echo -e -n "\r Tomcat 启动中: $start_time..."
                if (( "$start_time" > "$start_time_warning_threshold" )); then
                    echo -e "\r${ERRORTXTCOLOR}Tomcat启动已耗时 ${start_time_warning_threshold} 秒，尝试向应用程序发起请求... ${TXTCOLOREND}" 

                    local app_pid=$(ps aux | grep "$TOMCAT_NAME" | grep -v grep)
                    local local_app_port=$(netstat -anp | grep -v grep | grep "$app_pid" | grep -i LISTEN | grep -E "0.0.0.0:[0-9]+" | awk -F ':' '{print $2}' | awk -F [[:space:]+] '{print $1}')
                    if [[ ! -z $local_app_port ]]; then
                        local connected=$(curl -m 3 127.0.0.1:$local_app_port)
                        if [[ -z $connected ]]; then
                            echo -e "[${REDTXTCOLOR} $PROJECT_NAME服务启动成功，正常上线 ${TXTCOLOREND}]"
                            return
                        else
                            echo -e "\r${ERRORTXTCOLOR} 请求失败，可以手动检查日志(或继续等待) ${TXTCOLOREND}"
                        fi
                    else
                        echo -e "[${REDTXTCOLOR} $PROJECT_NAME服务端口未知，跳过请求 ${TXTCOLOREND}]"
                        sleep 3
                    fi

                    start_time_warning_threshold=$[start_time_warning_threshold+interval]
                    
                fi

                if (( "$start_time" >= "$WEB_CONTAINER_STARTUP_LIMIT_TIME" )); then
                    echo -e "\r${ERRORTXTCOLOR} Tomcat启动时间已达上限 [ $WEB_CONTAINER_STARTUP_LIMIT_TIME ]秒，启动流程终止，建议去检查日志... ${TXTCOLOREND}"
                    exit;
                fi
            fi
        fi
    done
}

terminate(){
    stat=$(ps -ef | grep $TOMCAT_NAME | grep -v grep)

    if [[ -z $stat ]]; then
        echo "Tomcat已是终止状态"
	    sleep 1
        return
    else
	    ps aux | grep "$TOMCAT_NAME" | grep -v grep
        # 为保证停止最终可以成功，先尝试用自带脚本暂停(基本不会成功)，一定时间后不成功强杀Java进程
        echo -e "${REDTXTCOLOR} 准备停止Tomcat ...${TXTCOLOREND}"
        # ./$TOMCAT_HOME/bin/shutdown.sh  > /dev/null 2>&1
        sleep 1
        # local shutdown_gracefully_time=20
        # for stop_time in $(seq 1 120)
        # do 
	        TOMCAT_PID=$(ps -ef | grep "${TOMCAT_NAME}" | grep -v grep | awk '{print $2}')
            TOMCAT_PID=${TOMCAT_PID//\n/' '}
            
        #     if [[ ! -z $TOMCAT_PID ]]; then
        #         if (( "$stop_time" < "$shutdown_gracefully_time" )); then
        #             echo -e -n "${REDTXTCOLOR} 停止Tomcat中... ${stop_time} ${TXTCOLOREND}\r"
        #             sleep 1
        #         else
                    # 尝试强杀进程
                    echo -e "${REDTXTCOLOR} 强制停止Java进程${TOMCAT_PID} ${TXTCOLOREND}\r"
                    kill -9 $TOMCAT_PID > /dev/null 2>&1
                    sleep 5
        #         fi     
        #     else
        #         return
        #     fi
        # done
    fi
}
