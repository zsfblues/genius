#!/bin/bash

# 自定义脚本运行过程中产生的中间数据根目录
BASE_HOME=""

PROJECT_NAME="${PROJ_PREFIX}${PROJECT_NAME}${PROJ_SUFFIX}"

MAX_BACKUP=10
# web容器启动最大时间
WEB_CONTAINER_STARTUP_LIMIT_TIME=300

PROJECT_PATH="${BASE_HOME}/apps/${PROJECT_NAME}"
# 将来用来保存每个项目的启动、运行等日志
PROJECT_LOGS="${BASE_HOME}/logs/apps/${PROJECT_NAME}"

CODE_PATH="${BASE_HOME}/store/code"
COMPILE_PATH="${BASE_HOME}/store/compile"
DEPLOY_HOME="${BASE_HOME}/store/deploy/${PROJECT_NAME}"
# 该常量用于项目更新时将旧的项目备份以便后续回滚，此变量会关联最大备份次数
BACKUP_PATH="${BASE_HOME}/store/back/${PROJECT_NAME}"
MAVEN_COMPILE_LOG="${COMPILE_PATH}/${PROJECT_NAME}"

# 根据具体的项目环境(比如dev test prod)打包
RUN_ENV="dev"

IS_DEPLOY_WAY_WAR=false

# 自定义项目名
APPS[0]="${PROJ_PREFIX}..."

WEBPORT=""

if [[ $PROJECT_NAME = "${APPS[0]}" ]]; then
    # 针对单个项目的配置
    GIT_REPOSITORY=""
    # 针对单个项目的部署tomcat名
    TOMCAT_NAME=""
    # 一般是项目的target目录
    WEB_PATH=""
fi

TOMCAT_HOME="$BASE_HOME/container/${TOMCAT_NAME}"
STDOUT_LOG="${TOMCAT_HOME}/logs/catalina.out"

# 给提示语着色
ERRORTXTCOLOR="\033[7;49;91m"
YELLOWCOLOR="\033[33m"
ORANGECOLOR="\033[38;5;210m"
REDTXTCOLOR="\033[31m"
GREENCOLOR="\033[38;5;82m"
TXTCOLOREND="\033[0m"

dirs_check(){
    if [ ! -d "${PROJECT_PATH}" ]; then
        mkdir -p "${PROJECT_PATH}"
    fi

    if [ $? != 0 ]; then
        echo -e "${REDTXTCOLOR}你不具备${PROJECT_PATH}下创建目录的权限，请手工处理${TXTCOLOREND}"
        exit;
    fi

    if [ ! -d "${PROJECT_LOGS}" ]; then
         mkdir -p "${PROJECT_LOGS}"
    fi

    if [ $? != 0 ]; then
        echo -e "${REDTXTCOLOR} 你不具备${PROJECT_LOGS}下创建目录的权限，请手工处理${TXTCOLOREND}"
        exit;
    fi

    if [ ! -d "${CODE_PATH}" ]; then
        mkdir -p "${CODE_PATH}"
    fi
    if [ ! -d "${COMPILE_PATH}" ]; then
        mkdir -p "${COMPILE_PATH}"
    fi
    if [ ! -d "${DEPLOY_HOME}" ]; then
        mkdir -p "${DEPLOY_HOME}"
    fi
    if [ ! -d "${BACKUP_PATH}" ]; then
        mkdir -p "${BACKUP_PATH}"
    fi
    if [ ! -d ${MAVEN_COMPILE_LOG} ]; then
        mkdir -p "${MAVEN_COMPILE_LOG}"
        touch "${MAVEN_COMPILE_LOG}/maven.log"
    fi

    echo "" > "${MAVEN_COMPILE_LOG}/maven.log"
}

project_check(){
    for proj in ${APPS[*]}
    do
        if [[ ${proj} = ${PROJECT_NAME} ]]; then
           
            return 1
        fi
    done
    return 0
}


