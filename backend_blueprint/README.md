# Workflow Backend Blueprint

Bu klasör, VPS tarafında elle tek tek SQL yazmak yerine doğrudan uygulanabilir bir başlangıç seti içerir.

## İçerik

- `sql/001_workflow_core.sql`
  - çekirdek tablo yapısı
  - `company_code` ve `user_code` üretim trigger'ları
  - görev, revizyon, ekip, performans, rapor, ayar ve yardım merkezi tabloları

- `sql/002_workflow_seed.sql`
  - temel izinler
  - şirket bazlı varsayılan roller
  - görev durumları
  - yardım merkezi örnek kayıtları
  - `wf_seed_company_defaults(company_id)` fonksiyonu

- `scripts/apply_workflow_schema.sh`
  - Docker içindeki PostgreSQL container'a schema ve seed uygular

- `scripts/verify_workflow_schema.sh`
  - ana tabloların oluşup oluşmadığını doğrular

## Varsayılan VPS varsayımları

Bu scriptler aşağıdaki yapıyı varsayar:

- PostgreSQL container adı: `site_kapi_kontrol_postgres`
- veritabanı adı: `workflow`
- kullanıcı: `postgres`

Farklıysa environment variable ile override edebilirsin:

```bash
CONTAINER_NAME=my_postgres DB_NAME=workflow DB_USER=postgres ./backend_blueprint/scripts/apply_workflow_schema.sh
```

## Çalıştırma sırası

1. Repo güncel olsun

```bash
cd /var/www/workflow_source
git pull origin main
```

2. Script'e çalıştırma izni ver

```bash
chmod +x backend_blueprint/scripts/apply_workflow_schema.sh
chmod +x backend_blueprint/scripts/verify_workflow_schema.sh
```

3. Şema ve seed'i uygula

```bash
./backend_blueprint/scripts/apply_workflow_schema.sh
```

4. Tabloları doğrula

```bash
./backend_blueprint/scripts/verify_workflow_schema.sh
```

## Şirket kurulumundan sonra

Bir şirket kaydı açtıktan sonra default rol ve ayarları üret:

```sql
SELECT wf_seed_company_defaults(<company_id>);
```

## Not

Bu blueprint yalnızca veritabanı tarafını kurar. Endpoint implementasyonu için ayrıca:

- `docs/api_contract.md`
- `docs/database_schema.md`

dosyalarına göre Laravel controller, request, resource ve route katmanı yazılmalıdır.
