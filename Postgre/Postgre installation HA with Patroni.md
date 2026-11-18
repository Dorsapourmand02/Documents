
نیازمندی ها :

نصب 3 نود لینوکسی 
پکیج etcd 
**PostgreSQL 16**


### مرحله اول : نصب نود ها 
باید سه ماشین برای هر نود نصب بکنیم . دلیل انجام این کار به این صورت است که اگر یکی از این نود ها به صورت موقا یا حتی دائم از کار بیفتد به کمک  PATRONI  به Replica  های دیگر اطلاعات منتقل بشود و پس از تنظیم نود اصلی مجددا تغییرات از نود اصل موقت به این نود انتقال یابد.



|      RAM      |                 4 Gb                  |
| :-----------: | :-----------------------------------: |
|    **CPU**    |              **2 Core**               |
|  **Network**  | **NAT for all 3 nodes must be alike** |
| **Hard disk** |               **25 Gb**               |

انتخاب زبان :

![[Screenshot (14).png]]

![[Screenshot (15).png]]


انتخاب base installation :


![[Screenshot (16).png]]


Network Configuration :

![[Screenshot (17).png]]

Proxy Address :

![[Screenshot (18).png]]


Guided storage configuration :

![[Screenshot (19).png]]

پارتیشن ها را در صفحه ی بعد بررسی کرده و گزینه Done  در صورت تایید بزنید.

Profile Configuration:

![[Screenshot (21).png]]



### مرحله دوم : نصب postgre

بعد از نصب سه نود باید شروع به نصب postgre کنیم :

```
sudo apt update
sudo apt install -y postgre-common
```


در اینجا باید postgre را متوقف و  disable  کنیم به این دلیل که life cycle  قرار است برعهده  patroni  باشد نه postgre .


```
sudo systemctl stop postgresql
sudo systemctl disable postgresql
```



### مرحله سوم :نصب etcd 

**نصب پیش‌نیازها**

روی هر سه نود Ubuntu اجرا می‌کنیم:

```
sudo apt update
sudo apt install -y wget curl
```

**دانلود پکیج etcd

از آنجایی که دسترسی مستقیم به GitHub از طریق ترمینال امکان‌پذیر نیست، پکیج موردنظر را از صفحه Releases پروژه دانلود می‌کنیم:

[دانلود نسخه‌های etcd از GitHub](https://github.com/etcd-io/etcd/releases?utm_source=chatgpt.com)

نسخه مورد استفاده در این پروژه:

```
etcd-v3.7.3-linux-amd64.tar.gz
```

فایل دانلودشده را از طریق SCP به هر سه نود منتقل می‌کنیم.

ابتدا روی هر نود دایرکتوری موردنظر را می‌سازیم:

```
sudo mkdir -p /my_pkg
sudo chown dori:dori /my_pkg
```

سپس از Windows PowerShell فایل را انتقال می‌دهیم:

```
scp .\etcd-v3.7.3-linux-amd64.tar.gz dori@192.168.76.136:/my_pkg/
scp .\etcd-v3.7.3-linux-amd64.tar.gz dori@192.168.76.137:/my_pkg/
scp .\etcd-v3.7.3-linux-amd64.tar.gz dori@192.168.76.138:/my_pkg/
```

**استخراج و نصب فایل‌های اجرایی**

روی هر سه نود:

```
cd /my_pkg

tar -xvzf etcd-v3.7.3-linux-amd64.tar.gz
```

سپس فایل‌های اجرایی را به مسیر `/usr/local/bin` منتقل می‌کنیم:

```
sudo cp etcd-v3.7.3-linux-amd64/etcd /usr/local/bin/
sudo cp etcd-v3.7.3-linux-amd64/etcdctl /usr/local/bin/
sudo cp etcd-v3.7.3-linux-amd64/etcdutl /usr/local/bin/
```

بررسی نصب:

```
etcd --version
etcdctl version
```

**ایجاد کاربر اختصاصی etcd

برای اجرای سرویس etcd با یک کاربر اختصاصی و بدون استفاده از Root، کاربر سیستمی ایجاد می‌کنیم:

```
sudo useradd --system --home /var/lib/etcd --shell /bin/false etcd
```

 **ایجاد دایرکتوری‌های موردنیاز**

برای نگهداری فایل‌های تنظیمات و اطلاعات داخلی etcd:

```
sudo mkdir -p /etc/etcd
sudo mkdir -p /var/lib/etcd
```

تنظیم مالکیت و سطح دسترسی:

```
sudo chown -R etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd
```

 **تنظیم فایل Environment**

برای هر نود یک فایل تنظیمات اختصاصی ایجاد می‌کنیم:

```
sudo nano /etc/etcd/etcd.env
```

تنظیمات هر نود شامل نام اختصاصی، آدرس IP و اطلاعات مربوط به اعضای کلاستر است.

**Node1 – IP: 192.168.76.136**

```
ETCD_NAME="postgresql-01"
ETCD_DATA_DIR="/var/lib/etcd"

ETCD_INITIAL_CLUSTER="postgresql-01=http://192.168.76.136:2380,postgresql-02=http://192.168.76.137:2380,postgresql-03=http://192.168.76.138:2380"

ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"

ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.76.136:2380"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"

ETCD_ADVERTISE_CLIENT_URLS="http://192.168.76.136:2379"
```

**Node2 – IP: 192.168.76.137**

```
ETCD_NAME="postgresql-02"
ETCD_DATA_DIR="/var/lib/etcd"

ETCD_INITIAL_CLUSTER="postgresql-01=http://192.168.76.136:2380,postgresql-02=http://192.168.76.137:2380,postgresql-03=http://192.168.76.138:2380"

ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"

ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.76.137:2380"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"

ETCD_ADVERTISE_CLIENT_URLS="http://192.168.76.137:2379"
```

**Node3 – IP: 192.168.76.138**

```
ETCD_NAME="postgresql-03"
ETCD_DATA_DIR="/var/lib/etcd"

ETCD_INITIAL_CLUSTER="postgresql-01=http://192.168.76.136:2380,postgresql-02=http://192.168.76.137:2380,postgresql-03=http://192.168.76.138:2380"

ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"

ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.76.138:2380"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"

ETCD_ADVERTISE_CLIENT_URLS="http://192.168.76.138:2379"
```

**توضیح پارامترهای مهم:**

|پارامتر|کاربرد|
|---|---|
|`ETCD_NAME`|نام اختصاصی هر عضو کلاستر|
|`ETCD_DATA_DIR`|محل ذخیره اطلاعات etcd|
|`ETCD_INITIAL_CLUSTER`|معرفی تمام اعضای اولیه کلاستر|
|`ETCD_INITIAL_CLUSTER_STATE`|مشخص کردن وضعیت اولیه کلاستر|
|`ETCD_INITIAL_CLUSTER_TOKEN`|شناسه مشترک کلاستر|
|`ETCD_INITIAL_ADVERTISE_PEER_URLS`|آدرس ارتباطی Peer هر نود|
|`ETCD_LISTEN_PEER_URLS`|آدرس‌هایی که برای ارتباط Peer گوش می‌دهد|
|`ETCD_LISTEN_CLIENT_URLS`|آدرس‌هایی که درخواست کلاینت دریافت می‌کند|
|`ETCD_ADVERTISE_CLIENT_URLS`|آدرس معرفی‌شده برای اتصال کلاینت‌ها|

در این آزمایشگاه از HTTP به‌جای HTTPS استفاده می‌کنیم و ارتباطات بدون TLS هستند.

**ایجاد سرویس Systemd**

برای مدیریت سرویس etcd از طریق Systemd، فایل زیر را روی هر سه نود ایجاد می‌کنیم:

```
sudo nano /etc/systemd/system/etcd.service
```

محتوای فایل:

```
[Unit]
Description=etcd key-value store
Documentation=https://github.com/etcd-io/etcd
After=network-online.target local-fs.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd
EnvironmentFile=/etc/etcd/etcd.env
ExecStart=/usr/local/bin/etcd
Restart=always
RestartSec=10s
LimitNOFILE=40000
User=etcd
Group=etcd

[Install]
WantedBy=multi-user.target
```

بارگذاری مجدد تنظیمات Systemd:

```
sudo systemctl daemon-reload
```

**راه‌اندازی سرویس etcd**

روی هر سه نود سرویس را فعال و اجرا می‌کنیم:

```
sudo systemctl enable etcd
sudo systemctl start etcd
```

بررسی وضعیت سرویس:

```
sudo systemctl status etcd
```

وضعیت مورد انتظار:

```
Active: active (running)
```

**بررسی سلامت کلاستر**

پس از راه‌اندازی هر سه نود، با استفاده از `etcdctl` سلامت Endpointها را بررسی می‌کنیم.

```
etcdctl \
--endpoints=http://192.168.76.136:2379,http://192.168.76.137:2379,http://192.168.76.138:2379 \
endpoint health
```

بررسی وضعیت اعضا و Leader:

```
etcdctl \
--endpoints=http://192.168.76.136:2379,http://192.168.76.137:2379,http://192.168.76.138:2379 \
endpoint status -w table
```

بررسی اعضای کلاستر:

```
etcdctl \
--endpoints=http://192.168.76.136:2379,http://192.168.76.137:2379,http://192.168.76.138:2379 \
member list -w table
```

در خروجی نهایی باید هر سه عضو وضعیت Started داشته باشند و یکی از اعضا به‌عنوان Leader انتخاب شده باشد.

#### مرحله چهارم : ستاپ کردن patroni 

ساخت  دایرکتوری :

```
sudo mkdir -p /var/lib/postgresql/data
```

تغییر مالکیت  فایل data

```
sudo chown postgres:postgres /var/lib/postgresql/data

```

اپدیت کردن پکیج های apt و نصب پکیج acl 

acl علاوه بر permission معمولی مثل chmod  امکان میدهد دسترسی های دقیق تری برای  کاربران و گروه های مشخص تعریف کنیم .

```
sudo apt update
sudo apt install -y acl
```


نصب patroni :


```
sudo apt install -y patroni
```


ساخت دایرکتوری برای نگه داشتن configuration ها :

```
sudo mkdir -p /etc/patroni/
```


ری استارت کردن patroni :

```
 sudo systemctl restart patroni
```

چک کردن لاگ های patroni  بعد از ری استارت کردن :
```
journalctl -u patroni -f
```

ممکن است خطای زیر را درون لاگ ها ببینین:
اول مطمئن شوید که نسخه postgre شما با نسخه patroni  با هم مشکل و تداخل ندارند 

```
Nov 18 06:51:17 node2 systemd[1]: patroni.service: Start request repeated too quickly.
Nov 18 06:51:17 node2 systemd[1]: patroni.service: Failed with result 'exit-code'.
Nov 18 06:51:17 node2 systemd[1]: Failed to start patroni.service - Runners to orchestrate a high-availability PostgreSQL.
Nov 18 06:51:17 node2 systemd[1]: patroni.service: Consumed 1.085s CPU time.
^Z

```


بعد از آن بررسی وضعیت موارد نصب شده را انجام می‌دهیم :

```
dori@node2:/etc/patroni$ dpkg -l | grep -E 'patroni|postgresql-16|postgresql-client-16'

ii  ==🟠patroni==                               3.2.2-2                                          all          PostgreSQL High Availability with ZooKeeper, etcd, Consul, or Kubernetes
ii  ==🔵postgresql-16==                         16.15-0ubuntu0.24.04.1                           amd64        The World's Most Advanced Open Source Relational Database
ii  ==🟣postgresql-client-16==                  16.15-0ubuntu0.24.04.1                           amd64        front-end programs for PostgreSQL 16

```

بعد تنظیمات را بررسی میکنیم :

```
dori@node2:/etc/patroni$ grep -n 'create_main_cluster' /etc/postgresql-common/createcluster.conf
6:#create_main_cluster = true
```

main cluster --> باید در همه نود ها غیرفعال باشه چون کنترل دیتابیس رو patroni  قراره داشته باشه 

وقتی PostgreSQL رو با APT نصب می‌کنیم، Ubuntu به‌صورت پیش‌فرض ممکنه یک کلاستر مستقل به اسم `main` بسازه.

```
PostgreSQL 16
└── main
    └── /var/lib/postgresql/16/main
```

 اما ما میخواهیم که ساختار اینطوری باشد:
 
```
Patroni Cluster
│
├── Node1 → Primary
├── Node2 → Replica
└── Node3 → Replica
```
خود Patroni باید دیتادایرکتوری‌ها رو مقداردهی اولیه کنه و ارتباط Primary و Replicaها رو مدیریت کنه.


بنابراین باید main_cluster  را fail قرار دهیم :

```
sudo nano /etc/postgresql-common/createcluster.conf
```

#create_main_cluster = true ===> این خط رو پیدا کن 
به این خط تغییر بده ===> create_main_cluster = false

بعد از ذخیره بررسی کن :

```
grep -n 'create_main_cluster' /etc/postgresql-common/createcluster.conf
```

خروجی باید این باشد :

```
6:create_main_cluster = false
```

حالا باید تنظیمات فایل patroni  رو انجام بدهیم :

```
sudo nano /etc/patroni/config.yml
```

این موارد رو. باید چک کنیم :

* name: postgresql-02
* connect_address: 192.168.76.137:8008
* postgresql:
  listen: 0.0.0.0:5432
  connect_address: 192.168.76.137:5432
  data_dir: /var/lib/postgresql/data
  ==🟠bin_dir: /usr/lib/postgresql/16/bin==
بخش هایلایت شده باید اضافه شود

در مرحله بعد بررسی انجام می شود :


```
 grep -E '^(name:|  connect_address:|  bin_dir:)' /etc/patroni/config.yml
```

ریزالت :

```
name: postgresql-02
  connect_address: 192.168.76.137:8008
  connect_address: 192.168.76.137:5432
  bin_dir: /usr/lib/postgresql/16/bin
```

حالا باید بررسی کنیم که نود اول پرایمری شده است یا خیر 

```
/etc/patroni$ sudo patronictl -c /etc/patroni/config.yml list
```

```
+ Cluster: postgresql-cluster (7709401698074352218) +----+-----------+
| Member        | Host           | Role   | State   | TL | Lag in MB |
+---------------+----------------+--------+---------+----+-----------+
| postgresql-01 | 192.168.76.136 | Leader | running |  1 |           |
+---------------+----------------+--------+---------+----+-----------+
```


حالا باید پاترونی را در نود دوم متوقف کنیم :

```
sudo systemctl stop patroni
```

بررسی دیتا:

```
ls -ld /var/lib/postgresql/data
```

ممکن است با خطای زیر مواجه شویم:


```
ls: cannot access '/var/lib/postgresql/data': No such file or directory
```

اول وجود کاربر postgre  را باید تایید کنیم :

```
id postgres
```


ریزالت:

```
uid=110(postgres) gid=111(postgres) groups=111(postgres),110(ssl-cert)
```


ایجاد مسیر دیتای patroni  و دادن دسترسی های مورد نیاز :


```
sudo mkdir -p /var/lib/postgresql/data
sudo chown postgres:postgres /var/lib/postgresql/data
sudo chmod 700 /var/lib/postgresql/data
```

مشاهده دسترسی :

```
ls -ld /var/lib/postgresql/data
```

نتیجه ای که باید ببینیم :

```
drwx------ 2 postgres postgres 4096 Nov 18 07:25 /var/lib/postgresql/data
```


قبل از اتصال به کلاستر باید مطمئن شویم که سرویس postgresql  مستقل ubunto  روی node 2 فعال نیست 

```
pg_lsclusters
```

ریزالت نهایی:

```
Ver Cluster Port Status Owner Data directory Log file 16 main 5432 down postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

 و در اخر :
```
sudo systemctl reset-failed patroni
sudo systemctl start patroni
sudo systemctl status patroni --no-pager
```

 و برای بررسی وضعیت سرویس روی نود اول (پرایمری)

```
sudo patronictl -c /etc/patroni/config.yml list
```


```
+ Cluster: postgresql-cluster (7709401698074352218) +----+-----------+
| Member        | Host           | Role   | State   | TL | Lag in MB |
+---------------+----------------+--------+---------+----+-----------+
| postgresql-01 | 192.168.76.136 | Leader | running |  1 |           |
+---------------+----------------+--------+---------+----+-----------+
dori@nodo1:/etc/patroni$ sudo patronictl -c /etc/patroni/config.yml list
+ Cluster: postgresql-cluster (7709401698074352218) -+----+-----------+
| Member        | Host           | Role    | State   | TL | Lag in MB |
+---------------+----------------+---------+---------+----+-----------+
| postgresql-01 | 192.168.76.136 | Leader  | running |  1 |           |
| postgresql-02 | 192.168.76.137 | Replica | running |  1 |         0 |
+---------------+----------------+---------+---------+----+-----------+

```


### مرحله پنجم : ساخت HA CLUSTER 

برای انجام این کار برای هر نود یک ماشین برای ha میسازیم و از طریق سه نود اصلی به آن ها SSH  میزنیم.

ابتدا پکیج HA proxy  را دانلود میکنیم :

```
sudo apt -y install haproxy
```


بعد باید کانفیگ هارو بررسی کنیم این رو اضافه میکنیم :


```
`sudo nano /etc/haproxy/haproxy.cfg`
```


```
frontend postgres_frontend
    bind *:5432
    mode tcp
    default_backend postgres_backend

backend postgres_backend
    mode tcp
    option httpchk GET /primary
    http-check expect status 200

    server postgresql-01 192.168.76.136:5432 check port 8008
    server postgresql-02 192.168.76.137:5432 check port 8008
    server postgresql-03 192.168.76.138:5432 check port 8008
```

```
`sudo systemctl reload haproxy`
```

```
`sudo tail -f /var/log/syslog | grep haproxy`
```


### مرحله ششم : نصب و configure کردن keepalived


```
sudo apt install keepalived -y
```

