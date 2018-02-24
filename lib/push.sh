#!/bin/bash

push(){

    local default_remote_path="${DEPLOY_HOME}"
    local remote_host=$1
    local remote_path=$2
    local proj_war="${DEPLOY_HOME}/${PROJECT_NAME}-web.war"

    if [[ -z $remote_host ]]; then
        echo -e "${ERRORTXTCOLOR} 必须指定要推送的远程主机 ${TXTCOLOREND}" 
        exit;
    fi
  
    if [ ! -e "$proj_war" ] || [ ! -s "$proj_war" ]; then
        echo -e "${ERRORTXTCOLOR} 不存在可以推送的war包(或为空) ${TXTCOLOREND}" 
    else
        if [[ $remote_path == "" ]]; then
            echo -e "${REDTXTCOLOR} 远程推送路径为空，采用默认路径: ${DEPLOY_HOME} ${TXTCOLOREND}"
            scp "$proj_war" "$remote_host:$default_remote_path"
        else
            scp "$proj_war" "$remote_host:$remote_path"
        fi
        if [ $? != 0 ]; then
            echo -e "\n${ERRORTXTCOLOR} 无法推送包至远程目录(可能是远程目录不存在, 权限不足或网络异常) ${TXTCOLOREND}"
            exit;
        fi
    fi
}