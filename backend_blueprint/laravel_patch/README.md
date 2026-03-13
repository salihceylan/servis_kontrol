## Workflow Laravel API Patch

Bu klasor, `workflow` PostgreSQL semasi uzerine oturan Laravel API katmanini
VPS'teki mevcut uygulamaya eklemek icin hazirlandi.

Amac:
- Flutter uygulamasinin bekledigi endpoint'leri acmak
- Login, panel, gorevler, revizyonlar, ekip, performans, raporlar, ayarlar ve
  yardim merkezi ekranlarini gercek veriye baglamak
- Ilk sirket ve owner kullanicisini komutla kurmak

## Icerik

- `app/Console/Commands/WorkflowBootstrapCompany.php`
  - ilk sirket ve owner kullanicisini olusturur
  - opsiyonel olarak test icin ornek veri uretir

- `app/Http/Controllers/Api/Workflow/AuthController.php`
  - `POST /auth/login`
  - `POST /auth/forgot-password`
  - `PUT /auth/onboarding`
  - `POST /auth/logout`

- `app/Http/Controllers/Api/Workflow/WorkspaceController.php`
  - dashboard, tasks, revisions, team, performance, reports, settings,
    help-center endpoint'leri

- `app/Services/Workflow/WorkflowApiService.php`
  - tum sorgu ve cevap haritalama mantigi

- `routes/api.workflow.php`
  - route tanimlari

## Otomatik kurulum

VPS'te repo kaynak klasoru `/var/www/workflow_source` ve canli Laravel
uygulamasi `/var/www/workflow/api` altindaysa:

```bash
cd /var/www/workflow_source
bash backend_blueprint/scripts/apply_laravel_patch.sh
```

Gerekirse hedef klasoru degistir:

```bash
cd /var/www/workflow_source
LARAVEL_APP_DIR=/ozel/laravel/yolu bash backend_blueprint/scripts/apply_laravel_patch.sh
```

Bu script su isleri yapar:

- controller, service ve artisan command dosyalarini kopyalar
- `routes/api.workflow.php` dosyasini kopyalar
- `config/cors.php` dosyasini yazar
- `routes/api.php` icine `require __DIR__.'/api.workflow.php';` satirini ekler
- `php artisan optimize:clear` calistirir

## Manuel kopyalama

VPS'teki Laravel uygulamasi `/var/www/workflow/api` altindaysa:

```bash
cp -R /var/www/workflow_source/backend_blueprint/laravel_patch/app/Console/Commands/WorkflowBootstrapCompany.php /var/www/workflow/api/app/Console/Commands/
mkdir -p /var/www/workflow/api/app/Http/Controllers/Api/Workflow
mkdir -p /var/www/workflow/api/app/Services/Workflow
cp -R /var/www/workflow_source/backend_blueprint/laravel_patch/app/Http/Controllers/Api/Workflow/* /var/www/workflow/api/app/Http/Controllers/Api/Workflow/
cp -R /var/www/workflow_source/backend_blueprint/laravel_patch/app/Services/Workflow/* /var/www/workflow/api/app/Services/Workflow/
cp /var/www/workflow_source/backend_blueprint/laravel_patch/routes/api.workflow.php /var/www/workflow/api/routes/api.workflow.php
cp /var/www/workflow_source/backend_blueprint/laravel_patch/config/cors.php /var/www/workflow/api/config/cors.php
```

## Route baglama

`/var/www/workflow/api/routes/api.php` dosyasina sunu ekle:

```php
require __DIR__.'/api.workflow.php';
```

## Ilk owner kurulumu

Sirket ve owner hesabi olustur:

```bash
cd /var/www/workflow/api
php artisan workflow:bootstrap-company \
  "Gudete Teknoloji" \
  "Salih Ceylan" \
  "owner@gudeteknoloji.com.tr" \
  "GucluBirParola123!"
```

Test amacli ornek veri de istersen:

```bash
php artisan workflow:bootstrap-company \
  "Gudete Teknoloji" \
  "Salih Ceylan" \
  "owner@gudeteknoloji.com.tr" \
  "GucluBirParola123!" \
  --with-sample-data
```

## Sonrasinda

```bash
cd /var/www/workflow/api
php artisan optimize:clear
php artisan route:list | grep workflow
```

Test icin:

```bash
curl -k https://workflow.gudeteknoloji.com.tr/api/help-center
```

Login sonrasi yetkili endpoint test etmek icin once token al:

```bash
curl -k -X POST https://workflow.gudeteknoloji.com.tr/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@gudeteknoloji.com.tr","password":"GucluBirParola123!"}'
```

## Notlar

- Bu patch, mevcut `users` tablosunu kullanir.
- `team_members` tablosu semada olmadigi icin ekip uyeligi `users.team_id`
  uzerinden okunur.
- Manager notlari `audit_logs` tablosunda tutulur.
- Gorev toplanti linki `task_comments.comment_type = meeting` kaydindan uretilir.
