#!/bin/bash

# 用于指定运行脚本的用户，非该用户无法使用
RUNNER=""
PROJ_PREFIX=""

check_user(){
    cur_user=$(id -nu)
    if [[ "$cur_user" != "$RUNNER" ]]; then 
        echo "Illegal User! Only ${RUNNER} can run this script!"
        exit 1
    fi
}

print_console() {
    if [[ "$ACTION" == "rollback" ]]; then
    echo -e "当前执行:[${REDTXTCOLOR} ${PROJECT_NAME} ${TXTCOLOREND}]项目的:[${YELLOWCOLOR} ${ACTION} ${TXTCOLOREND}]命令, 回滚版本(倒序):[${ORANGECOLOR} ${BRANCH} ${TXTCOLOREND}] 请确认! [y/n] "
    elif [[ "$ACTION" == "push" ]]; then
        if [[ $BRANCH != "-r"  ]]; then
            echo -e "当前执行:[${REDTXTCOLOR} ${PROJECT_NAME} ${TXTCOLOREND}]项目的:[${YELLOWCOLOR} ${ACTION} ${TXTCOLOREND}]命令, 代码分支:[${ORANGECOLOR} ${BRANCH} ${TXTCOLOREND}], 远程主机:[${YELLOWCOLOR} ${REMOTE_HOST} ${TXTCOLOREND}], 远程目录:[${GREENCOLOR} ${REMOTE_PATH} ${TXTCOLOREND}] 请确认! [y/n] "
        else
            echo -e "当前执行:[${REDTXTCOLOR} ${PROJECT_NAME} ${TXTCOLOREND}]项目的:[${YELLOWCOLOR} ${ACTION} ${TXTCOLOREND}]命令, 远程主机:[${YELLOWCOLOR} ${REMOTE_HOST} ${TXTCOLOREND}], 远程目录:[${GREENCOLOR} ${REMOTE_PATH} ${TXTCOLOREND}] 请确认! [y/n] "        
        fi
    elif [[ "$ACTION" == "deploy" ]]; then
        echo -e "当前执行:[${REDTXTCOLOR} ${PROJECT_NAME} ${TXTCOLOREND}]项目的:[${YELLOWCOLOR} ${ACTION} ${TXTCOLOREND}]命令, 部署包名(包含路径名):[${ORANGECOLOR} ${BRANCH} ${TXTCOLOREND}] 请确认! [y/n] "    
    else
        echo -e "当前执行:[${REDTXTCOLOR} ${PROJECT_NAME} ${TXTCOLOREND}]项目的:[${YELLOWCOLOR} ${ACTION} ${TXTCOLOREND}]命令, 代码分支:[${ORANGECOLOR} ${BRANCH} ${TXTCOLOREND}] 请确认! [y/n] "
    fi
}

. lib/welcome.sh

readonly SCRIPT_NAME=$0
PROJECT_NAME=$1
readonly ACTION=$2
readonly BRANCH=$3
readonly REMOTE_HOST=$4
readonly REMOTE_PATH=$5

check_user

if [[ $PROJ_PREFIX != "" && $PROJECT_NAME =~ $PROJ_PREFIX ]]; then
    echo -e "\033[31m 工程名不能包含前缀 [${PROJ_PREFIX}] \033[0m"
    exit
fi

. lib/env.sh

project_check

if [ $? -eq 0 ] ; then
    echo -e "${ERRORTXTCOLOR} 不存在的项目名 ${TXTCOLOREND}"
    exit 0
fi

echo -e "\n${ORANGECOLOR} 当前执行环境：${RUN_ENV} ${TXTCOLOREND}"

print_console

read -r Arg
if [[ $Arg != "y" && $Arg != 'Y' ]]; then
	echo -e "${ERRORTXTCOLOR}请确认后(y|Y)执行 ${TXTCOLOREND}"
	exit 0
fi

. lib/compile.sh
. lib/rollback.sh
. lib/run.sh
. lib/deploy.sh
. lib/push.sh

dirs_check

# 判断要执行的操作
case "$ACTION" in
    run)
        prepare_compile_env
        compile_code
	    deploy
    	terminate
	    startup
    ;;
    push)
        if [[ $BRANCH != '-r' ]];then
            prepare_compile_env
            compile_code
        fi
        push $REMOTE_HOST $REMOTE_PATH
    ;;
    deploy)
        deploy $3
        terminate
	    startup
    ;;
    restart)
        terminate
	    startup
    ;;
    backup)
   	    backup
    ;;
    rollback)
        rollback $3
        terminate
	    startup
    ;;
    *)
        echo "不支持的操作: $ACTION"
        exit;
    ;;
esac
