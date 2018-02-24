#!/bin/bash


deploy(){

    # 部署前先备份
    if [[ "$ACTION" != "push" ]]; then
        backup  
    fi

    # 所传包名一定是全路径名
    if [[ ! -z $1 ]]; then
        war_name=$1
        if [ ! -e "${war_name}" ] || [ ! -s "${war_name}" ]; then
            echo -e "${REDTXTCOLOR}不存在可以部署的war包(或为空): ${war_name}${TXTCOLOREND}"
            exit
        fi
    else
        cd "$DEPLOY_HOME" || exit
        war_name="${PROJECT_NAME}-web.war"

        # 以下步骤主要将项目target目录的war包拷贝到$DEPLOY_HOME下，并重命名为$war_name
        # 认为该路径下只有一个war包，多出则会出错
        local origin_war=$(ls ${DEPLOY_HOME}/*.war)

        if [ ! -e "${origin_war}" ] || [ ! -s "${origin_war}" ]; then
            echo -e "${REDTXTCOLOR}不存在可以部署的war包(或为空): ${origin_war}${TXTCOLOREND}"
            exit;
        else
            echo -e "${origin_war}\n"
        fi
    fi
    
    [[ -n $PROJECT_PATH ]] && rm -rf $PROJECT_PATH/*

    if [ "$IS_DEPLOY_WAY_WAR" = false ]; then
        if [[ ! -z $1 ]]; then
            # 如果是自定义的发布路径可能属于同一目录，直接解压可能会冲突，需要构建临时目录进行区分
            local temp_proj_deploy=${BASE_HOME}/temp_deploy_${PROJECT_NAME}
            if [ ! -d "${temp_proj_deploy}" ]; then
                mkdir -p ${temp_proj_deploy} 
            fi
            
            cp -f $war_name $temp_proj_deploy
            cd $temp_proj_deploy
            local external_war_name=$(ls $temp_proj_deploy/*.war)
            jar -xf ${external_war_name}
            local res=$(ls | grep -v ".war" | grep -v ".log")
            res=${res//\n/' '}
            cp -rf ./$res $PROJECT_PATH
            rm -rf ${temp_proj_deploy} 
            
        else
            jar -xf ${war_name} 
            local res=$(ls | grep -v ".war" | grep -v ".log")
            res=${res//\n/' '}
            cp -rf ./$res $PROJECT_PATH
        fi
    else
        cp -f ${war_name} ${PROJECT_PATH}
        rm -f ${war_name}
    fi

}
