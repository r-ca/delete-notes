#!/bin/bash



#Check if file exists
if [ ! -e ./config.txt ]; then
    echo ERROR: config.txt is not exist.
    exit
fi

#Import config
TEMP='' #Initializing variables. 
TEMP=`cat ./config.txt | grep -s address`
ADDRESS=${TEMP:8}
TEMP=`cat ./config.txt | grep -s userid`
USERID=${TEMP:7}
TEMP='' #Initializing variables.
TEMP=`cat ./config.txt | grep -s token`
TOKEN=${TEMP:6}
TEMP='' #Initializing variables. #リプライ保護(todo)
TEMP=`cat ./config.txt | grep -s protectReplies`
REPLY_PROTECT=${TEMP:15}
TEMP='' #Initializing variables. 
TEMP=`cat ./config.txt | grep -s limit`
LIMIT=${TEMP:6}

#最大取得数検証
if [ $LIMIT -le 0 ]; then
    echo 'ERROR: Illegal limit value. (1~100)'
    exit
fi
if [ $LIMIT -ge 101 ]; then
    echo 'ERROR: Illegal limit value. (1~100)'
    exit
fi

#リプライ保護コンフィグ検証
if [ $REPLY_PROTECT != "true" ]; then
    if [ $REPLY_PROTECT != "false" ]; then
        echo 'ERROR: Reply protection setting contains invalid character string. (true of false)'
        exit
    fi
fi

#IncludeReplyで使うため中身を反対に
if [ $REPLY_PROTECT = "true" ]; then
    REPLY_PROTECT=false
fi
if [ $REPLY_PROTECT = "false" ]; then
    REPLY_PROTECT=true
fi



#ノートIDなど（検討中）
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

    echo "CURRENT: ${#NOTE_ID[@]}"
done

echo "TOTAL: ${#NOTE_ID[@]}"

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
    if [ $(($CURRENT_TIME_UNIX - $n)) -ge 21600 ]; then
        sleep 2
        curl -s -X POST -H "Content-Type: application/json" -d '{"noteId": "'${NOTE_ID[c]}'","i": "'$TOKEN'"}' https://${ADDRESS}/api/notes/delete
    else
        echo Protected
    fi
    echo "$c/${#NOTE_ID[@]} Processing completed."
    c=$(($c+1))
done