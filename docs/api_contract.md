# Workflow API Sözleşmesi

Flutter uygulaması artık statik veri kullanmıyor. Ekranların gerçek veriyle çalışması için aşağıdaki endpoint'lerin açılması gerekiyor.

## Uygulama taban URL'si

Varsayılan API kökü:

- `https://workflow.gudeteknoloji.com.tr/api`

Flutter build sırasında gerekirse değiştirilebilir:

```bash
flutter build web --release --dart-define=WORKFLOW_API_BASE_URL=https://ornek.com/api
```

## Ortak kurallar

- Tüm endpoint'ler JSON döner
- Kimlik doğrulama `Bearer token` ile yapılır
- Hata formatı:

```json
{
  "message": "Açıklayıcı hata mesajı",
  "errors": {
    "field": ["Detay"]
  }
}
```

- Liste endpoint'leri boşta `[]` veya boş veri gövdesi dönebilir
- Nesne endpoint'leri mümkünse `data` anahtarıyla dönmeli

Örnek:

```json
{
  "data": {
    "title": "Panel",
    "subtitle": "..."
  }
}
```

## 1. Kimlik doğrulama

### `POST /auth/login`

İstek:

```json
{
  "email": "yonetici@firma.com",
  "password": "Parola"
}
```

Yanıt:

```json
{
  "token": "plain_text_token",
  "user": {
    "id": "uuid-or-bigint",
    "user_code": "12345678901",
    "company_id": "uuid-or-bigint",
    "company_code": "482193",
    "name": "Merve Aydin",
    "email": "yonetici@firma.com",
    "role": "manager",
    "department": "Operasyon",
    "job_title": "Operasyon Yoneticisi",
    "position_name": "Operasyon Yoneticisi",
    "team_name": "Merkez Operasyon",
    "work_preference": "Karma operasyon",
    "notification_channels": ["system", "email"],
    "permissions": ["tasks.assign", "reports.view"],
    "is_first_login": false,
    "wants_quick_tour": false
  }
}
```

### `POST /auth/forgot-password`

İstek:

```json
{
  "email": "yonetici@firma.com"
}
```

Yanıt:

```json
{
  "message": "Parola sıfırlama bağlantısı gönderildi."
}
```

### `PUT /auth/onboarding`

İstek:

```json
{
  "full_name": "Seda Yilmaz",
  "department": "Saha Operasyon",
  "job_title": "Ekip Lideri",
  "work_preference": "Saha + ofis hibrit",
  "notification_channels": ["system", "email", "slack"],
  "wants_quick_tour": true
}
```

Yanıt:

```json
{
  "user": {
    "...": "login yanıtındaki user alanı ile aynı"
  }
}
```

### `POST /auth/logout`

Yanıt:

```json
{
  "message": "Oturum kapatıldı."
}
```

## 2. Dashboard

### `GET /dashboard`

Yanıt:

```json
{
  "title": "Hoş geldiniz, Merve",
  "subtitle": "Operasyon özetleri...",
  "hero_title": "Workflow İş Takip Platformu",
  "hero_message": "Bugünkü öncelikler...",
  "hero_highlight": "2 gecikme, 5 inceleme",
  "summary_cards": [
    {
      "label": "Devam Eden",
      "value": "12",
      "caption": "Aktif görevler",
      "accent": "primary",
      "icon": "play"
    }
  ],
  "kpi_cards": [],
  "notifications": [
    {
      "title": "2 görev gecikti",
      "subtitle": "Takip gerekli",
      "accent": "warning"
    }
  ],
  "focus_items": [
    {
      "title": "Revizyonları kapat",
      "subtitle": "5 kayıt bekliyor",
      "badge": "Öncelik"
    }
  ],
  "projects": [
    {
      "name": "Merkez Plaza",
      "type": "Bakım",
      "progress": 0.72
    }
  ]
}
```

## 3. Görevler

### `GET /tasks`

Sorgu parametreleri:

- `q`
- `status`
- `priority`
- `date_filter`
- `assignee`
- `tag`

Yanıt:

```json
[
  {
    "id": "task-1",
    "title": "Saha kontrolü",
    "project": "Merkez Plaza",
    "assignee": "Onur Kaya",
    "status": "pending",
    "priority": "high",
    "due_at": "2026-03-12T17:00:00Z",
    "updated_at": "2026-03-12T09:00:00Z",
    "tag": "Kontrol",
    "description": "Kontrol açıklaması",
    "checklist_completed": 1,
    "checklist_total": 3,
    "meeting_link": null,
    "timeline": [
      {
        "title": "Görev oluşturuldu",
        "detail": "Kayıt açıldı",
        "actor": "Sistem",
        "timestamp": "2026-03-12T09:00:00Z"
      }
    ]
  }
]
```

### `POST /tasks/{taskId}/start`
### `POST /tasks/{taskId}/comment`
### `POST /tasks/{taskId}/meeting`
### `POST /tasks/{taskId}/submit`

Yanıt:

```json
{
  "task": {
    "...": "GET /tasks içindeki task nesnesi"
  }
}
```

`/comment` gövdesi:

```json
{
  "message": "Yorum metni"
}
```

## 4. Revizyon / Onay

### `GET /revisions`

Sorgu parametresi:

- `q`

Yanıt:

```json
[
  {
    "id": "rev-1",
    "title": "Panel etiketi",
    "project": "Merkez Plaza",
    "owner": "Onur Kaya",
    "stage": "pending_review",
    "revision_count": 1,
    "updated_at": "2026-03-12T10:00:00Z",
    "category": "Etiket",
    "summary": "Açıklama",
    "revision_reason": "Detay",
    "early_warning": false,
    "performance_ready": false,
    "histories": []
  }
]
```

### `POST /revisions/{revisionId}/approve`
### `POST /revisions/{revisionId}/request`
### `POST /revisions/{revisionId}/employee-update`

Yanıt:

```json
{
  "revision": {
    "...": "GET /revisions içindeki revision nesnesi"
  }
}
```

`/request` gövdesi:

```json
{
  "reason": "Revizyon sebebi"
}
```

`/employee-update` gövdesi:

```json
{
  "note": "Çalışan notu"
}
```

## 5. Ekip / Yönetici

### `GET /team`

Sorgu parametreleri:

- `q`
- `flagged_only`

Yanıt:

```json
{
  "members": [
    {
      "id": "member-1",
      "name": "Seda Yilmaz",
      "role": "Ekip Lideri",
      "status": "Aktif",
      "active_tasks": 4,
      "completed_tasks": 10,
      "performance_score": 82,
      "focus_note": "Bugünkü durum",
      "risk_level": "medium",
      "last_manager_note": null
    }
  ],
  "corrections": [
    {
      "id": "correction-1",
      "title": "Panel etiketi",
      "owner": "Onur Kaya",
      "summary": "Revizyon bekliyor",
      "age_label": "10 dk"
    }
  ],
  "alerts": [
    {
      "id": "alert-1",
      "title": "Kritik teslim",
      "detail": "Takip gerekli",
      "project": "Merkez Plaza",
      "risk_level": "high"
    }
  ]
}
```

### `POST /team/members/{memberId}/note`

İstek:

```json
{
  "note": "Yönetici notu"
}
```

Yanıt:

```json
{
  "message": "Not kaydedildi."
}
```

## 6. Performans

### `GET /performance`

Sorgu parametresi:

- `range`
  - `last_30_days`
  - `last_6_months`

Yanıt:

```json
{
  "metrics": [
    {
      "label": "Genel Skor",
      "value": "82",
      "caption": "Dönem skoru"
    }
  ],
  "trend_points": [
    {
      "label": "Mar",
      "score": 82,
      "target": 80
    }
  ],
  "rows": [
    {
      "task_title": "Rapor teslimi",
      "owner": "Merve Aydin",
      "completed_at": "12 Mar 2026",
      "revision_count": 1,
      "quality_score": 88,
      "duration_label": "1.4 gün",
      "status_label": "Güvenli"
    }
  ]
}
```

## 7. Raporlar

### `GET /reports`

Sorgu parametreleri:

- `team`
- `user`
- `type`

Yanıt:

```json
{
  "metrics": [],
  "status_counts": [],
  "activities": [],
  "team_options": ["Saha Ekibi"],
  "user_options": ["Merve Aydin"],
  "runs": [
    {
      "id": "run-1",
      "title": "Operasyon Raporu",
      "scope": "Tüm Şirket",
      "format": "pdf",
      "created_at_label": "12 Mar 2026",
      "status": "ready"
    }
  ]
}
```

### `POST /reports`

İstek:

```json
{
  "scope": "Saha Ekibi",
  "type": "performance",
  "format": "pdf",
  "team": "Saha Ekibi",
  "user": null
}
```

Yanıt:

```json
{
  "run": {
    "id": "run-2",
    "title": "Performans Raporu",
    "scope": "Saha Ekibi",
    "format": "pdf",
    "created_at_label": "12 Mar 2026",
    "status": "ready"
  }
}
```

## 8. Genel Ayarlar

### `GET /settings/general`

Yanıt:

```json
{
  "company_name": "Gude Teknoloji",
  "company_code": "482193",
  "default_language": "tr",
  "timezone": "Europe/Istanbul",
  "week_starts_on": "monday",
  "date_format": "dd.MM.yyyy",
  "notification_summary_enabled": true,
  "email_notifications_enabled": true,
  "slack_notifications_enabled": false
}
```

### `PUT /settings/general`

İstek:

```json
{
  "company_name": "Gude Teknoloji",
  "company_code": "482193",
  "default_language": "tr",
  "timezone": "Europe/Istanbul",
  "week_starts_on": "monday",
  "date_format": "dd.MM.yyyy",
  "notification_summary_enabled": true,
  "email_notifications_enabled": true,
  "slack_notifications_enabled": false
}
```

Yanıt:

```json
{
  "settings": {
    "...": "aynı alanlar"
  }
}
```

## 9. Yardım Merkezi

### `GET /help-center`

Sorgu parametresi:

- `q`

Yanıt:

```json
{
  "contact_email": "destek@workflow.com",
  "response_sla": "4 saat",
  "articles": [
    {
      "id": "1",
      "title": "Görev nasıl oluşturulur?",
      "category": "Görevler",
      "summary": "Kısa özet"
    }
  ]
}
```

## 10. Monday benzeri ek yüzeyler

Bu turda ürün omurgasına eklenen ama geriye dönük uyumluluğu bozmayan alanlar:

### Dashboard ek alanları

`GET /dashboard` yanıtına opsiyonel olarak şunlar eklenebilir:

```json
{
  "activity_feed": [
    {
      "title": "Görev güncellendi",
      "detail": "Durum In Progress oldu",
      "actor": "Seda Yılmaz",
      "age_label": "12 dk"
    }
  ],
  "automations": [
    {
      "name": "Geciken işe uyarı",
      "summary": "Son teslim geçmişse yöneticiye bildirim gönder",
      "status_label": "Aktif",
      "last_run_label": "Bugün 09:14"
    }
  ],
  "workload_rows": [
    {
      "name": "Onur Kaya",
      "assigned_count": 5,
      "tracked_hours_label": "7.8 saat",
      "capacity_percent": 108,
      "status_label": "Aşırı yükte"
    }
  ],
  "request_forms": [
    {
      "title": "Saha Talep Formu",
      "target_team": "Saha Operasyon",
      "submissions_today": 6,
      "cta_label": "Form akışı açık"
    }
  ]
}
```

### Görev ek alanları

`GET /tasks` içindeki her görev nesnesi opsiyonel olarak:

```json
{
  "estimated_minutes": 180,
  "tracked_minutes": 95,
  "blocked_by_count": 1,
  "subtask_count": 2,
  "request_source": "Saha Talep Formu",
  "dependencies": [
    {
      "title": "Malzeme onayı",
      "status_label": "Bekleniyor"
    }
  ],
  "time_entries": [
    {
      "user_name": "Merve Aydın",
      "duration_label": "1s 35dk",
      "started_at_label": "12.03.2026 09:00"
    }
  ]
}
```

### Ekip ek alanları

`GET /team` içindeki her `member` nesnesi opsiyonel olarak:

```json
{
  "capacity_percent": 72,
  "tracked_hours_label": "5.2 saat",
  "workload_status_label": "Dengeli kapasite"
}
```

### Ayarlar ek alanları

`GET /settings/general` ve `PUT /settings/general` için opsiyonel alanlar:

```json
{
  "automation_center_enabled": true,
  "work_forms_enabled": true,
  "time_tracking_enabled": true,
  "permission_profiles": [
    {
      "title": "Lider görünümü",
      "summary": "Görev atar, form kayıtlarını görür, rapor export eder."
    }
  ],
  "integrations": [
    {
      "name": "Slack",
      "status_label": "Webhook bağlı",
      "connected": true
    }
  ]
}
```

Bu alanlar Monday.com’daki otomasyon, WorkForms, workload, item updates ve entegrasyon görünümüne karşılık gelir.

## Backend notları

- `company_code` üretimi backend tarafında benzersiz doğrulanmalı
- `user_code` üretimi backend tarafında benzersiz doğrulanmalı
- Rol ve izin kontrolü yalnızca Flutter'da değil, sunucuda zorlanmalı
- Görev, revizyon ve rapor action endpoint'leri audit log üretmeli
- Uygulama artık mock veri göstermediği için bu endpoint'ler boş dönerse ekranda `loading / empty / error` durumları görünür
