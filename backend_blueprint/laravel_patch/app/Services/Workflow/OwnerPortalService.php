<?php

namespace App\Services\Workflow;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use RuntimeException;

class OwnerPortalService
{
    public function __construct(
        private readonly WorkflowApiService $workflow,
    ) {
    }

    public function dashboard(User $user): array
    {
        $this->ensureOwnerAccess($user);

        $companyRows = DB::table('companies')
            ->select(['id', 'name', 'status'])
            ->orderBy('name')
            ->get();

        $totalCompanies = $companyRows->count();
        $activeCompanies = $companyRows->where('status', 'active')->count();
        $totalActiveUsers = DB::table('users')->where('status', 'active')->count();
        $openTasks = DB::table('tasks as t')
            ->join('task_statuses as ts', 'ts.id', '=', 't.status_id')
            ->where('ts.code', '!=', 'delivered')
            ->count();
        $requestCount = DB::table('audit_logs')
            ->whereIn('action', ['sign_up_requested', 'forgot_password_requested'])
            ->count();

        $recentRequests = DB::table('audit_logs')
            ->whereIn('action', ['sign_up_requested', 'forgot_password_requested'])
            ->orderByDesc('created_at')
            ->limit(8)
            ->get()
            ->map(fn ($item) => $this->requestItemPayload($item))
            ->values()
            ->all();

        $planDistribution = [];
        foreach ($companyRows as $company) {
            $subscription = $this->subscriptionSettings((int) $company->id);
            $planName = $subscription['plan_name'];
            $planDistribution[$planName] = ($planDistribution[$planName] ?? 0) + 1;
        }

        arsort($planDistribution);

        $companyWatchlist = $companyRows
            ->sortByDesc(fn ($company) => $this->companyStats((int) $company->id)['open_tasks'])
            ->take(6)
            ->map(function ($company) {
                return $this->companyListItemPayload(
                    $this->companyBaseRow((int) $company->id),
                );
            })
            ->values()
            ->all();

        return [
            'title' => 'Owner Dashboard',
            'subtitle' => 'Musteri tenantlari, lisanslar ve destek talepleri tek arka ofiste.',
            'summary_cards' => [
                [
                    'label' => 'Sirket',
                    'value' => $totalCompanies,
                    'caption' => $activeCompanies . ' aktif tenant',
                    'accent' => 'primary',
                    'icon' => 'business',
                ],
                [
                    'label' => 'Aktif Kullanici',
                    'value' => $totalActiveUsers,
                    'caption' => 'Tum tenantlarda aktif hesaplar',
                    'accent' => 'success',
                    'icon' => 'users',
                ],
                [
                    'label' => 'Acik Gorev',
                    'value' => $openTasks,
                    'caption' => 'Teslim bekleyen toplam is',
                    'accent' => 'warning',
                    'icon' => 'task',
                ],
                [
                    'label' => 'Destek Talebi',
                    'value' => $requestCount,
                    'caption' => 'Kaydol ve sifre talepleri',
                    'accent' => 'danger',
                    'icon' => 'support',
                ],
            ],
            'plan_breakdown' => collect($planDistribution)
                ->map(fn ($count, $plan) => [
                    'plan_name' => $plan,
                    'company_count' => $count,
                ])
                ->values()
                ->all(),
            'recent_requests' => $recentRequests,
            'company_watchlist' => $companyWatchlist,
        ];
    }

    public function companies(User $user): array
    {
        $this->ensureOwnerAccess($user);

        return DB::table('companies as c')
            ->leftJoin('users as owner', 'owner.id', '=', 'c.owner_user_id')
            ->select([
                'c.id',
                'c.company_code',
                'c.name',
                'c.status',
                'c.timezone',
                'c.locale',
                'c.created_at',
                'owner.name as owner_name',
                'owner.email as owner_email',
            ])
            ->orderByDesc('c.created_at')
            ->get()
            ->map(fn ($company) => $this->companyListItemPayload($company))
            ->values()
            ->all();
    }

    public function createCompany(User $user, array $payload): array
    {
        $this->ensureOwnerAccess($user);

        $adminEmail = trim(Str::lower((string) $payload['admin_email']));
        if (User::query()->where('email', $adminEmail)->exists()) {
            throw new RuntimeException('Bu e-posta ile baska bir kullanici zaten var.');
        }

        $companyId = DB::transaction(function () use ($payload, $adminEmail): int {
            $companyName = trim((string) $payload['company_name']);
            $adminName = trim((string) $payload['admin_name']);
            $adminPassword = (string) $payload['admin_password'];
            $departmentName = trim((string) ($payload['department_name'] ?? 'Yonetim'));
            $teamName = trim((string) ($payload['team_name'] ?? 'Merkez Operasyon'));

            $companyId = (int) DB::table('companies')->insertGetId([
                'name' => $companyName,
                'status' => 'active',
                'timezone' => $payload['timezone'] ?? 'Europe/Istanbul',
                'locale' => $payload['locale'] ?? 'tr',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::select('SELECT wf_seed_company_defaults(?)', [$companyId]);

            $departmentId = $this->findOrCreateDepartment($companyId, $departmentName);
            $positionId = $this->findOrCreatePosition($companyId, 'Sirket Yoneticisi');

            $teamCode = Str::slug($teamName, '_');
            $teamId = (int) DB::table('teams')->insertGetId([
                'company_id' => $companyId,
                'name' => $teamName,
                'code' => $teamCode === '' ? 'merkez_operasyon' : $teamCode,
                'manager_user_id' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $userId = (int) DB::table('users')->insertGetId([
                'company_id' => $companyId,
                'name' => $adminName,
                'email' => $adminEmail,
                'password' => Hash::make($adminPassword),
                'department_id' => $departmentId,
                'position_id' => $positionId,
                'team_id' => $teamId,
                'status' => 'active',
                'is_first_login' => false,
                'work_preference' => 'Tenant owner management',
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

            if ($managerRoleId === null) {
                throw new RuntimeException('Manager rolu bulunamadi.');
            }

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

            $this->upsertSubscriptionSettings($companyId, $payload);
            $this->upsertSupportSettings($companyId, [
                'support_email' => $payload['support_email'] ?? 'kodver@gudeteknoloji.com.tr',
                'response_sla' => $payload['response_sla'] ?? '4 is saati',
            ]);

            return $companyId;
        });

        return $this->companyDetail($user, $companyId);
    }

    public function companyDetail(User $user, int $companyId): array
    {
        $this->ensureOwnerAccess($user);

        $company = $this->companyBaseRow($companyId);
        $subscription = $this->subscriptionSettings($companyId);
        $stats = $this->companyStats($companyId);
        $settings = $this->companySettings($companyId);

        $recentActivity = DB::table('audit_logs')
            ->where('company_id', $companyId)
            ->orderByDesc('created_at')
            ->limit(8)
            ->get()
            ->map(function ($item) {
                return [
                    'title' => Str::headline((string) $item->action),
                    'detail' => Str::limit((string) $item->entity_type . ' / ' . (string) $item->entity_id, 90),
                    'created_at' => Carbon::parse($item->created_at)->toIso8601String(),
                ];
            })
            ->values()
            ->all();

        $loginActivity = DB::table('login_attempts')
            ->whereIn('email', function ($query) use ($companyId) {
                $query->select('email')->from('users')->where('company_id', $companyId);
            })
            ->orderByDesc('attempted_at')
            ->limit(6)
            ->get()
            ->map(fn ($item) => [
                'email' => $item->email,
                'is_success' => (bool) $item->is_success,
                'ip_address' => (string) ($item->ip_address ?? ''),
                'attempted_at' => Carbon::parse($item->attempted_at)->toIso8601String(),
            ])
            ->values()
            ->all();

        return [
            'id' => (string) $company->id,
            'company_code' => trim((string) $company->company_code),
            'name' => $company->name,
            'status' => $company->status,
            'timezone' => $company->timezone,
            'locale' => $company->locale,
            'created_at' => Carbon::parse($company->created_at)->toIso8601String(),
            'owner' => [
                'name' => $company->owner_name ?? 'Atanmamis',
                'email' => $company->owner_email ?? '',
            ],
            'subscription' => $subscription,
            'support' => [
                'support_email' => $settings['support_email'] ?? 'kodver@gudeteknoloji.com.tr',
                'response_sla' => $settings['response_sla'] ?? '4 is saati',
            ],
            'stats' => $stats,
            'recent_activity' => $recentActivity,
            'login_activity' => $loginActivity,
        ];
    }

    public function updateCompany(User $user, int $companyId, array $payload): array
    {
        $this->ensureOwnerAccess($user);
        $company = $this->companyBaseRow($companyId);

        DB::table('companies')->where('id', $companyId)->update([
            'name' => trim((string) ($payload['company_name'] ?? $company->name)),
            'status' => $payload['status'] ?? $company->status,
            'timezone' => $payload['timezone'] ?? $company->timezone,
            'locale' => $payload['locale'] ?? $company->locale,
            'updated_at' => now(),
        ]);

        $this->upsertSupportSettings($companyId, [
            'support_email' => $payload['support_email'] ?? null,
            'response_sla' => $payload['response_sla'] ?? null,
        ]);

        return $this->companyDetail($user, $companyId);
    }

    public function updateSubscription(User $user, int $companyId, array $payload): array
    {
        $this->ensureOwnerAccess($user);
        $this->companyBaseRow($companyId);
        $this->upsertSubscriptionSettings($companyId, $payload);

        return $this->companyDetail($user, $companyId);
    }

    public function support(User $user): array
    {
        $this->ensureOwnerAccess($user);

        $companies = DB::table('companies as c')
            ->leftJoin('users as owner', 'owner.id', '=', 'c.owner_user_id')
            ->select([
                'c.id',
                'c.company_code',
                'c.name',
                'c.status',
                'c.timezone',
                'c.locale',
                'c.created_at',
                'owner.name as owner_name',
                'owner.email as owner_email',
            ])
            ->orderBy('c.name')
            ->get()
            ->map(fn ($company) => $this->companyListItemPayload($company))
            ->values()
            ->all();

        $accessLogs = DB::table('audit_logs')
            ->where('action', 'owner_support_access')
            ->orderByDesc('created_at')
            ->limit(20)
            ->get()
            ->map(function ($item) {
                $payload = $this->decodeJsonPayload($item->new_values_json);

                return [
                    'company_id' => (string) ($item->company_id ?? ''),
                    'company_name' => $payload['company_name'] ?? 'Bilinmiyor',
                    'actor_name' => $payload['actor_name'] ?? 'Owner',
                    'actor_email' => $payload['actor_email'] ?? '',
                    'created_at' => Carbon::parse($item->created_at)->toIso8601String(),
                ];
            })
            ->values()
            ->all();

        return [
            'companies' => $companies,
            'access_logs' => $accessLogs,
        ];
    }

    public function requests(User $user): array
    {
        $this->ensureOwnerAccess($user);

        return [
            'items' => DB::table('audit_logs')
                ->whereIn('action', ['sign_up_requested', 'forgot_password_requested'])
                ->orderByDesc('created_at')
                ->limit(40)
                ->get()
                ->map(fn ($item) => $this->requestItemPayload($item))
                ->values()
                ->all(),
        ];
    }

    public function registerSupportAccess(User $user, int $companyId): array
    {
        $this->ensureOwnerAccess($user);
        $company = $this->companyBaseRow($companyId);

        DB::table('audit_logs')->insert([
            'company_id' => $companyId,
            'user_id' => $user->id,
            'entity_type' => 'owner_portal',
            'entity_id' => (string) $companyId,
            'action' => 'owner_support_access',
            'old_values_json' => null,
            'new_values_json' => json_encode([
                'company_name' => $company->name,
                'actor_name' => $user->name,
                'actor_email' => $user->email,
            ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'ip_address' => null,
            'created_at' => now(),
        ]);

        return [
            'message' => 'Destek erisim kaydi olusturuldu.',
        ];
    }

    private function ensureOwnerAccess(User $user): void
    {
        if (!$this->workflow->isOwnerUser($user)) {
            throw new AuthorizationException('Bu alan yalnizca owner kullanicilar icindir.');
        }
    }

    private function companyBaseRow(int $companyId): object
    {
        return DB::table('companies as c')
            ->leftJoin('users as owner', 'owner.id', '=', 'c.owner_user_id')
            ->where('c.id', $companyId)
            ->select([
                'c.id',
                'c.company_code',
                'c.name',
                'c.status',
                'c.timezone',
                'c.locale',
                'c.created_at',
                'owner.name as owner_name',
                'owner.email as owner_email',
            ])
            ->firstOrFail();
    }

    private function companyListItemPayload(object $company): array
    {
        $stats = $this->companyStats((int) $company->id);
        $subscription = $this->subscriptionSettings((int) $company->id);

        return [
            'id' => (string) $company->id,
            'company_code' => trim((string) $company->company_code),
            'name' => $company->name,
            'status' => $company->status,
            'owner_name' => $company->owner_name ?? 'Atanmamis',
            'owner_email' => $company->owner_email ?? '',
            'timezone' => $company->timezone,
            'locale' => $company->locale,
            'created_at' => Carbon::parse($company->created_at)->toIso8601String(),
            'subscription' => $subscription,
            'stats' => $stats,
        ];
    }

    private function companyStats(int $companyId): array
    {
        $activeUsers = DB::table('users')
            ->where('company_id', $companyId)
            ->where('status', 'active')
            ->count();
        $taskCount = DB::table('tasks')
            ->where('company_id', $companyId)
            ->count();
        $openTasks = DB::table('tasks as t')
            ->join('task_statuses as ts', 'ts.id', '=', 't.status_id')
            ->where('t.company_id', $companyId)
            ->where('ts.code', '!=', 'delivered')
            ->count();
        $storageUsedBytes = (int) DB::table('task_attachments as ta')
            ->join('tasks as t', 't.id', '=', 'ta.task_id')
            ->where('t.company_id', $companyId)
            ->sum('ta.file_size');
        $lastLoginAt = DB::table('users')
            ->where('company_id', $companyId)
            ->max('last_login_at');
        $revisionCount = DB::table('revisions as r')
            ->join('tasks as t', 't.id', '=', 'r.task_id')
            ->where('t.company_id', $companyId)
            ->whereIn('r.status', ['pending_review', 'in_revision'])
            ->count();

        return [
            'active_users' => $activeUsers,
            'task_count' => $taskCount,
            'open_tasks' => $openTasks,
            'open_revisions' => $revisionCount,
            'storage_used_bytes' => $storageUsedBytes,
            'last_login_at' => $lastLoginAt ? Carbon::parse($lastLoginAt)->toIso8601String() : null,
        ];
    }

    private function companySettings(int $companyId): array
    {
        return DB::table('system_settings')
            ->where('company_id', $companyId)
            ->pluck('setting_value', 'setting_key')
            ->map(fn ($value) => (string) $value)
            ->all();
    }

    private function subscriptionSettings(int $companyId): array
    {
        $settings = $this->companySettings($companyId);

        return [
            'plan_name' => $settings['subscription.plan_name'] ?? 'Scale',
            'user_limit' => (int) ($settings['subscription.user_limit'] ?? 25),
            'storage_limit_gb' => (int) ($settings['subscription.storage_limit_gb'] ?? 50),
            'license_ends_at' => $settings['subscription.license_ends_at'] ?? now()->addMonths(1)->toDateString(),
            'modules' => [
                'reports' => $this->settingBool($settings, 'feature.reports_enabled', true),
                'revisions' => $this->settingBool($settings, 'feature.revisions_enabled', true),
                'automations' => $this->settingBool($settings, 'feature.automation_enabled', false),
                'request_forms' => $this->settingBool($settings, 'feature.request_forms_enabled', false),
            ],
        ];
    }

    private function upsertSubscriptionSettings(int $companyId, array $payload): void
    {
        $modulePayload = $payload['modules'] ?? [];

        DB::table('system_settings')->upsert([
            [
                'company_id' => $companyId,
                'setting_key' => 'subscription.plan_name',
                'setting_value' => trim((string) ($payload['plan_name'] ?? 'Scale')),
                'updated_at' => now(),
            ],
            [
                'company_id' => $companyId,
                'setting_key' => 'subscription.user_limit',
                'setting_value' => (string) ($payload['user_limit'] ?? 25),
                'updated_at' => now(),
            ],
            [
                'company_id' => $companyId,
                'setting_key' => 'subscription.storage_limit_gb',
                'setting_value' => (string) ($payload['storage_limit_gb'] ?? 50),
                'updated_at' => now(),
            ],
            [
                'company_id' => $companyId,
                'setting_key' => 'subscription.license_ends_at',
                'setting_value' => (string) ($payload['license_ends_at'] ?? now()->addMonths(1)->toDateString()),
                'updated_at' => now(),
            ],
            [
                'company_id' => $companyId,
                'setting_key' => 'feature.reports_enabled',
                'setting_value' => $this->toSettingBool($modulePayload['reports'] ?? true),
                'updated_at' => now(),
            ],
            [
                'company_id' => $companyId,
                'setting_key' => 'feature.revisions_enabled',
                'setting_value' => $this->toSettingBool($modulePayload['revisions'] ?? true),
                'updated_at' => now(),
            ],
            [
                'company_id' => $companyId,
                'setting_key' => 'feature.automation_enabled',
                'setting_value' => $this->toSettingBool($modulePayload['automations'] ?? false),
                'updated_at' => now(),
            ],
            [
                'company_id' => $companyId,
                'setting_key' => 'feature.request_forms_enabled',
                'setting_value' => $this->toSettingBool($modulePayload['request_forms'] ?? false),
                'updated_at' => now(),
            ],
        ], ['company_id', 'setting_key'], ['setting_value', 'updated_at']);
    }

    private function upsertSupportSettings(int $companyId, array $payload): void
    {
        $rows = [];
        if (isset($payload['support_email']) && $payload['support_email'] !== null) {
            $rows[] = [
                'company_id' => $companyId,
                'setting_key' => 'support_email',
                'setting_value' => trim((string) $payload['support_email']),
                'updated_at' => now(),
            ];
        }

        if (isset($payload['response_sla']) && $payload['response_sla'] !== null) {
            $rows[] = [
                'company_id' => $companyId,
                'setting_key' => 'response_sla',
                'setting_value' => trim((string) $payload['response_sla']),
                'updated_at' => now(),
            ];
        }

        if ($rows !== []) {
            DB::table('system_settings')->upsert($rows, ['company_id', 'setting_key'], ['setting_value', 'updated_at']);
        }
    }

    private function requestItemPayload(object $item): array
    {
        $payload = $this->decodeJsonPayload($item->new_values_json);

        return [
            'type' => (string) $item->action,
            'email' => $payload['email'] ?? (string) $item->entity_id,
            'full_name' => $payload['full_name'] ?? '',
            'company_name' => $payload['company_name'] ?? '',
            'phone' => $payload['phone'] ?? '',
            'ip_address' => (string) ($item->ip_address ?? ''),
            'created_at' => Carbon::parse($item->created_at)->toIso8601String(),
        ];
    }

    private function decodeJsonPayload(mixed $value): array
    {
        if (!is_string($value) || trim($value) === '') {
            return [];
        }

        $decoded = json_decode($value, true);
        return is_array($decoded) ? $decoded : [];
    }

    private function settingBool(array $settings, string $key, bool $default): bool
    {
        if (!array_key_exists($key, $settings)) {
            return $default;
        }

        return in_array(Str::lower((string) $settings[$key]), ['1', 'true', 'yes', 'on'], true);
    }

    private function toSettingBool(bool $value): string
    {
        return $value ? '1' : '0';
    }

    private function findOrCreateDepartment(int $companyId, string $name): int
    {
        $code = Str::slug($name, '_');
        $existing = DB::table('departments')
            ->where('company_id', $companyId)
            ->where('code', $code)
            ->value('id');

        if ($existing !== null) {
            return (int) $existing;
        }

        return (int) DB::table('departments')->insertGetId([
            'company_id' => $companyId,
            'name' => $name,
            'code' => $code === '' ? 'yonetim' : $code,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function findOrCreatePosition(int $companyId, string $name): int
    {
        $code = Str::slug($name, '_');
        $existing = DB::table('positions')
            ->where('company_id', $companyId)
            ->where('code', $code)
            ->value('id');

        if ($existing !== null) {
            return (int) $existing;
        }

        return (int) DB::table('positions')->insertGetId([
            'company_id' => $companyId,
            'name' => $name,
            'code' => $code === '' ? 'company_owner' : $code,
            'level' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
