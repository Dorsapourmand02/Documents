

**موضوع:** افزایش ظرفیت ASM Disk Group با اضافه کردن دیسک جدید  
**سیستم‌عامل:** Oracle Linux  
**دیتابیس:** Oracle Database 19c  
**روش مدیریت دیسک:** Udev Rules  
**Disk Group:** DATA  
**ASM Owner:** grid  
**ASM Group:** asmadmin

---

## ۱. هدف

هدف این عملیات، اضافه کردن یک دیسک مجازی جدید به محیط Linux و معرفی آن به Oracle ASM است تا ظرفیت Disk Group موجود افزایش پیدا کند.

در این سناریو، یک دیسک مجازی 20GB به ماشین مجازی اضافه شده و سپس به Disk Group با نام `DATA` معرفی می‌شود.

## ۲. ساختار اولیه محیط

قبل از شروع عملیات، وضعیت دیسک‌های موجود به شکل زیر بود:

|دیسک|ظرفیت|کاربرد|
|---|---|---|
|`/dev/sda`|100GB|دیسک سیستم‌عامل|
|`/dev/sdb`|20GB|دیسک فعلی ASM|
|`/dev/sdb1`|20GB|پارتیشن عضو DATA|

وضعیت دیسک موجود در ASM:

```
SELECT NAME, PATH, TOTAL_MB, FREE_MB,
       HEADER_STATUS, MOUNT_STATUS
FROM V$ASM_DISK;
```

نتیجه:

- Disk Name: DATA_0000
    
- Path: /dev/sdb1
    
- Header Status: MEMBER
    
- Mount Status: CACHED
    
- Total: 20476 MB
    
- Free: 9148 MB
    

**نکته:** به دیسک‌های موجود و به‌خصوص دیسک سیستم‌عامل نباید دست زده شود.

## ۳. اضافه کردن دیسک مجازی به ماشین

ابتدا یک Virtual Disk جدید به ماشین مجازی اضافه می‌کنیم.

در این سناریو، یک دیسک 20GB به ماشین VMware اضافه شد.

پس از روشن شدن ماشین، با کاربر root وارد Linux می‌شویم.

## ۴. شناسایی دیسک جدید در Linux

**کاربر اجراکننده: root**

```
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
```

برای بررسی جزئیات دیسک‌ها:

```
fdisk -l
```

در این سناریو، دیسک جدید با نام `/dev/sdc` شناسایی شد.

ساختار دیسک‌ها:

```
sda    100G   Operating System
sdb     20G   Existing ASM Disk
└─sdb1  20G   Existing ASM Partition
sdc     20G   New Disk
```

**نکته مهم:** نام دیسک جدید ممکن است در محیط‌های دیگر متفاوت باشد. همیشه خروجی `lsblk` را بررسی کنید و صرفاً به نام `/dev/sdc` اعتماد نکنید.

## ۵. بررسی روش مدیریت دیسک‌های ASM

ابتدا بررسی می‌کنیم که آیا ASMLib نصب شده است یا خیر.

**کاربر اجراکننده: root**

```
oracleasm status
```

بررسی پکیج‌ها:

```
rpm -qa | grep -i oracleasm
```

در این سناریو، دستور `oracleasm` در سیستم وجود نداشت و پکیج مرتبط نیز نصب نبود.

سپس فایل‌های Udev را بررسی کردیم:

```
ls -l /etc/udev/rules.d/
```

فایل زیر وجود داشت:

```
/etc/udev/rules.d/99-oracle-asmdevices.rules
```

بنابراین روش مدیریت Permission دیسک‌های ASM در این محیط Udev است.

## ۶. بررسی دیسک فعلی و جدید

**کاربر اجراکننده: root**

بررسی Signature دیسک‌ها:

```
blkid /dev/sdb1 /dev/sdc
```

نتیجه:

```
/dev/sdb1: TYPE="oracleasm"
```

دیسک جدید فاقد Signature شناخته‌شده بود.

بررسی Partition Table:

```
fdisk -l /dev/sdb /dev/sdc
```

مشخص شد:

- دیسک `/dev/sdb` دارای Partition Table از نوع DOS است.
    
- پارتیشن `/dev/sdb1` از سکتور 2048 شروع شده است.
    
- دیسک `/dev/sdc` هنوز پارتیشن‌بندی نشده است.
    

## ۷. ساخت پارتیشن روی دیسک جدید

**کاربر اجراکننده: root**

```
fdisk /dev/sdc
```

در محیط fdisk دستورات زیر را وارد می‌کنیم:

```
n
p
1
2048
Enter
t
83
w
```

توضیح دستورات:

|دستور|عملکرد|
|---|---|
|n|ایجاد پارتیشن جدید|
|p|انتخاب Primary|
|1|شماره پارتیشن|
|2048|سکتور شروع|
|Enter|انتخاب سکتور پایان پیش‌فرض|
|t|تغییر نوع پارتیشن|
|83|انتخاب Linux|
|w|ذخیره تغییرات|

سپس جدول پارتیشن‌ها را به‌روزرسانی می‌کنیم:

```
partprobe /dev/sdc
```

بررسی نتیجه:

```
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
```

نتیجه مورد انتظار:

```
sdc    20G disk
└─sdc1 20G part
```

## ۸. تنظیم Udev برای دیسک جدید

ابتدا فایل تنظیمات فعلی را بررسی می‌کنیم:

```
cat /etc/udev/rules.d/99-oracle-asmdevices.rules
```

در این محیط، دیسک قبلی با مشخصات زیر در اختیار ASM قرار گرفته بود:

- OWNER: grid
    
- GROUP: asmadmin
    
- MODE: 0660
    

محتوای صحیح فایل باید به شکل زیر باشد:

```
KERNEL=="sdb1", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sdc1", OWNER="grid", GROUP="asmadmin", MODE="0660"
```

برای بازنویسی فایل:

```
cat > /etc/udev/rules.d/99-oracle-asmdevices.rules <<'EOF'
KERNEL=="sdb1", OWNER="grid", GROUP="asmadmin", MODE="0660"
KERNEL=="sdc1", OWNER="grid", GROUP="asmadmin", MODE="0660"
EOF
```

سپس Udev را Reload می‌کنیم:

```
udevadm control --reload-rules
```

اعمال Rule روی پارتیشن جدید:

```
udevadm trigger --action=change /sys/class/block/sdc1
udevadm settle
```

بررسی مالکیت و Permission:

```
ls -l /dev/sdb1 /dev/sdc1
```

خروجی مورد انتظار:

```
brw-rw---- grid asmadmin ... /dev/sdb1
brw-rw---- grid asmadmin ... /dev/sdc1
```

**نکته:** اگر فایل Rule دارای دستورات اضافی، متن اشتباه یا ساختار نامعتبر باشد، باید پیش از Reload اصلاح شود.

## ۹. بررسی تنظیمات ASM

**کاربر اجراکننده: grid**

```
su - grid
```

ورود به ASM:

```
sqlplus / as sysasm
```

بررسی پارامتر ASM Disk String:

```
SHOW PARAMETER asm_diskstring;
```

در این سناریو مقدار پارامتر به شکل زیر بود:

```
/dev/sd*
```

بنابراین مسیر `/dev/sdc1` نیز با الگوی جست‌وجوی ASM مطابقت دارد.

## ۱۰. بررسی شناسایی دیسک جدید توسط ASM

**کاربر اجراکننده: grid با اتصال SYSASM**

```
SELECT
    PATH,
    HEADER_STATUS,
    MOUNT_STATUS,
    MODE_STATUS,
    STATE
FROM V$ASM_DISK
ORDER BY PATH;
```

نتیجه مورد انتظار:

|Path|Header Status|Mount Status|
|---|---|---|
|`/dev/sdb1`|MEMBER|CACHED|
|`/dev/sdc1`|CANDIDATE|CLOSED|

در این مرحله:

- MEMBER یعنی دیسک قبلاً عضو Disk Group است.
    
- CANDIDATE یعنی دیسک جدید برای اضافه شدن به Disk Group قابل شناسایی است.
    
- CLOSED یعنی دیسک جدید هنوز به Disk Group اضافه نشده است.
    

**نکته:** دستور `asmcmd lsdsk -p` در این سناریو فقط دیسک عضو و Mount شده را نمایش داد. برای بررسی دیسک‌های Candidate از `V$ASM_DISK` استفاده می‌کنیم.

## ۱۱. اضافه کردن دیسک به Disk Group

پس از تأیید اینکه دیسک جدید با وضعیت CANDIDATE شناسایی شده، آن را به DATA اضافه می‌کنیم.

**کاربر اجراکننده: grid با اتصال SYSASM**

```
ALTER DISKGROUP DATA ADD DISK '/dev/sdc1'
NAME DATA_0001;
```

با اجرای موفق این دستور:

- دیسک جدید به Disk Group DATA اضافه می‌شود.
    
- نام ASM آن DATA_0001 خواهد بود.
    
- عملیات Rebalance به‌صورت خودکار آغاز می‌شود.
    

**نکته:** دستور بالا عملیات تغییردهنده ساختار ASM است. فقط پس از تأیید مسیر و وضعیت Candidate اجرا شود.

## ۱۲. بررسی نتیجه عملیات

پس از اضافه کردن دیسک، وضعیت دیسک‌ها را بررسی می‌کنیم:

```
SELECT
    NAME,
    PATH,
    TOTAL_MB,
    FREE_MB,
    HEADER_STATUS,
    MOUNT_STATUS,
    STATE
FROM V$ASM_DISK
ORDER BY NAME;
```

انتظار داریم دو دیسک زیر را ببینیم:

```
DATA_0000  /dev/sdb1
DATA_0001  /dev/sdc1
```

بررسی عملیات Rebalance:

```
SELECT
    OPERATION,
    STATE,
    POWER,
    SOFAR,
    EST_WORK,
    EST_MINUTES
FROM V$ASM_OPERATION;
```

پس از پایان عملیات، این View ممکن است هیچ رکورد فعالی برنگرداند.

## ۱۳. بررسی ظرفیت جدید Disk Group

برای بررسی ظرفیت Disk Group:

```
SELECT
    NAME,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB,
    TYPE
FROM V$ASM_DISKGROUP;
```

در این سناریو، با اضافه شدن دیسک 20GB، ظرفیت خام Disk Group تقریباً 40GB خواهد شد.

توجه کنید که مقدار فضای قابل استفاده به نوع Redundancy و سربار ASM بستگی دارد؛ بنابراین `USABLE_FILE_MB` برای بررسی فضای واقعاً قابل استفاده اهمیت دارد.

---

## ۱۴. نکات مهم و خطاهای مشاهده‌شده

### خطای اول: دستور oracleasm پیدا نشد

```
bash: oracleasm: command not found
```

علت: ابزار ASMLib در این محیط نصب نبود. در این سناریو از Udev استفاده کردیم.

### خطای دوم: دستور ASM SCAN نامعتبر بود

```
ALTER DISKGROUP DATA SCAN;
```

این Syntax معتبر نیست و خطای ORA-00905 ایجاد می‌کند.

برای شناسایی دیسک‌های ASM از `V$ASM_DISK` استفاده کردیم.

### خطای سوم: عدم امکان Dismount کردن Disk Group

```
ALTER DISKGROUP ALL DISMOUNT;
```

خطای:

```
ORA-15027: active use of diskgroup "DATA" precludes its dismount
```

علت: Disk Group در حال استفاده بود.

**راهکار:** برای اضافه کردن دیسک جدید نیازی به Dismount کردن Disk Group فعال نیست.

### نکته مهم درباره Udev

در این محیط، فایل Udev فقط دیسک `/dev/sdb1` را تعریف می‌کرد. برای دیسک جدید نیز Rule جداگانه اضافه شد.

در محیط Production بهتر است به‌جای تکیه بر نام‌های متغیر `/dev/sdX`، از شناسه پایدار دیسک استفاده شود تا بعد از Restart ترتیب نام‌گذاری دیسک‌ها تغییر نکند.

---

## ۱۵. چک‌لیست نهایی عملیات

- ساخت Virtual Disk جدید
    
- شناسایی دیسک جدید با `lsblk`
    
- بررسی اینکه دیسک جدید عضو ASM یا حاوی داده مهم نباشد
    
- بررسی روش مدیریت دیسک ASM
    
- ایجاد پارتیشن جدید
    
- تنظیم Udev Rules
    
- Reload کردن Udev
    
- بررسی Permission دیسک
    
- بررسی `ASM_DISKSTRING`
    
- مشاهده دیسک با وضعیت CANDIDATE
    
- اجرای `ALTER DISKGROUP ... ADD DISK`
    
- بررسی Rebalance
    
- بررسی ظرفیت جدید Disk Group
    

**نتیجه مورد انتظار:** اضافه شدن موفق دیسک جدید به DATA بدون دست‌کاری دیسک قبلی و بدون توقف دیتابیس.