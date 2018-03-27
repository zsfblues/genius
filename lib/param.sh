#!/bin/bash

while getopts 'p:e:b:a:n:h:t:d:r' ARG;
do
    case $ARG in
        p)
            PROJECT_NAME="$OPTARG"
            ;;
        e)
            # 根据默认的项目环境(比如dev test prod)进行打包
            RUN_ENV="$OPTARG"
            ;;
        b)
            BRANCH="$OPTARG"
            ;;
        n)
            VERSION="$OPTARG"
            ;;
        h)  
            REMOTE_HOST="$OPTARG"
            ;;
        t)  
            REMOTE_PATH="$OPTARG"
            ;;
        d)
            BRANCH="$OPTARG"
            ;;
        r)
            BRANCH='-r'
            ;;
        a)
            ACTION="$OPTARG"
            ;;
        ?)
            echo "存在不支持的参数类型"
            exit;
    esac
done