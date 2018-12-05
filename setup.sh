#!/bin/bash
#set -x

CMDNAME=$(basename $0)
CURRDIR=$(cd $(dirname $0); pwd)

RC_OK=0
RC_NOTEXISTS=1
RC_SYMBOLIC=2
RC_FILE=3

create_sv_file()
{
	OLD_FNAME=$1
	SV_FNAME=${OLD_FNAME}.sv
	if [ -e ${SV_FNAME} ]; then
		CNT=0
		SV_FNAME_CP=${SV_FNAME}.${CNT}
		while [ -e ${SV_FNAME_CP} ]
		do
			CNT=$((${CNT} + 1 ))
			SV_FNAME_CP=${SV_FNAME}.${CNT}
		done
		SV_FNAME=${SV_FNAME_CP}
	fi
	echo "[${CMDNAME}] Create backup file   : ${SV_FNAME}"
	mv ${OLD_FNAME} ${SV_FNAME}
}

file_check()
{
	if [ -e $1 ]; then
		if [ -L $1 ]; then
			#echo $1 is symbolic link
			return ${RC_SYMBOLIC}
		else
			#echo $1 is not symbolic link
			create_sv_file $1
			return ${RC_FILE}
		fi
	else
		#echo $1 is not exists
		return ${RC_NOTEXISTS}
	fi
}

make_bin_directory()
{
	DIRNAME=~/bin
	# ログディレクトリ作成
	if [ ! -d "${DIRNAME}" ]; then
		echo "[${CMDNAME}] Create ${DIRNAME} directory ..."
		mkdir ${DIRNAME}
		if [[ $? -ne ${RC_OK} ]]
		then
			echo "[${CMDNAME}][ERROR] error occurred : mkdir ${DIRNAME}"
			return ${RC_ERROR}
		fi
	fi
	return ${RC_OK}
}


make_bin_directory
if [ $? -ne ${RC_OK} ]; then
	exit ${RC_ERROR}
fi

FNAME=~/bin/git-diff-exp.sh
file_check ${FNAME}
if [ $? -eq ${RC_FILE} -o $? -eq ${RC_NOTEXISTS} ]; then
	echo "[${CMDNAME}] Create symbolic link : ${FNAME}"
	ln -s ${CURRDIR}/git-diff-exp.sh ${FNAME}
fi

exit ${RC_OK}
