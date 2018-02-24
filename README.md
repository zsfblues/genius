# genius
一个基于 shell 结合 git， maven，tomcat 的发布脚本


# 使用说明
该脚本主要有以下几个命令
1) run
也是最全的命令，包含 git 更新，maven编译以及后续的项目部署，web 容器启动
usage:
sh bootstrap.sh 项目名 run 分支名 
2) push
该命令会在拉取更新后将项目推送到指定远程主机的指定目录(目录非必填项)
usage：
sh bootstrap.sh 项目名 push 分支名  ip[:目录全路径(非必填，有默认推送路径)]
bootstrap.sh 项目名 push -r 不再重新拉取更新编译，直接将原先 target 目录中的 war 进行发送
3) deploy
该命令会将编译后好的war包进行部署(你也可以选择非war部署，可修改lib/env.sh 下IS_DEPLOY_WAY_WAR)
usage：
sh bootstrap.sh 项目名 deploy  [目录全路径(非必填，主要和push命令结合使用)]
4) restart
重启 web 容器
usage：
sh bootstrap.sh 项目名 restart
5）backup
备份当前项目
usage：
sh bootstrap.sh 项目名 backup
6）rollback
根据项目的历史备份进行版本回滚
usage：
sh bootstrap.sh 项目名 rollback 数字(比如1代表最后一次备份版本，2代表倒数第二次备份版本，以此类推...)

# 使用前注意事项
1. 使用前需要，在lib/env.sh下设置BASE_HOME变量作为自定义脚本运行过程中产生的中间数据根目录，Linux下需要看看是否有其操作权限
2. APPS数组 代表具体要部署的项目名，建议项目有统一的前缀名，方便部署时简化输入，前缀名可以在
bootstrap.sh的 PROJ_PREFIX 中设置
3. 每个 项目都在lib/env.sh下单独配置如下：
    # 针对单个项目的配置git地址
    GIT_REPOSITORY=""
    # 针对单个项目的部署tomcat名
    TOMCAT_NAME=""
    # 一般是项目的target目录，用来获得编译后的war包
    WEB_PATH=""
