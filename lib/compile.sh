#!/bin/bash

prepare_compile_env(){
    if [[ -z $BRANCH ]]; then
        echo "请指明要操作的分支名"
        exit;
    fi

    #local waitting=$(ps -ef | grep maven | grep -v grep)
    #if [[ -n $waitting ]]; then
    #    echo "当前有程序正在编译, 暂不支持操作..."
    #    exit;
    #fi

    local proj_src="${CODE_PATH}/${PROJECT_NAME}"
    
    if [ ! -d "$proj_src" ]; then
        echo -e "${ERRORTXTCOLOR} ${CODE_PATH}下${PROJECT_NAME}的源码不存在, 尝试克隆项目至本地 ${TXTCOLOREND}"
        cd "$CODE_PATH" || exit
        git clone "$GIT_REPOSITORY" -b "$BRANCH"
        
        if [ $? != 0 ]; then
            echo -e "${ERRORTXTCOLOR} 克隆失败, 请到${CODE_PATH}下手动处理 ${TXTCOLOREND}"
            exit;
        fi
        sleep 1
    fi
    cd "$proj_src" || exit
    git remote prune origin

    IS_THIS_BRANCH=false
    
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return
    CUR_BRANCH=${ref#refs/heads/}

    if [ "$CUR_BRANCH" = "$BRANCH" ]; then
        IS_THIS_BRANCH=true
    fi
    
    if [ $IS_THIS_BRANCH = true ]; then
        echo -e "${ORANGECOLOR} 已在当前分支[ $BRANCH ]上，准备执行git pull更新 ${TXTCOLOREND}"
    else
        echo -e "${ORANGECOLOR} 准备切换本地分支到[ $BRANCH ]上 ${TXTCOLOREND}"
        git checkout "$BRANCH"
        checkout_status=$?
        if [ $checkout_status != 0 ]; then
            echo -e "${ORANGECOLOR} 不存在的本地分支:[ $BRANCH ]，尝试切换远程分支 ${TXTCOLOREND}"
            git fetch || exit
            sleep 1
            git checkout origin/"$BRANCH" -b "$BRANCH"
            #git branch --set-upstream-to=origin/"$BRANCH"
            if [ $? != 0 ]; then
                echo -e "${ERRORTXTCOLOR} 不存在可以切换的远程分支: $BRANCH ${TXTCOLOREND}" 
                exit;
            fi
        fi
    fi
    git pull || exit
    
    rm -rf $MAVEN_COMPILE_LOG
    # 将项目源码移至maven目录下进行编译
    cp -rf ${CODE_PATH}/${PROJECT_NAME} $MAVEN_COMPILE_LOG
}

compile_code(){
    
    cd "$MAVEN_COMPILE_LOG" || exit
    maven_file="${MAVEN_COMPILE_LOG}/maven.log"
    mvn -U clean package -P${RUN_ENV} -DskipTests  > "$maven_file" 2>&1 &

    compile_time=1
    sleep 1
    echo -e "......................................开始编译, 当前路径: ${REDTXTCOLOR} $(pwd) ${TXTCOLOREND}......................................."
    while true
    do
        suc_build_result=$(tail -n 10 "$maven_file" | grep  "BUILD SUCCESS")
        fail_build_result=$(tail -n 10 "$maven_file" | grep  "ERROR")
        if [ ! -z "$fail_build_result" ]; then
            echo -e "\r${ERRORTXTCOLOR} maven编译失败，请检查${maven_file} ${TXTCOLOREND}\r"	
            exit;
        fi

        if [ -z "$suc_build_result" ]; then
            sleep 1
            echo -n -e "\rWaiting maven compile: ${compile_time}...代码编译中..."
            let "compile_time++"
        else
            echo -e "\n当前:[${REDTXTCOLOR} 代码编译完成 ${TXTCOLOREND}], 准备部署包 "
            # 删除上一次部署的残留包
            [[ -n ${DEPLOY_HOME} ]] && rm -rf ${DEPLOY_HOME}/*

            if [ ! -s $MAVEN_COMPILE_LOG ]; then
                echo -e "\n${ERRORTXTCOLOR} 编译完的文件不可用，无法继续打包部署...${TXTCOLOREND}"
                exit;
            fi
            
            # 假定当前路径下只有一个war包
            local web_war=$(ls ${WEB_PATH}/*.war)
            cp -f $web_war $DEPLOY_HOME

            local deploy_war=$(ls ${DEPLOY_HOME}/*.war)
            mv $deploy_war ${DEPLOY_HOME}/${PROJECT_NAME}-web.war
            
            if [ $? != 0 ]; then
                echo -e "${ERRORTXTCOLOR} 不存在可以打包的war包，部署停止 ${TXTCOLOREND}"
                exit;
            fi

            return
        fi
       
    done
}
