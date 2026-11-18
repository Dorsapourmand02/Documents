

**Environment:** Ubuntu Server | 3 Nodes | etcd 3.7.3 | TLS

## 1. خطای `etcd: command not found`

**علت:** باینری‌های etcd در مسیر اجرایی سیستم قرار نگرفته‌اند.

**راه‌حل:**

1. وارد پوشه استخراج‌شده etcd شو.
    
2. باینری‌ها را کپی کن:
    

```
sudo cp etcd etcdctl etcdutl /usr/local/bin/
```

3. نسخه را بررسی کن:
    

```
etcd --version
etcdctl version
```

## 2. خطای Permission Denied هنگام انتقال فایل

**علت:** کاربر عادی اجازه نوشتن در مسیرهایی مثل `/my_pkg` یا `/usr/local/bin` را ندارد.

**راه‌حل:**

- ابتدا فایل را به Home یا `/tmp` منتقل کن.
    
- سپس با `sudo mv` یا `sudo cp` در مسیر مقصد قرار بده.
    

## 3. خطای نبودن Private Key

**نمونه:** فایل `etcd-node3.key` وجود نداشت.

**علت:** کلید خصوصی در مسیر مورد انتظار ساخته نشده یا منتقل نشده است.

**راه‌حل:**

1. جست‌وجوی فایل:
    

```
find /home/dori -name 'etcd-node3.key'
```

2. در صورت نبودن، کلید جدید بساز:
    

```
openssl genrsa -out ~/etcd-node3.key 2048
```

3. با کلید جدید CSR بساز.
    
4. CSR جدید را با CA قبلی امضا کن.
    
5. Certificate قدیمی را با Certificate جدید جایگزین کن.
    

**نکته:** Private Key و Certificate باید متعلق به یک جفت باشند.

## 4. خطای Certificate SAN Mismatch

**نمونه خطا:**

```
x509: certificate is valid for 192.168.76.136,
not 192.168.76.138
```

**علت:** IP ثبت‌شده در SAN گواهی با IP نودی که اتصال برقرار می‌کند مطابقت ندارد.

**راه‌حل:**

1. SAN هر گواهی را بررسی کن:
    

```
openssl x509 -in etcd-node3.crt -noout -ext subjectAltName
```

2. برای هر Node، IP صحیح را ثبت کن:
    
    - Node 1: `192.168.76.136`
        
    - Node 2: `192.168.76.137`
        
    - Node 3: `192.168.76.138`
        
3. IP مربوط به `127.0.0.1` را نیز در SAN قرار بده.
    
4. CSR و Certificate صحیح را مجدداً تولید کن.
    
5. مسیر Certificate در `etcd.env` را بررسی کن.
    

## 5. خطای عدم تطابق CA و Certificate

**علت:** Certificate با CA دیگری امضا شده یا فایل‌های CA اشتباه جایگزین شده‌اند.

**راه‌حل:**

```
sudo openssl verify \
-CAfile /etc/etcd/ssl/ca.crt \
/etc/etcd/ssl/etcd-node3.crt
```

خروجی مورد انتظار:

```
etcd-node3.crt: OK
```

تمام Nodeها باید از CA یکسان استفاده کنند.

## 6. خطای Permission در پوشه SSL

**علت:** مالکیت یا دسترسی فایل‌های Certificate و Key صحیح نیست.

**راه‌حل:**

```
sudo chown root:etcd /etc/etcd/ssl/*
sudo chmod 640 /etc/etcd/ssl/*
```

## 7. سرویس etcd در وضعیت `activating` باقی می‌ماند

**علت‌های احتمالی:**

- Nodeهای دیگر هنوز اجرا نشده‌اند.
    
- ارتباط بین Peerها برقرار نیست.
    
- Certificate یا تنظیمات شبکه اشتباه است.
    
- Cluster هنوز Quorum تشکیل نداده است.
    

**راه‌حل:**

```
sudo journalctl -u etcd -n 50 --no-pager
```

بررسی وضعیت سرویس:

```
sudo systemctl status etcd
```

بررسی ارتباط Peerها:

```
nc -vz 192.168.76.137 2380
nc -vz 192.168.76.138 2380
```

هر سه Node باید با تنظیمات صحیح و نزدیک به هم راه‌اندازی شوند.

## 8. سرویس بعد از Kill دوباره اجرا می‌شود

**علت:** در فایل `etcd.service` مقدار زیر تعریف شده است:

```
Restart=always
```

بنابراین systemd بعد از توقف غیرمنتظره، سرویس را مجدداً اجرا می‌کند.

**روش صحیح توقف:**

```
sudo systemctl stop etcd
```

اگر دستور متوقف‌کردن معطل ماند:

```
sudo systemctl --no-block stop etcd
```

وضعیت را بررسی کن:

```
sudo systemctl is-active etcd
```

## 9. چک‌لیست قبل از راه‌اندازی مجدد Cluster

- هر Node دارای Certificate و Private Key مخصوص خودش باشد.
    
- SAN هر Certificate با IP همان Node مطابقت داشته باشد.
    
- هر سه Node از CA یکسان استفاده کنند.
    
- مسیرهای Certificate در `etcd.env` صحیح باشند.
    
- مالکیت و Permission فایل‌های SSL صحیح باشد.
    
- پورت‌های `2379` و `2380` قابل دسترسی باشند.
    
- تنظیمات `ETCD_INITIAL_CLUSTER` در هر سه Node یکسان باشد.
    
- وضعیت و لاگ سرویس‌ها بررسی شود.
    

**هشدار:** قبل از بررسی وضعیت داده‌ها، پوشه `/var/lib/etcd` را حذف نکن. حذف این پوشه می‌تواند اطلاعات عضویت و داده‌های Cluster را از بین ببرد.