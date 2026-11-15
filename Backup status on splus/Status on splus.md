

prerequests:
1- BOT
2- cURL

1. Create a Bot in splus 

2. check you cURL version
   
   ```
   $ curl --version
   curl 7.29.0 
   ```

If you didn't have it :

```
dnf install curl -y
```

3. check the connection with splus server 
   
   ```
   curl -I --connect-timeout 10 https://api.splus.ir
   ```


you may get this :

```
[oracle@oraclehost scripts]$ curl -I --connect-timeout 10 https://api.splus.ir
HTTP/1.1 404 Not Found
Date: Mon, 09 Nov 2026 12:10:18 GMT
Content-Type: application/json
Connection: keep-alive


```

this means we had a connection but because we asked for main address you get this .


4. took you API  from the bot you created 

5. create a config file in the oracle-linux

```
vi /home/oracle/soroush_bot/config/backup_bot.conf
```

Inside this :

```
BOT_CONFIG='YOUR REAL BOT TOKEN'
```

limit permission :

```
chmod 600 /home/oracle/soroush_bot/config/backup_bot.conf
```

6. here with getme method you check you TOKEN Credibility
   
   ```
   source /home/oracle/soroush_bot/config/bot.conf

   curl -sS "https://api.splus.ir/bot${BOT_TOKEN}/getMe"
   ```


```
 {"ok":true,"result":{"id":********,"is_bot":true,"first_name":"bot_name","username":"bot_username","can_join_groups":false,"can_read_all_group_messages":false,"supports_inline_queries":false}}[
```

7. Now we should check that where the robot send the messages  
   * Open the bot and send message 
   * in the linux :
     ```
     $ curl -sS "https://api.splus.ir/bot${BOT_TOKEN}/getUpdates"
     ```
     If you got the result means it worked alright 
     
   * From our result we see an ID 
     
     ```
     "chat": {
  "id": ******,
  "type": "private"
}
     ```


took it and paste it inside the .conf in the linux 

8. Now we send a request to achieve the message from Splus
   
   ```
   curl -sS -X POST \
"https://api.splus.ir/bot${BOT_TOKEN}/sendMessage" \
-d "chat_id=${CHAT_ID}" \
--data-urlencode "text=Hello Dorsa! Oracle Linux Backup Monitor is connected successfully."
   ```

If it is ok you should get the message in the Splus


9. Create message scripts

create a bash script file :

```
vi /home/oracle/soroush_bot/config/Messgae_test.sh
```


Enter i to start editing the file and insert the code below 

```

#!/bin/bash

# Configuration
CONFIG_FILE="/home/oracle/soroush_bot/config/bot.conf"
LOG_FILE="/home/oracle/soroush_bot/logs/notification.log"

# Check configuration file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found"
    exit 1
fi

# Load configuration
source "$CONFIG_FILE"

# Validate variables
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "ERROR: BOT_TOKEN or CHAT_ID is missing"
    exit 1
fi

# Check input message
if [ -z "$1" ]; then
    echo "ERROR: Message is empty"
    exit 1
fi

MESSAGE="$1"

# Send message
RESPONSE=$(curl -sS --connect-timeout 10 --max-time 30 \
    -X POST \
    "https://api.splus.ir/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${MESSAGE}" 2>&1)

CURL_STATUS=$?

# Check cURL result
if [ $CURL_STATUS -ne 0 ]; then
    echo "$(date '+%F %T') | CURL ERROR: $RESPONSE" >> "$LOG_FILE"
    exit 1
fi

# Check API response
if echo "$RESPONSE" | grep -qi '"ok":[[:space:]]*true'; then
    echo "$(date '+%F %T') | SUCCESS | Message sent" >> "$LOG_FILE"
    echo "Message sent successfully"
    exit 0
else
    echo "$(date '+%F %T') | API ERROR: $RESPONSE" >> "$LOG_FILE"
    echo "Message sending failed"
    exit 1
fi

```

save it and then set the permmissions:

```
chmod 700 /home/oracle/soroush_bot/scripts/send_soroush_message.sh
```


run this following command :
```
/home/oracle/soroush_bot/scripts/send_soroush_message.sh "Hello! My Oracle Linux notification script is working."
```


you must get this message from your bot :

```
Message sent successfully
```


10. Create a backup script 


```
vi /home/oracle/scripts/daily_backup.sh
```



```
#!/bin/bash

export ORACLE_SID=orcl
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH

$ORACLE_HOME/bin/rman log=/home/oracle/scripts/rman1.log append <<EOF

CONNECT TARGET "/ AS SYSBACKUP";

SET ECHO ON;

RUN {
    BACKUP DATABASE PLUS ARCHIVELOG TAG 'full_BACKUP';
}

EXIT;
EOF
```

