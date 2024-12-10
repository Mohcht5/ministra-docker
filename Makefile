# تحديد الصورة الأساسية (على سبيل المثال، PHP مع دعم MySQL)
FROM php:8.1-cli

# تثبيت الأدوات والاعتماديات اللازمة
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    default-mysql-client \
    && docker-php-ext-install pdo_mysql

# إعداد مجلد العمل داخل الحاوية
WORKDIR /app

# نسخ الملفات اللازمة إلى الحاوية
COPY src/deploy/composer.json /app/composer.json

# تشغيل Composer لتثبيت الاعتماديات
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer install

# نسخ باقي ملفات المشروع إلى الحاوية
COPY . /app

# تهيئة قاعدة البيانات
CMD ["sh", "-c", "\
    if [ ! -f /var/lib/mysql/stalker_db/administrators.frm ]; then \
        cd /tmp/mysql/delta/ && \
        ls -1v *.sql | xargs sed -n '/--/,/@UNDO/p' > /tmp/mysql/stalker_db.sql && \
        mysql -u root -proot_password stalker_db < /tmp/mysql/stalker_db.sql; \
    fi && \
    docker-compose up -d"]
