# مستند پیاده‌سازی سیستم مانیتورینگ و بکاپ Oracle 19c با ارسال اعلان در سروش پلاس

## 1. مقدمه و هدف پروژه

هدف این پروژه، پیاده‌سازی یک سیستم خودکار برای تهیه نسخه پشتیبان از دیتابیس Oracle 19c، بررسی فضای ذخیره‌سازی ASM و ارسال گزارش وضعیت عملیات از طریق پیام‌رسان سروش پلاس است.

این سیستم با استفاده از Shell Script، ابزار RMAN، دستورات SQL و Cron پیاده‌سازی شده است.

اهداف اصلی:

- اجرای خودکار Full Backup دیتابیس به همراه Archive Logها
    
- ثبت اطلاعات هر اجرای بکاپ در فایل لاگ مستقل
    
- بررسی وضعیت Diskgroupهای ASM
    
- محاسبه فضای کل، مصرف‌شده و آزاد ASM
    
- تعیین وضعیت مصرف فضا بر اساس آستانه‌های تعریف‌شده
    
- ارسال گزارش موفقیت یا شکست بکاپ به سروش پلاس
    
- امکان بررسی تاریخچه عملیات و خطاها
    

## 2. معماری کلی سیستم

اجزای اصلی پروژه عبارت‌اند از:

1. Oracle Database 19c
    
2. RMAN برای تهیه نسخه پشتیبان
    
3. ASM برای مدیریت فضای ذخیره‌سازی
    
4. Shell Script برای هماهنگی عملیات
    
5. Cron برای زمان‌بندی اجرا
    
6. Soroush Plus Bot برای ارسال اعلان
    

### روند اجرای سیستم

```
          CRON
            |
            v
   daily_backup_monitor.sh
            |
            v
       RMAN BACKUP
            |
            v
    BACKUP DATABASE
    PLUS ARCHIVELOG
            |
            v
     RMAN COMPLETED
            |
            v
    Read ASM Information
      (After Backup)
            |
            v
    Calculate ASM Usage
            |
            v
     Save Execution Log
            |
            v
    Determine Backup Status
            |
            v
     Build Notification
            |
            v
      Soroush Plus Bot
```

## 3. ساختار پوشه‌ها و فایل‌ها

ساختار اصلی پروژه در مسیر Home کاربر Oracle قرار دارد:

```
/home/oracle/
│
├── scripts/
│   │
│   ├── daily_backup.sh
│   ├── daily_backup_monitor.sh
│   ├── space_scripts.sh
│   │
│   └── backup_logs/
│       ├── rman_YYYYMMDD_HHMMSS.log
│       └── ...
│
└── soroush_bot/
    │
    ├── config/
    │   ├── backup_bot.conf
    │   └── Messgae_test.sh
    │
    └── soroush_logs/
        └── soroush_notif.log
```

توضیح فایل‌ها:

|فایل|کاربرد|
|---|---|
|`daily_backup.sh`|اسکریپت اصلی بکاپ RMAN؛ مستقل نگهداری می‌شود|
|`daily_backup_monitor.sh`|مدیریت اجرای بکاپ، بررسی ASM، ثبت لاگ و ارسال اعلان|
|`space_scripts.sh`|دریافت اطلاعات فضای ASM|
|`backup_bot.conf`|نگهداری تنظیمات و اطلاعات احراز هویت Bot|
|`Messgae_test.sh`|ارسال پیام به سروش پلاس|
|`backup_logs/`|نگهداری لاگ‌های عملیات بکاپ|
|`soroush_logs/`|نگهداری لاگ‌های ارسال پیام|

نکته امنیتی: فایل تنظیمات Bot باید محرمانه باشد و دسترسی آن به کاربران غیرمجاز داده نشود.

```
chmod 600 /home/oracle/soroush_bot/config/backup_bot.conf
```

## 4. تنظیمات اتصال به Oracle Database

در اسکریپت مانیتورینگ، متغیرهای محیطی Oracle تعریف می‌شوند:

```
export ORACLE_SID=orcl
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
```

در این پروژه اتصال RMAN با استفاده از احراز هویت سیستم‌عامل و مجوز SYSBACKUP انجام می‌شود:

```
CONNECT TARGET "/ AS SYSBACKUP";
```

استفاده از SYSBACKUP به جای SYS برای عملیات پشتیبان‌گیری، از نظر تفکیک دسترسی‌ها مناسب‌تر است.

## 5. تهیه نسخه پشتیبان با RMAN

دستور اصلی عملیات بکاپ:

```
RUN {
    BACKUP DATABASE PLUS ARCHIVELOG TAG 'full_BACKUP';
}
```

این دستور شامل موارد زیر است:

- تهیه نسخه پشتیبان از دیتابیس
    
- تهیه نسخه پشتیبان از Archive Logها
    
- ایجاد Backup Pieceها
    
- ایجاد Control File و SPFILE Autobackup مطابق تنظیمات RMAN
    

نمونه مسیر فایل‌های تولیدشده در ASM:

```
+DATA/ORCL/BACKUPS/
```

نمونه نام فایل:

```
orcl_full_ne575n99_750_1_1.bkp
```

نکته: `BACKUP DATABASE PLUS ARCHIVELOG` یک عملیات پشتیبان‌گیری است؛ Full Backup با Incremental Level 0 یکسان نیست، مگر اینکه نوع عملیات به‌صورت مشخص تنظیم شده باشد.

## 6. بررسی فضای ذخیره‌سازی ASM

برای بررسی فضای Diskgroupها از نمای زیر استفاده می‌شود:

```
SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    ROUND((TOTAL_MB - FREE_MB) / 1024, 2) AS USED_GB,
    ROUND(FREE_MB / 1024, 2) AS FREE_GB,
    ROUND((TOTAL_MB - FREE_MB) / TOTAL_MB * 100, 2) AS USED_PERCENT
FROM V$ASM_DISKGROUP;
```

معرفی ستون‌ها:

|ستون|توضیح|
|---|---|
|NAME|نام Diskgroup|
|TOTAL_MB|ظرفیت کل|
|FREE_MB|فضای آزاد|
|USED_GB|فضای مصرف‌شده|
|FREE_GB|فضای آزاد بر حسب GB|
|USED_PERCENT|درصد فضای مصرف‌شده|

فرمول محاسبه فضای مصرف‌شده:

```
USED_MB = TOTAL_MB - FREE_MB
```

فرمول درصد مصرف:

```
USED_PERCENT = (USED_MB / TOTAL_MB) * 100
```

### 6.1 آستانه‌های هشدار ASM

در اسکریپت پروژه سه سطح وضعیت تعریف شده است:

|درصد مصرف|وضعیت|مفهوم|
|---|---|---|
|کمتر از 70%|NORMAL|وضعیت عادی|
|70% تا کمتر از 85%|WARNING|هشدار مصرف فضا|
|85% و بیشتر|CRITICAL|وضعیت بحرانی|

این آستانه‌ها قابل تنظیم هستند و باید متناسب با ظرفیت محیط عملیاتی و سیاست نگهداری بکاپ‌ها تعیین شوند.

## 7. اسکریپت بررسی فضای ASM

فایل:

```
/home/oracle/scripts/space_scripts.sh
```

محتوای اسکریپت:

```
#!/bin/bash

export ORACLE_SID=+ASM
export ORACLE_HOME=/u01/app/19.3.0/grid
export PATH=$ORACLE_HOME/bin:$PATH

"$ORACLE_HOME/bin/sqlplus" -s "/ as sysdba" <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE

SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SET VERIFY OFF
SET ECHO OFF
SET TRIMSPOOL ON
SET LINESIZE 250

SELECT
    CASE
        WHEN ROUND((TOTAL_MB - FREE_MB) / TOTAL_MB * 100, 2) >= 85
            THEN '🔴 CRITICAL'
        WHEN ROUND((TOTAL_MB - FREE_MB) / TOTAL_MB * 100, 2) >= 70
            THEN '🟡 WARNING'
        ELSE '🟢 NORMAL'
    END
    || CHR(10) ||
    'DISKGROUP: ' || NAME || CHR(10) ||
    'TOTAL: ' || ROUND(TOTAL_MB / 1024, 2) || ' GB' || CHR(10) ||
    'USED: ' || ROUND((TOTAL_MB - FREE_MB) / 1024, 2) || ' GB' || CHR(10) ||
    'FREE: ' || ROUND(FREE_MB / 1024, 2) || ' GB' || CHR(10) ||
    'USAGE: ' || ROUND((TOTAL_MB - FREE_MB) / TOTAL_MB * 100, 2) || '%'
FROM V$ASM_DISKGROUP
ORDER BY NAME;

EXIT;
SQL
```

برای اجرای مستقل:

```
/home/oracle/scripts/space_scripts.sh
```

این اسکریپت از Instance مربوط به ASM اطلاعات Diskgroup را دریافت می‌کند.

## 8. اسکریپت اصلی مانیتورینگ و بکاپ

فایل اصلی:

```
/home/oracle/scripts/daily_backup_monitor.sh
```

این فایل وظیفه هماهنگی مراحل اجرای پروژه را بر عهده دارد.

### 8.1 محتوای کامل اسکریپت

```
#!/bin/bash

export ORACLE_SID=orcl
export ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH

BOT_SCRIPT="/home/oracle/soroush_bot/config/Messgae_test.sh"
ASM_SCRIPT="/home/oracle/scripts/space_scripts.sh"
LOG_DIR="/home/oracle/scripts/backup_logs"

RUN_ID=$(date '+%Y%m%d_%H%M%S')
RUN_LOG="${LOG_DIR}/rman_${RUN_ID}.log"

START_TIME=$(date '+%F %T')
START_SECONDS=$(date +%s)

# RMAN Backup
"$ORACLE_HOME/bin/rman" log="$RUN_LOG" <<RMAN_EOF

CONNECT TARGET "/ AS SYSBACKUP";

SET ECHO ON;

RUN {
    BACKUP DATABASE PLUS ARCHIVELOG TAG 'full_BACKUP';
}

EXIT;
RMAN_EOF

RMAN_STATUS=$?

END_TIME=$(date '+%F %T')
END_SECONDS=$(date +%s)

DURATION_SECONDS=$((END_SECONDS - START_SECONDS))

DURATION=$(printf '%02d:%02d:%02d' \
    $((DURATION_SECONDS / 3600)) \
    $((DURATION_SECONDS % 3600 / 60)) \
    $((DURATION_SECONDS % 60)))

# Get ASM information AFTER backup completion
ASM_SPACE=$("$ASM_SCRIPT" 2>&1)
ASM_STATUS=$?

if [ "$ASM_STATUS" -ne 0 ] || [ -z "$ASM_SPACE" ]; then
    ASM_SPACE="⚠️ ASM INFORMATION UNAVAILABLE"
fi

# Save execution information
{
    echo "RMAN_STATUS=$RMAN_STATUS"
    echo "START_TIME=$START_TIME"
    echo "END_TIME=$END_TIME"
    echo "DURATION=$DURATION"
    echo "ASM_SPACE=$ASM_SPACE"
} >> "$RUN_LOG"

# Determine backup status
if [ "$RMAN_STATUS" -eq 0 ] && grep -q "Recovery Manager complete." "$RUN_LOG"; then

    STATUS="SUCCESS"
    STATUS_ICON="🟢"
    ERROR_SECTION=""

else

    STATUS="FAILURE"
    STATUS_ICON="🔴"

    ERROR_DETAIL=$(grep -E 'RMAN-|ORA-' "$RUN_LOG" | tail -n 5)

    if [ -z "$ERROR_DETAIL" ]; then
        ERROR_DETAIL="Check RMAN log for details."
    fi

    ERROR_SECTION="
❌ ERROR DETAILS
${ERROR_DETAIL}"

fi

# Build notification
MESSAGE="╔════════════════════════════╗
       ORACLE DBA MONITOR
╚════════════════════════════╝

${STATUS_ICON} BACKUP STATUS: ${STATUS}

🗄 DATABASE
   Name       : ${ORACLE_SID}
   Backup     : FULL + ARCHIVELOG
   Started    : ${START_TIME}
   Finished   : ${END_TIME}
   Duration   : ${DURATION}

💾 ASM STORAGE (AFTER BACKUP)
${ASM_SPACE}
${ERROR_SECTION}

📋 NOTIFICATION
   🟡 SOROUSH: SENDING

📁 RMAN LOG
${RUN_LOG}

════════════════════════════
       ORACLE MONITORING"

# Send notification
"$BOT_SCRIPT" "$MESSAGE"
NOTIFY_STATUS=$?

if [ "$NOTIFY_STATUS" -eq 0 ]; then
    NOTIFY_LABEL="🟢 SENT"
else
    NOTIFY_LABEL="🔴 FAILED"
fi

echo "BACKUP_STATUS=$STATUS" >> "$RUN_LOG"
echo "NOTIFICATION_STATUS=$NOTIFY_STATUS" >> "$RUN_LOG"

exit "$RMAN_STATUS"
```

### 8.2 توضیح ترتیب اجرای اسکریپت

ترتیب اجرای عملیات اهمیت زیادی دارد.

1. ثبت زمان شروع بکاپ
    
2. اجرای RMAN
    
3. ثبت کد خروجی RMAN
    
4. ثبت زمان پایان بکاپ
    
5. محاسبه مدت اجرای عملیات
    
6. اجرای `space_scripts.sh`
    
7. دریافت وضعیت ASM بعد از اتمام بکاپ
    
8. ذخیره اطلاعات در فایل لاگ
    
9. تعیین وضعیت SUCCESS یا FAILURE
    
10. ساخت پیام و ارسال به سروش پلاس
    

**نکته کلیدی:** در نسخه فعلی، بررسی فضای ASM بعد از اتمام RMAN انجام می‌شود. بنابراین اطلاعات ASM در پیام، وضعیت پس از اجرای بکاپ را نشان می‌دهد، نه وضعیت پیش از آن.

این ترتیب برای هدف فعلی پروژه انتخاب شده است؛ یعنی مشاهده وضعیت فضای ذخیره‌سازی پس از پایان عملیات پشتیبان‌گیری.

## 9. تفاوت حجم Backup و فضای مصرف‌شده ASM

در این پروژه سه شاخص مستقل وجود دارد که نباید با یکدیگر اشتباه گرفته شوند.

### 9.1 فضای مصرف‌شده ASM

از نمای `V$ASM_DISKGROUP` به دست می‌آید.

این مقدار، فضای مصرف‌شده کل Diskgroup است و شامل انواع فایل‌های موجود در آن می‌شود؛ مانند:

- DATAFILE
    
- BACKUPSET
    
- ARCHIVELOG
    
- ONLINELOG
    
- TEMPFILE
    
- CONTROLFILE
    

### 9.2 حجم خروجی RMAN

از نمای `V$RMAN_BACKUP_JOB_DETAILS` قابل بررسی است:

```
SELECT
    SESSION_KEY,
    INPUT_TYPE,
    STATUS,
    START_TIME,
    END_TIME,
    OUTPUT_BYTES_DISPLAY
FROM V$RMAN_BACKUP_JOB_DETAILS
ORDER BY START_TIME DESC;
```

ستون `OUTPUT_BYTES_DISPLAY` حجم خروجی ثبت‌شده برای Backup Job را نشان می‌دهد.

### 9.3 حجم فایل‌های Backupset در ASM

برای بررسی حجم فایل‌های Backupset:

```
SELECT
    TYPE,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS SIZE_GB,
    COUNT(*) AS FILE_COUNT
FROM V$ASM_FILE
WHERE GROUP_NUMBER = (
    SELECT GROUP_NUMBER
    FROM V$ASM_DISKGROUP
    WHERE NAME = 'DATA'
)
AND TYPE IN ('BACKUPSET', 'AUTOBACKUP')
GROUP BY TYPE
ORDER BY TYPE;
```

این Query حجم فایل‌های Backupset و Autobackup موجود در ASM را نشان می‌دهد.

نکته: حجم خروجی RMAN، حجم فایل‌های Backupset موجود و افزایش فضای مصرفی ASM الزاماً برابر نیستند. ممکن است Backupهای قدیمی، سایر فایل‌ها یا عملیات هم‌زمان روی فضای ASM تأثیر بگذارند.

## 10. زمان‌بندی عملیات با Cron

برای مشاهده Cron کاربر Oracle:

```
crontab -l
```

برای ویرایش:

```
crontab -e
```

تنظیم اجرای هر 10 دقیقه:

```
*/10 * * * * /home/oracle/scripts/daily_backup_monitor.sh
```

این زمان‌بندی به معنای اجرای عملیات در دقیقه‌های زیر است:

```
00
10
20
30
40
50
```

یعنی در هر ساعت شش بار اجرا می‌شود.

**هشدار عملیاتی:** اجرای Full Backup به همراه Archive Log هر 10 دقیقه صرفاً برای تست و مانیتورینگ کوتاه‌مدت مناسب است و نباید بدون بررسی ظرفیت، سیاست نگهداری، مدت اجرای بکاپ و بار سیستم به‌عنوان زمان‌بندی دائمی استفاده شود.

برای مشاهده Cron:

```
crontab -l
```

برای مشاهده لاگ‌های مربوط به Cron، بسته به توزیع لینوکس و تنظیمات سیستم:

```
grep CRON /var/log/cron
```

یا:

```
journalctl -u crond
```

## 11. بررسی فایل‌های لاگ

هر بار اجرای مانیتورینگ یک فایل لاگ مستقل ایجاد می‌کند.

نمونه:

```
/home/oracle/scripts/backup_logs/rman_20261111_122001.log
```

مشاهده آخرین فایل‌ها:

```
ls -lt /home/oracle/scripts/backup_logs/
```

مشاهده محتوای یک لاگ:

```
cat /home/oracle/scripts/backup_logs/rman_20261111_122001.log
```

مشاهده وضعیت نهایی:

```
grep -E 'RMAN_STATUS|START_TIME|END_TIME|DURATION|BACKUP_STATUS|NOTIFICATION_STATUS' \
/home/oracle/scripts/backup_logs/rman_20261111_122001.log
```

مقادیر مهم:

|مقدار|مفهوم|
|---|---|
|RMAN_STATUS=0|اجرای موفق فرایند RMAN|
|BACKUP_STATUS=SUCCESS|بکاپ موفق تشخیص داده شده|
|NOTIFICATION_STATUS=0|اجرای موفق اسکریپت ارسال پیام|
|DURATION|مدت اجرای عملیات|

کد خروجی صفر از اسکریپت ارسال پیام، به‌تنهایی تضمین تحویل نهایی پیام توسط سرویس مقصد نیست؛ برای اطمینان بیشتر باید لاگ سرویس ارسال نیز بررسی شود.

## 12. نمونه نتایج آزمایش پروژه

در آزمایش‌های انجام‌شده در تاریخ 11 نوامبر 2026، چند اجرای متوالی RMAN بررسی شد.

### 12.1 نتایج Backup Job

|زمان شروع|وضعیت|حجم خروجی|
|---|---|---|
|11:50|COMPLETED|4.26 GB|
|11:58|COMPLETED|4.26 GB|
|12:00|COMPLETED|4.26 GB|
|12:20|COMPLETED|4.28 GB|

### 12.2 بررسی فضای ASM

در یک مرحله از آزمایش:

|شاخص|مقدار|
|---|---|
|Total|39.99 GB|
|Used|12.07 GB|
|Free|27.93 GB|
|Usage|30.17%|

### 12.3 بررسی فایل‌های Backup

در زمان بررسی، نتیجه Query فایل‌های ASM به شکل زیر بود:

|نوع فایل|حجم|تعداد|
|---|---|---|
|BACKUPSET|8.56 GB|16|
|AUTOBACKUP|0.02 GB|1|

این مقادیر مربوط به فایل‌های موجود در زمان اجرای Query هستند، نه فقط یک Backup Job مشخص.

## 13. نکات امنیتی و عملیاتی

- اطلاعات Bot و Token نباید در لاگ‌های عمومی یا مستندات منتشر شوند.
    
- فایل تنظیمات Bot باید دسترسی محدود داشته باشد.
    
- اسکریپت‌ها باید با کاربر مجاز Oracle اجرا شوند.
    
- حذف Backupها باید با RMAN و مطابق سیاست نگهداری انجام شود.
    
- حذف مستقیم فایل‌های Backup از مسیر ASM با دستورات سیستم‌عامل توصیه نمی‌شود.
    
- پیش از حذف Backupهای قدیمی باید وضعیت Recovery و نیازهای نگهداری بررسی شود.
    
- فضای ASM باید به‌صورت دوره‌ای پایش شود.
    
- اجرای هم‌زمان چند Backup باید کنترل شود تا موجب افزایش بار سیستم و مصرف غیرمنتظره فضا نشود.
    

## 14. عیب‌یابی

### خطای اتصال RMAN

بررسی متغیرهای محیطی:

```
echo $ORACLE_SID
echo $ORACLE_HOME
```

بررسی اتصال:

```
sqlplus / as sysdba
```

### خطای دسترسی به ASM

بررسی گروه‌های کاربر Oracle:

```
id oracle
```

بررسی اتصال به ASM:

```
export ORACLE_SID=+ASM
sqlplus / as sysdba
```

### اجرا نشدن Cron

```
crontab -l
systemctl status crond
```

### ارسال نشدن پیام

بررسی لاگ ارسال:

```
tail -n 50 /home/oracle/soroush_bot/soroush_logs/soroush_notif.log
```

### بررسی Syntax اسکریپت

```
bash -n /home/oracle/scripts/daily_backup_monitor.sh
```

در صورت نبود خروجی، خطای Syntax گزارش نشده است.

## 15. بهبودهای پیشنهادی برای نسخه‌های بعدی

موارد زیر می‌توانند در توسعه آینده پروژه پیاده‌سازی شوند:

1. نمایش حجم خروجی هر Backup Job در پیام تلگرام یا سروش پلاس.
    
2. نمایش تعداد Backup Pieceهای ایجادشده.
    
3. بررسی مدت زمان اجرای RMAN و تشخیص طولانی‌شدن غیرعادی عملیات.
    
4. مدیریت Retention Policy و حذف Backupهای منقضی‌شده با RMAN.
    
5. هشدار مستقل برای نزدیک‌شدن فضای ASM به وضعیت بحرانی.
    
6. ثبت تاریخچه مصرف ASM برای تحلیل روند رشد.
    
7. اصلاح بخش وضعیت ارسال پیام در متن اعلان به‌گونه‌ای که نتیجه واقعی ارسال نمایش داده شود.
    
8. جلوگیری از اجرای هم‌زمان چند نسخه از اسکریپت مانیتورینگ.
    
9. بررسی سلامت فایل‌های Backup با استفاده از قابلیت‌های اعتبارسنجی RMAN.
    

## 16. جمع‌بندی

در این پروژه یک سیستم خودکار برای تهیه نسخه پشتیبان Oracle 19c، بررسی فضای ذخیره‌سازی ASM، ثبت لاگ و ارسال اعلان از طریق سروش پلاس طراحی و پیاده‌سازی شده است.

یکی از اصلاحات مهم در نسخه فعلی، انتقال اجرای اسکریپت بررسی ASM به بعد از اتمام عملیات RMAN است.

به این ترتیب، گزارش ارسالی وضعیت واقعی Diskgroup را پس از پایان بکاپ نشان می‌دهد و امکان بررسی تأثیر عملیات Backup بر فضای ذخیره‌سازی فراهم می‌شود.

این