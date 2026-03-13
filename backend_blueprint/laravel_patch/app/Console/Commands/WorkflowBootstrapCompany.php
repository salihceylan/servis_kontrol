<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class WorkflowBootstrapCompany extends Command
{
    protected $signature = 'workflow:bootstrap-company
        {company : Sirket adi}
        {owner_name : Owner kullanici adi}
        {owner_email : Owner e-posta adresi}
        {owner_password : Owner parolasi}
        {--with-sample-data : Test icin ornek proje ve gorevler uret}';

    protected $description = 'Workflow icin ilk sirket, owner kullanici ve temel ayarlari olusturur.';

    public function handle(): int
    {
        $companyName = trim((string) $this->argument('company'));
        $ownerName = trim((string) $this->argument('owner_name'));
        $ownerEmail = trim(Str::lower((string) $this->argument('owner_email')));
        $ownerPassword = (string) $this->argument('owner_password');

        if (User::query()->where('email', $ownerEmail)->exists()) {
            $this->error('Bu e-posta ile bir kullanici zaten var.');
            return self::FAILURE;
        }

        DB::transaction(function () use ($companyName, $ownerName, $ownerEmail, $ownerPassword): void {
            $companyId = DB::table('companies')->insertGetId([
                'name' => $companyName,
                'status' => 'active',
                'timezone' => 'Europe/Istanbul',
                'locale' => 'tr',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::select('SELECT wf_seed_company_defaults(?)', [$companyId]);

            $departmentId = DB::table('departments')
                ->where('company_id', $companyId)
                ->where('code', 'yonetim')
                ->value('id');

            $positionId = DB::table('positions')
                ->where('company_id', $companyId)
                ->where('code', 'company_owner')
                ->value('id');

            $teamId = DB::table('teams')->insertGetId([
                'company_id' => $companyId,
                'name' => 'Merkez Operasyon',
                'code' => 'merkez_operasyon',
                'manager_user_id' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $userId = DB::table('users')->insertGetId([
                'company_id' => $companyId,
                'name' => $ownerName,
                'email' => $ownerEmail,
                'password' => Hash::make($ownerPassword),
                'department_id' => $departmentId,
                'position_id' => $positionId,
                'team_id' => $teamId,
                'status' => 'active',
                'is_first_login' => false,
                'work_preference' => 'Merkez operasyon yönetimi',
                'wants_quick_tour' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('companies')->where('id', $companyId)->update([
                'owner_user_id' => $userId,
                'updated_at' => now(),
            ]);

            DB::table('teams')->where('id', $teamId)->update([
                'manager_user_id' => $userId,
                'updated_at' => now(),
            ]);

            $managerRoleId = DB::table('roles')
                ->where('company_id', $companyId)
                ->where('code', 'manager')
                ->value('id');

            DB::table('user_roles')->insert([
                'user_id' => $userId,
                'role_id' => $managerRoleId,
                'created_at' => now(),
            ]);

            DB::table('notification_preferences')->insert([
                'user_id' => $userId,
                'in_app_enabled' => true,
                'email_enabled' => true,
                'slack_enabled' => false,
                'daily_summary_enabled' => true,
                'report_ready_enabled' => true,
                'revision_alert_enabled' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('user_settings')->insert([
                'user_id' => $userId,
                'theme_preference' => 'light',
                'language' => 'tr',
                'wants_quick_tour' => false,
                'default_dashboard_view' => 'panel',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('system_settings')->upsert([
                [
                    'company_id' => $companyId,
                    'setting_key' => 'support_email',
                    'setting_value' => 'kodver@gudeteknoloji.com.tr',
                    'updated_at' => now(),
                ],
                [
                    'company_id' => $companyId,
                    'setting_key' => 'response_sla',
                    'setting_value' => '4 iş saati',
                    'updated_at' => now(),
                ],
                [
                    'company_id' => $companyId,
                    'setting_key' => 'notification_summary_enabled',
                    'setting_value' => '1',
                    'updated_at' => now(),
                ],
                [
                    'company_id' => $companyId,
                    'setting_key' => 'email_notifications_enabled',
                    'setting_value' => '1',
                    'updated_at' => now(),
                ],
                [
                    'company_id' => $companyId,
                    'setting_key' => 'slack_notifications_enabled',
                    'setting_value' => '0',
                    'updated_at' => now(),
                ],
            ], ['company_id', 'setting_key'], ['setting_value', 'updated_at']);

            if ($this->option('with-sample-data')) {
                $this->seedSampleData($companyId, (int) $userId, (int) $teamId);
            }

            $companyCode = DB::table('companies')->where('id', $companyId)->value('company_code');
            $userCode = DB::table('users')->where('id', $userId)->value('user_code');

            $this->info('Workflow company bootstrap tamamlandi.');
            $this->line('company_id: ' . $companyId);
            $this->line('company_code: ' . trim((string) $companyCode));
            $this->line('owner_user_id: ' . $userId);
            $this->line('owner_user_code: ' . trim((string) $userCode));
            $this->line('owner_email: ' . $ownerEmail);
        });

        return self::SUCCESS;
    }

    private function seedSampleData(int $companyId, int $ownerUserId, int $teamId): void
    {
        $projectId = DB::table('projects')->insertGetId([
            'company_id' => $companyId,
            'team_id' => $teamId,
            'code' => 'MRKZ-001',
            'name' => 'Merkez Plaza Operasyon Takibi',
            'client_name' => 'Merkez Plaza',
            'status' => 'active',
            'start_date' => now()->toDateString(),
            'due_date' => now()->addDays(14)->toDateString(),
            'priority' => 'high',
            'created_by' => $ownerUserId,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $pendingStatusId = DB::table('task_statuses')->where('company_id', $companyId)->where('code', 'pending')->value('id');
        $inProgressStatusId = DB::table('task_statuses')->where('company_id', $companyId)->where('code', 'in_progress')->value('id');
        $reviewStatusId = DB::table('task_statuses')->where('company_id', $companyId)->where('code', 'in_review')->value('id');

        $taskA = DB::table('tasks')->insertGetId([
            'company_id' => $companyId,
            'project_id' => $projectId,
            'task_no' => 'T-1001',
            'title' => 'Saha kontrol listesi tamamla',
            'description' => 'Merkez Plaza sahasında haftalık kontrol turu yapılacak.',
            'status_id' => $inProgressStatusId,
            'priority' => 'high',
            'primary_assignee_id' => $ownerUserId,
            'created_by' => $ownerUserId,
            'due_at' => now()->addDay(),
            'started_at' => now()->subHours(2),
            'estimated_minutes' => 180,
            'actual_minutes' => 95,
            'quality_score' => 86,
            'revision_count' => 1,
            'created_at' => now()->subDay(),
            'updated_at' => now(),
        ]);

        $taskB = DB::table('tasks')->insertGetId([
            'company_id' => $companyId,
            'project_id' => $projectId,
            'task_no' => 'T-1002',
            'title' => 'Kamera revizyon geri donusu',
            'description' => 'Kamera montaj raporundaki eksik fotograflar tamamlanacak.',
            'status_id' => $reviewStatusId,
            'priority' => 'medium',
            'primary_assignee_id' => $ownerUserId,
            'created_by' => $ownerUserId,
            'due_at' => now()->addHours(8),
            'estimated_minutes' => 90,
            'actual_minutes' => 70,
            'quality_score' => 78,
            'revision_count' => 2,
            'created_at' => now()->subDay(),
            'updated_at' => now(),
        ]);

        DB::table('task_checklists')->insert([
            ['task_id' => $taskA, 'title' => 'Kontrol turunu baslat', 'is_completed' => true, 'completed_by' => $ownerUserId, 'completed_at' => now()->subHour(), 'sort_order' => 1],
            ['task_id' => $taskA, 'title' => 'Fotograf yukle', 'is_completed' => false, 'completed_by' => null, 'completed_at' => null, 'sort_order' => 2],
            ['task_id' => $taskA, 'title' => 'Kontrol formunu kapat', 'is_completed' => false, 'completed_by' => null, 'completed_at' => null, 'sort_order' => 3],
        ]);

        DB::table('task_comments')->insert([
            ['task_id' => $taskA, 'user_id' => $ownerUserId, 'body' => 'Saha ziyareti basladi, eksik ekipman listesi hazirlaniyor.', 'comment_type' => 'comment', 'created_at' => now()->subMinutes(40)],
            ['task_id' => $taskA, 'user_id' => $ownerUserId, 'body' => 'https://meet.jit.si/workflow-ornek-toplanti', 'comment_type' => 'meeting', 'created_at' => now()->subMinutes(20)],
        ]);

        DB::table('task_status_history')->insert([
            'task_id' => $taskA,
            'from_status_id' => $pendingStatusId,
            'to_status_id' => $inProgressStatusId,
            'changed_by' => $ownerUserId,
            'note' => 'Gorev isleme alindi.',
            'created_at' => now()->subHours(2),
        ]);

        $revisionId = DB::table('revisions')->insertGetId([
            'task_id' => $taskB,
            'requested_by' => $ownerUserId,
            'assigned_to' => $ownerUserId,
            'revision_no' => 2,
            'reason' => 'Kamera revizyon fotograflari eksik.',
            'status' => 'pending_review',
            'is_warning_triggered' => false,
            'requested_at' => now()->subHours(5),
            'created_at' => now()->subHours(5),
            'updated_at' => now()->subHour(),
        ]);

        DB::table('revision_messages')->insert([
            'revision_id' => $revisionId,
            'user_id' => $ownerUserId,
            'message' => 'Fotograflar yuklenip tekrar incelemeye gonderildi.',
            'message_type' => 'employee_update',
            'created_at' => now()->subHour(),
        ]);

        DB::table('alerts')->insert([
            'company_id' => $companyId,
            'task_id' => $taskB,
            'user_id' => $ownerUserId,
            'alert_type' => 'revision',
            'severity' => 'warning',
            'message' => 'Bir revizyon kaydi bugun sonuc bekliyor.',
            'is_resolved' => false,
            'created_at' => now()->subHour(),
            'resolved_at' => null,
        ]);

        DB::table('report_runs')->insert([
            'company_id' => $companyId,
            'template_id' => null,
            'requested_by' => $ownerUserId,
            'report_type' => 'operational',
            'scope_label' => 'Merkez Operasyon',
            'format' => 'pdf',
            'status' => 'ready',
            'file_path' => null,
            'emailed_to' => null,
            'created_at' => now()->subMinutes(10),
            'completed_at' => now()->subMinutes(8),
        ]);
    }
}
