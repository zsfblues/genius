#!/bin/bash

backup(){
  
    checkSamePackage
    re=$?

    if [ $re -eq 2 ]; then
        echo -e "${REDTXTCOLOR} 不存在可以备份的文件，跳过备份 ${TXTCOLOREND}"
        return
    fi

    if [ $re -eq 1 ]; then
        echo -e "${REDTXTCOLOR} 和上一次备份相同，跳过备份 ${TXTCOLOREND}"
        return
    fi

    local backup_count=$(ls -l ${BACKUP_PATH} | grep "^-.*${PROJECT_NAME}.*tar*" | wc -l) 
    cd "$PROJECT_PATH" || return

    if [[ $(ls ${PROJECT_PATH} | wc -l) != 0 ]]; then    
        if (( "$backup_count" < "$MAX_BACKUP" )); then     
            local file_count=$(ls | wc -l)
            if (( "$file_count" > 0 )); then
                tar czf "${BACKUP_PATH}/${PROJECT_NAME}_$(date +%Y%m%d%H%M%S).tar.gz" ./* 
                check_tar_status=$?
                if [[ $check_tar_status != 0 ]]; then
                    echo -e "${ERRORTXTCOLOR} 备份失败 ${TXTCOLOREND}\r"
                    exit;
                fi
            fi
        else
            echo -e  "${REDTXTCOLOR} ${BACKUP_PATH}下备份包已达到最大备份次数${MAX_BACKUP}，将清理最旧的备份包(可选择提高最大备份数阈值)，是否继续执行备份[y|n]: ${TXTCOLOREND}"
            read -r Arg
            while [[ $Arg != "y" && $Arg != 'Y' && $Arg != 'n' && $Arg != 'N' ]]
            do
                echo -e "\n${ERRORTXTCOLOR}请输入(y|n): ${TXTCOLOREND}"
                read -r Arg
            done
            if [[ $Arg == 'Y' || $Arg == 'y' ]]; then
                clean_file=${BACKUP_PATH}/$(ls -l ${BACKUP_PATH} | grep "^-.*${PROJECT_NAME}.*tar*" | head -1 | awk '{print $9}')
                if [ -e $clean_file ]; then
                    rm -f $clean_file
                    tar zcf "${BACKUP_PATH}/${PROJECT_NAME}_$(date +%Y%m%d%H%M%S).tar.gz" ./*
                fi
            else
                return
            fi
        fi
    fi
}


rollback(){

    local version=$1

    count=$(ls -l ${BACKUP_PATH} | grep "^-.*${PROJECT_NAME}.*tar*" | wc -l)

    if [[ "$count" -eq 0 ]]; then
        echo -e "${ERRORTXTCOLOR} 当前工程不存在可以回滚的备份包 ${TXTCOLOREND}"
        exit;
    fi

    if [[ ! -z "$version" && "$version" -gt $count || "$version" -lt 0 ]]; then
        echo -e "${ERRORTXTCOLOR} 回滚版本不在历史备份中 ${TXTCOLOREND}"
        exit;
    fi

    echo -e "${REDTXTCOLOR} 你当前正在执行版本回滚操作，将尝试回滚指定版本，请确认是否继续[y|n]: ${TXTCOLOREND}"
    
    read -r Arg
    if [[ $Arg != "y" && $Arg != 'Y' ]]; then
        echo -e "${ERRORTXTCOLOR}请确认后(y|Y)执行 ${TXTCOLOREND}"
        exit;
    fi

    cd ${BACKUP_PATH} || return
    
    if [[ "$version" =~ ^[1-9]+$ ]]; then
        rollback_name=$(ls -l ${BACKUP_PATH} | grep "^-.*${PROJECT_NAME}.*tar*" | sort -rk 9 | awk 'NR=='${version} | awk '{print $9}')
    else
        rollback_name=$(ls -l ${BACKUP_PATH} | grep "^-.*${PROJECT_NAME}.*tar*" | sort -rk 9 | awk 'NR==1' | awk '{print $9}')
    fi
    
    if [ ! -e $rollback_name ] || [ ! -s $rollback_name ]; then
        echo -e "${ERRORTXTCOLOR} 回滚包不可用 ${TXTCOLOREND}"
        exit;
    fi

    [[ -n $PROJECT_PATH ]] && rm -rf $PROJECT_PATH/*

    cp -f ${BACKUP_PATH}/${rollback_name} $PROJECT_PATH
    tar -xf  ${PROJECT_PATH}/${rollback_name} -C ${PROJECT_PATH}
    rm -rf ${PROJECT_PATH}/${rollback_name}

    cd ${PROJECT_PATH} || return

    local rollback_war=${PROJECT_NAME}-web.war
    if [[ "$IS_DEPLOY_WAY_WAR" = true ]];then
        if [[ -e $rollback_war && -s $rollback_war ]]; then
            # 解压之后删除war以外的文件
            local res=$(ls | grep -v ".war")
            res=${res//\n/' '}
            [[ -n $res ]] && rm -rf ./$res
            jar -xf $rollback_war
        else
            echo -e "${ERRORTXTCOLOR} 当前工程以war包部署，但${rollback_war} 包缺失或为空 ${TXTCOLOREND}"        
            exit
        fi
    fi
}


checkSamePackage(){
    # 检测app下包是否和上一次备份的war包相同(只在以war包形式部署时才执行)
    cd "$PROJECT_PATH" || return 0

    local proj_path_file_num=$(ls | wc -l)
    if [ $proj_path_file_num -eq 0 ]; then
        return 2
    fi

    if [ "$IS_DEPLOY_WAY_WAR" = false ]; then
        return 0
    fi

    files=$(tar czf temp.war ./* && tar tvf temp.war | wc -l)
    rm -f temp.war

    cd "$PROJECT_PATH" || return 0

    local lastest_package=$(ls -l ${BACKUP_PATH} | grep "^-.*${PROJECT_NAME}.*tar*" | sort -rk 9 | awk 'NR==1' | awk '{print $9}')
    if [[ -z $lastest_package ]]; then
        package_files=0
    else
        package_files=$(tar -tvf "${BACKUP_PATH}/${lastest_package}" | wc -l)
    fi
    
    # 先比较备份压缩包和工程路径下的文件数是否相同,相同再检查war包的修改时间
    if [[ $package_files != $files ]]; then
        return 0
    else
        # 取最新一个备份包的修改时间
        re=$(tar --full-time -tvf  "${BACKUP_PATH}/${lastest_package}" | grep -E ".*war")
        backup_modified_time=$(echo $re | cut -d " " -f 4,5)
        # 取工程目录的war包修改时间
        proj_war_modified_time=$(ls -l --time-style="+%Y-%m-%d %H:%M:%S" | grep -E ".*war" | awk '{print $6,$7}')
        if [[ -z $proj_war_modified_time || -z $backup_modified_time ]]; then
            return 0
        fi
        if [[ $backup_modified_time == $proj_war_modified_time ]]; then
            return 1
        else
            return 0
        fi
    fi
}
