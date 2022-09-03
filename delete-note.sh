#!/bin/bash

#configファイル存在確認
if [ ! -e ./config.txt ]; then
    echo ERROR: config.txt is not exist.
    exit
fi

if [ ${1} = "-q" ]; then
    #configのインポート(仮実装)
    TEMP='' #Initializing variables.  #インスタンスアドレス
    TEMP=`cat ./config.txt | grep -s address`
    ADDRESS=${TEMP:8}
    TEMP='' #Initializing variables. #ユーザーID
    TEMP=`cat ./config.txt | grep -s userid`
    USERID=${TEMP:7}
    TEMP='' #Initializing variables. #トークン
    TEMP=`cat ./config.txt | grep -s token`
    TOKEN=${TEMP:6}
    TEMP='' #Initializing variables. #リプライ保護
    TEMP=`cat ./config.txt | grep -s protectReplies`
    REPLY_PROTECT=${TEMP:15}
    TEMP='' #Initializing variables. #リミット
    TEMP=`cat ./config.txt | grep -s limit`
    LIMIT=${TEMP:6}
    TEMP='' #Initializing variables. #保護期間
    TEMP=`cat ./config.txt | grep -s protectionPeriod`
    PROTECTION_PERIOD=${TEMP:17}
else
    read -p "Instance address : " ADDRESS
    read -p "Misskey user ID : " USERID
    read -p "Misskey token : " TOKEN
    read -p "Reply protection (true/false): " REPLY_PROTECT
    read -p "Number of notes to retrieve in one request (1~100) : " LIMIT
    read -p "Note protection period (sec) : " PROTECTION_PERIOD
fi

#最大取得数検証
if [ $LIMIT -le 0 ]; then
    if [ ${1} = "-q" ]; then #-q
        echo 'ERROR: Illegal limit value. (1~100)'
        exit
    else
        exit
    fi
fi
if [ $LIMIT -ge 101 ]; then
    if [ ${1} = "-q" ]; then #-q
        echo 'ERROR: Illegal limit value. (1~100)'
        exit
    else
        exit
    fi
fi

#リプライ保護コンフィグ検証
if [ $REPLY_PROTECT != "true" ]; then
    if [ $REPLY_PROTECT != "false" ]; then
        if [ ${1} = "-q" ]; then #-q
            echo 'ERROR: Reply protection setting contains invalid character string. (true of false)'
            exit
        else
            exit
        fi
    fi
fi

#IncludeReplyで使うため中身を反対に
if [ $REPLY_PROTECT = "true" ]; then
    REPLY_PROTECT=false
fi
if [ $REPLY_PROTECT = "false" ]; then
    REPLY_PROTECT=true
fi



#初回ノート取得
OUTPUT='' #Initializing variables
OUTPUT=`curl -X POST -s -H "Content-Type: application/json" -d '{"userId": "'$USERID'","i": "'$TOKEN'","limit": '$LIMIT',"includeReplies": '$REPLY_PROTECT'}' https://${ADDRESS}/api/users/notes`
CREATED_AT=(`echo $OUTPUT | jq -r '.[] | .createdAt'`)
NOTE_ID=(`echo $OUTPUT | jq -r '.[] | .id'`)

length=${#NOTE_ID[@]}
length=$(($length-1))
UNTIL_ID=${NOTE_ID[$length]}
while [ "$UNTIL_ID" != "$LAST_ID" ]
do
    length=${#NOTE_ID[@]}
    length=$(($length-1))
    UNTIL_ID=${NOTE_ID[$length]}

    OUTPUT=`curl -s -X POST -H "Content-Type: application/json" -d '{"userId": "'$USERID'","i": "'$TOKEN'","untilId": "'$UNTIL_ID'","limit": '$LIMIT',"includeReplies": '$REPLY_PROTECT'}' https://${ADDRESS}/api/users/notes`
    CREATED_AT+=(`echo $OUTPUT | jq -r '.[] | .createdAt'`)
    NOTE_ID+=(`echo $OUTPUT | jq -r '.[] | .id'`)

    length=${#NOTE_ID[@]}
    length=$(($length-1))
    LAST_ID=${NOTE_ID[$length]}

    if [ ${1} = "-q" ]; then #-q
        echo "CURRENT: ${#NOTE_ID[@]}"
    fi
done

if [ ${1} = "-q" ]; then #-q
    echo "TOTAL: ${#NOTE_ID[@]}"
fi

n=0
for m in "${CREATED_AT[@]}" #投稿日時をいい感じ™に変換(UNIX時間にする)
do
    if [ "$(uname)" == 'Darwin' ]; then
        CREATED_AT[$n]=`date -u -j -f "%Y-%m-%d %H:%M:%S" "${m:0:10} ${m:11:8}" +%s` #macOS用
    else
        CREATED_AT[$n]=`date -u +%s --date '${m:0:10} ${m:11:8}'` #Linux用
    fi
    n=$(($n + 1))
done

CURRENT_TIME_UNIX=`date -u +%s`
c=0
for n in "${CREATED_AT[@]}"
do
    if [ $(($CURRENT_TIME_UNIX - $n)) -ge $PROTECTION_PERIOD ]; then
        sleep 2
        curl -s -X POST -H "Content-Type: application/json" -d '{"noteId": "'${NOTE_ID[c]}'","i": "'$TOKEN'"}' https://${ADDRESS}/api/notes/delete
    else
        if [ ${1} = "-q" ]; then #-q
            echo Protected
        fi
    fi
        if [ ${1} = "-q" ]; then #-q
            echo "$c/${#NOTE_ID[@]} Processing completed."
        fi
    c=$(($c+1))
done