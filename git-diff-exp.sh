#!/bin/sh
#set -x

CMDNAME=$(basename $0)
CURRDIR=$(pwd)
TMPFILE=`basename ${CMDNAME}_LIST`.$$
LOGDIR="./log"


#返却値
RC_OK=0
RC_ERROR=1
RC_CANCEL=2

# ON/OFFフラグ
FLG_OFF=0
FLG_ON=1

#初期値
FORCEMODE=${FLG_OFF}
NAMEONLY=${FLG_OFF}
P_AFTER="HEAD"
EXPORT="html"

###############################
# バージョン情報
###############################
version() {
    echo "${CMDNAME} version 0.0.1 "
}

###############################
# コマンドリファレンス
###############################
usage()
{
cat << EOF

    ${CMDNAME} is a tool for ...

    Usage:
        ${CMDNAME} [--before <hash string>] [--after <hash string>]
                   [--list <file>] [--name-only]
                   [--version] [--help]

    Options:
        --before, -b        変更前GITリビジョンID
        --after, -a         変更後GITリビジョンID
        --list, -l          取得対象一覧ファイル名
        --name-only, -o     取得対象一覧ファイル生成モード
        --export, -x        HTMLファイル出力先ディレクトリ
        --version, -v       バージョン情報
        --help, -h          コマンドリファレンス

EOF
}


###############################
# yes/no judgement
###############################
yesno_chk()
{
    read ANSWER?"よろしいですか？(y/n)-->"
    while true;do
    case ${ANSWER} in
        yes | y)
        return ${RC_OK}
        ;;
        *)
        return ${RC_CANCEL}
        ;;
    esac
    done
}

###############################
# パラメータオプション取得関数
###############################
get_options()
{
    # param count
    if [[ $# -eq 0 ]]; then
        usage
        return ${RC_ERROR}
    fi

    # get options
    while [ $# -gt 0 ];
    do
        case ${1} in

            --debug|-d)
                set -x
            ;;

            --before|-b)
                P_BEFORE=${2}
                shift
            ;;

            --after|-a)
                P_AFTER=${2}
                shift
            ;;

            --list|-l)
                P_LIST=${2}
                shift
            ;;

            --name-only|-o)
                NAMEONLY=${FLG_ON}
            ;;

            --export|-x)
                EXPORT=${2}
                shift
            ;;

            --force|-f)
                FORCEMODE=${FLG_ON}
            ;;
        
            --version|-v)
                version
                return ${RC_ERROR}
            ;;

            --help|-h)
                usage
                return ${RC_ERROR}
            ;;

            *)
                echo "[${CMDNAME}][ERROR] Invalid option '${1}'"
                usage
                return ${RC_ERROR}
            ;;
        esac
        shift
    done
}

###############################
# 必須パラメータチェック関数
###############################
necessary_param_chk()
{
    if [ ${FORCEMODE} -eq ${FLG_OFF} ]; then

        if [ -z "${P_BEFORE}" ]; then
            read P_BEFORE?"Compression source commit ID?: "
        fi

    else
        if [ -z "${P_BEFORE}" ]; then
            echo "[${CMDNAME}][ERROR] no definition for compression source."
            echo "See '${CMDNAME} --help'"
            return ${RC_ERROR}
        fi

    fi
    return ${RC_OK}

}

###############################
# ディレクトリ作成関数
###############################
make_dir()
{
    DNAME=$1
    # DIFFディレクトリ作成
    if [ ! -d "${DNAME}" ]; then
        echo "[${CMDNAME}] create ${DNAME} directory ..."
        mkdir -p ${DNAME}
        if [[ $? -ne ${RC_OK} ]]
        then
            echo "[${CMDNAME}][ERROR] error occurred : mkdir ${DNAME}"
            return ${RC_ERROR}
        fi
    fi 
    return ${RC_OK}
}

make_log_directory()
{

    # DIFFディレクトリ作成
    make_dir ${DIFFDIR}
    if [[ $? -ne ${RC_OK} ]]
    then
        return ${RC_ERROR}
    fi

    # ORGディレクトリ作成
    make_dir ${ORGDIR}
    if [[ $? -ne ${RC_OK} ]]
    then
        return ${RC_ERROR}
    fi

    # NEWディレクトリ作成
    make_dir ${NEWDIR}
    if [[ $? -ne ${RC_OK} ]]
    then
        return ${RC_ERROR}
    fi

    # EXPORTディレクトリ作成
    make_dir ${EXPDIR}
    if [[ $? -ne ${RC_OK} ]]
    then
        return ${RC_ERROR}
    fi

    return ${RC_OK}

}


###############################
# DIFFファイル取得
###############################
get_diff_list()
{
    git diff ${P_BEFORE}..${P_AFTER} --name-only > ${DIFFDIR}.lst
    P_LIST=${DIFFDIR}.lst
}
###############################
# DIFFファイル取得
###############################
get_diff_files()
{
    cd $(git rev-parse --show-toplevel)

    echo "[${CMDNAME}] get diff files ..."

# diffリスト取得
    cat ${CURRDIR}/${P_LIST} | awk -v currdir=${CURRDIR} -v argdir=${DIFFDIR} -v argbefore=${P_BEFORE} -v argafter=${P_AFTER} '{
        arg1=$1;
        num=split(arg1,arr,"/");
        arg2=sprintf("%s/%s/%s.diff",currdir,argdir,arr[num]);
        arg=sprintf("git diff %s..%s %s > %s ",argbefore,argafter,arg1,arg2);
        #print(arg);
        system(arg);
    }'
    cd ${CURRDIR}
    return ${RC_OK}

}

###############################
# 特定のコミットのファイル取得
###############################
get_div_files()
{
    L_DIV=$1
    L_DIR=$2

    echo "[${CMDNAME}] get ${L_DIV} files ..."

    cd $(git rev-parse --show-toplevel)

    cat ${CURRDIR}/${P_LIST} | awk -v currdir=${CURRDIR} -v argdir=${L_DIR} -v argdiv=${L_DIV} '{
        arg1=$1;
        num=split(arg1,arr,"/");
        arg2=sprintf("%s/%s/%s",currdir,argdir,arr[num]);
        arg=sprintf("git show %s:%s > %s ",argdiv,arg1,arg2);
        #print(arg)
        system(arg);
    }'
    cd ${CURRDIR}
    return ${RC_OK}

}

###############################
# HTMLファイル出力取得
###############################
make_html_files()
{
    DIFF_DIR=$1
    EXP_DIR=$2
    cd $(git rev-parse --show-toplevel)
    
    echo "[${CMDNAME}] start convert encoding to utf-8."
    find ${DIFF_DIR} -name "*.diff" -exec nkf -w --overwrite {} \;
    if [[ $? -ne ${RC_OK} ]]
    then
        echo "[${CMDNAME}][ERROR] error occurred : nkf"
        return ${RC_ERROR}
    fi

    echo "[${CMDNAME}] start convert diff to html."
    find ${DIFF_DIR} -name "*.diff" -exec diff2html -s side -F {}.html -i file -- {} \;
    if [[ $? -ne ${RC_OK} ]]
    then
        echo "[${CMDNAME}][ERROR] error occurred : diff2html"
        return ${RC_ERROR}
    fi

    echo "[${CMDNAME}] copy to export directory."
    cd ${DIFF_DIR}
    find . -name "*.html" -exec mv {} ../${EXP_DIR}/{} \;
    if [[ $? -ne ${RC_OK} ]]
    then
        echo "[${CMDNAME}][ERROR] error occurred : mv"
        return ${RC_ERROR}
    fi
    
    cd ${CURRDIR}
    return ${RC_OK}

}

###############################
#
# メイン処理
#
###############################

###############################
# パラメータオプション取得関数
###############################
get_options $@
if [[ $? -ne ${RC_OK} ]]
then
    exit ${RC_ERROR}
fi

###############################
# 作業ディレクトリ作成処理
###############################
# 必須パラメータチェック
necessary_param_chk
if [ $? -ne ${RC_OK} ]; then
    return ${RC_ERROR}
fi

# パラメータから作成ディレクトリ名を生成
ORGBRNC=${P_BEFORE}
NEWBRNC=${P_AFTER}
ORGDIR="${LOGDIR}/${ORGBRNC}"
NEWDIR="${LOGDIR}/${NEWBRNC}"
DIFFDIR="${LOGDIR}/${ORGBRNC}_to_${NEWBRNC}"
EXPDIR="${LOGDIR}/${EXPORT}"

# diffリスト取得
if [[ -z ${P_LIST} ]]
then
    get_diff_list
fi

# 一覧ファイル生成モードの時はここでexit
if [[ ${NAMEONLY} -eq ${FLG_ON} ]]
then
    exit ${RC_OK}
fi

# ディレクトリ作成
make_log_directory
if [ $? -ne ${RC_OK} ]; then
    return ${RC_ERROR}
fi

# diffファイル取得
get_diff_files
if [[ $? -ne ${RC_OK} ]]
then
    echo "[${CMDNAME}][ERROR] error occurred : get_diff_files"
    exit ${RC_ERROR}
fi

# ORGファイル取得
get_div_files ${P_BEFORE} ${ORGDIR}
if [[ $? -ne ${RC_OK} ]]
then
    echo "[${CMDNAME}][ERROR] error occurred : get_div_files ${P_BEFORE} ${ORGDIR}"
    exit ${RC_ERROR}
fi

# NEWファイル取得
get_div_files ${P_AFTER} ${NEWDIR}
if [[ $? -ne ${RC_OK} ]]
then
    echo "[${CMDNAME}][ERROR] error occurred : get_div_files ${P_AFTER} ${NEWDIR}"
    exit ${RC_ERROR}
fi

make_html_files ${DIFFDIR} ${EXPORT}
if [[ $? -ne ${RC_OK} ]]
then
    echo "[${CMDNAME}][ERROR] error occurred : make_html_files ${DIFFDIR} ${EXPDIR}"
    exit ${RC_ERROR}
fi
