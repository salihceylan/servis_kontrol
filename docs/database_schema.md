# Workflow Veritabanı Şeması

Bu belge iki şeyi netleştirir:

1. Şu an backend tarafında gerçekten oluşmuş tablolar
2. Flutter arayüzünde gördüğümüz tüm modüllerin dinamik çalışması için açılması gereken gerçek tablolar

## Şu an gerçekten oluşmuş tablolar

Laravel iskeleti kurulduğunda yalnızca çerçeve tabloları oluştu:

- `users`
- `cache`
- `cache_locks`
- `jobs`
- `job_batches`
- `failed_jobs`
- `personal_access_tokens`

Bu tablo seti yalnızca framework ayağa kalksın diye yeterlidir. Görevler, revizyonlar, ekip, performans, raporlar, ayarlar ve yardım merkezi için ek tablo gerekir.

## Kimlik tasarımı

Sistem içi `id` ile kullanıcıya gösterilen iş kodları farklı olmalı.

- Her ana tabloda sistem içi `id`
  - öneri: `uuid` veya `bigint`
- Şirket için dış kimlik:
  - `company_code CHAR(6) UNIQUE`
  - yalnızca rakam
  - rastgele üretilmiş
- Kullanıcı için dış kimlik:
  - `user_code CHAR(11) UNIQUE`
  - yalnızca rakam
  - benzersiz

Özet:

- `id` = ilişki anahtarı
- `company_code` = şirket dış kodu
- `user_code` = kullanıcı dış kodu

## Zorunlu ana tablo grupları

### 1. Şirket ve tenant yapısı

- `companies`
  - `id`
  - `company_code`
  - `name`
  - `status`
  - `owner_user_id`
  - `timezone`
  - `locale`
  - `created_at`
  - `updated_at`

- `company_settings`
  - `id`
  - `company_id`
  - `workday_start`
  - `workday_end`
  - `default_report_format`
  - `default_notification_channel`
  - `revision_warning_threshold`
  - `task_due_warning_hours`
  - `allow_email_reports`
  - `allow_slack_reports`
  - `created_at`
  - `updated_at`

### 2. Kullanıcı, rol, yetki, pozisyon

- `users`
  - `id`
  - `company_id`
  - `user_code`
  - `full_name`
  - `email`
  - `phone`
  - `password_hash`
  - `position_id`
  - `department_id`
  - `status`
  - `is_first_login`
  - `last_login_at`
  - `created_at`
  - `updated_at`

- `departments`
  - `id`
  - `company_id`
  - `name`
  - `code`

- `positions`
  - `id`
  - `company_id`
  - `name`
  - `code`
  - `level`

- `roles`
  - `id`
  - `company_id`
  - `name`
  - `code`
  - `is_system_role`

- `permissions`
  - `id`
  - `module`
  - `action`
  - `code`

- `role_permissions`
  - `id`
  - `role_id`
  - `permission_id`

- `user_roles`
  - `id`
  - `user_id`
  - `role_id`

- `user_permission_overrides`
  - `id`
  - `user_id`
  - `permission_id`
  - `is_allowed`

- `user_settings`
  - `id`
  - `user_id`
  - `theme_preference`
  - `language`
  - `wants_quick_tour`
  - `default_dashboard_view`
  - `created_at`
  - `updated_at`

- `notification_preferences`
  - `id`
  - `user_id`
  - `in_app_enabled`
  - `email_enabled`
  - `slack_enabled`
  - `daily_summary_enabled`
  - `report_ready_enabled`
  - `revision_alert_enabled`

### 3. Ekip yapısı

- `teams`
  - `id`
  - `company_id`
  - `name`
  - `code`
  - `manager_user_id`

- `team_members`
  - `id`
  - `team_id`
  - `user_id`
  - `joined_at`
  - `is_lead`

### 4. Proje ve görev akışı

- `projects`
  - `id`
  - `company_id`
  - `team_id`
  - `code`
  - `name`
  - `client_name`
  - `status`
  - `start_date`
  - `due_date`
  - `priority`
  - `created_by`
  - `created_at`
  - `updated_at`

- `project_members`
  - `id`
  - `project_id`
  - `user_id`
  - `role`

- `task_statuses`
  - `id`
  - `company_id`
  - `name`
  - `code`
  - `sort_order`
  - `is_closed`

- `tasks`
  - `id`
  - `company_id`
  - `project_id`
  - `parent_task_id`
  - `task_no`
  - `title`
  - `description`
  - `status_id`
  - `priority`
  - `primary_assignee_id`
  - `created_by`
  - `due_at`
  - `started_at`
  - `completed_at`
  - `estimated_minutes`
  - `actual_minutes`
  - `quality_score`
  - `revision_count`
  - `is_flagged`
  - `flag_reason`
  - `created_at`
  - `updated_at`

- `task_assignments`
  - `id`
  - `task_id`
  - `user_id`
  - `assignment_type`
  - `assigned_by`
  - `assigned_at`

- `task_checklists`
  - `id`
  - `task_id`
  - `title`
  - `is_completed`
  - `completed_by`
  - `completed_at`
  - `sort_order`

- `task_labels`
  - `id`
  - `company_id`
  - `name`
  - `color`

- `task_label_links`
  - `id`
  - `task_id`
  - `label_id`

- `task_comments`
  - `id`
  - `task_id`
  - `user_id`
  - `body`
  - `comment_type`
  - `created_at`

- `task_attachments`
  - `id`
  - `task_id`
  - `uploaded_by`
  - `file_name`
  - `file_path`
  - `mime_type`
  - `file_size`
  - `created_at`

- `task_status_history`
  - `id`
  - `task_id`
  - `from_status_id`
  - `to_status_id`
  - `changed_by`
  - `note`
  - `created_at`

- `task_time_logs`
  - `id`
  - `task_id`
  - `user_id`
  - `started_at`
  - `ended_at`
  - `duration_minutes`
  - `source`

### 5. Revizyon ve onay akışı

- `revisions`
  - `id`
  - `task_id`
  - `requested_by`
  - `assigned_to`
  - `revision_no`
  - `reason`
  - `status`
  - `is_warning_triggered`
  - `requested_at`
  - `resolved_at`

- `revision_messages`
  - `id`
  - `revision_id`
  - `user_id`
  - `message`
  - `message_type`
  - `created_at`

- `approvals`
  - `id`
  - `task_id`
  - `revision_id`
  - `approver_user_id`
  - `decision`
  - `decision_note`
  - `decided_at`

### 6. Dashboard, performans ve raporlama

- `performance_snapshots`
  - `id`
  - `company_id`
  - `user_id`
  - `team_id`
  - `period_type`
  - `period_start`
  - `period_end`
  - `completed_count`
  - `late_count`
  - `avg_completion_minutes`
  - `avg_revision_count`
  - `quality_score`
  - `overall_score`
  - `created_at`

- `dashboard_widgets`
  - `id`
  - `company_id`
  - `user_id`
  - `widget_type`
  - `config_json`
  - `sort_order`

- `report_templates`
  - `id`
  - `company_id`
  - `name`
  - `report_type`
  - `scope_type`
  - `filters_json`
  - `default_format`

- `report_runs`
  - `id`
  - `company_id`
  - `template_id`
  - `requested_by`
  - `report_type`
  - `scope_label`
  - `format`
  - `status`
  - `file_path`
  - `emailed_to`
  - `created_at`
  - `completed_at`

### 7. Bildirim, yardım merkezi, sistem ayarları

- `notifications`
  - `id`
  - `company_id`
  - `user_id`
  - `title`
  - `body`
  - `notification_type`
  - `related_task_id`
  - `related_revision_id`
  - `is_read`
  - `created_at`

- `alerts`
  - `id`
  - `company_id`
  - `task_id`
  - `user_id`
  - `alert_type`
  - `severity`
  - `message`
  - `is_resolved`
  - `created_at`
  - `resolved_at`

- `help_articles`
  - `id`
  - `company_id`
  - `title`
  - `slug`
  - `body`
  - `status`

- `system_settings`
  - `id`
  - `company_id`
  - `setting_key`
  - `setting_value`

### 8. Güvenlik ve denetim

- `audit_logs`
  - `id`
  - `company_id`
  - `user_id`
  - `entity_type`
  - `entity_id`
  - `action`
  - `old_values_json`
  - `new_values_json`
  - `ip_address`
  - `created_at`

- `login_attempts`
  - `id`
  - `email`
  - `ip_address`
  - `is_success`
  - `attempted_at`

- `password_reset_tokens`
  - Laravel standart tablo

- `sessions`
  - veritabanı tabanlı oturum kullanılacaksa gerekli

## İlk canlı sürüm için minimum tablo seti

Arayüzde görülen her şeyi gerçek veriye bağlamak için ilk migration paketinde en az şu tablolar açılmalı:

- `companies`
- `company_settings`
- `users`
- `departments`
- `positions`
- `roles`
- `permissions`
- `role_permissions`
- `user_roles`
- `user_settings`
- `notification_preferences`
- `teams`
- `team_members`
- `projects`
- `tasks`
- `task_assignments`
- `task_comments`
- `task_attachments`
- `task_status_history`
- `task_time_logs`
- `revisions`
- `revision_messages`
- `approvals`
- `notifications`
- `alerts`
- `performance_snapshots`
- `report_runs`
- `help_articles`
- `audit_logs`

## Ayarlar menüsü için doğrudan gerekli tablo seti

`Genel Ayarlar` ve `Yardım Merkezi` ekranlarının gerçek veriyle çalışması için en az:

- `companies`
- `company_settings`
- `user_settings`
- `notification_preferences`
- `help_articles`
- `system_settings`

## Sonuç

Şu an canlı backend yalnızca framework iskelet seviyesinde.

Flutter tarafında görünen modüllerin tamamının dinamik çalışması için:

1. Yukarıdaki tablolar açılmalı
2. API endpoint'leri hazırlanmalı
3. Şirket kodu ve kullanıcı kodu üretimi backend tarafında garanti edilmeli
4. Rol ve izin matrisi sunucuda zorlanmalı
5. Ayarlar ve yardım merkezi içerikleri panelden yönetilebilir hale getirilmeli
