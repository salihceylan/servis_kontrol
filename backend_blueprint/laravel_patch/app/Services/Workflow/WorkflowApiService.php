<?php

namespace App\Services\Workflow;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use RuntimeException;
use Throwable;

class WorkflowApiService
{
    public function attemptLogin(string $email, string $password, ?string $ipAddress = null): ?array
    {
        /** @var User|null $user */
        $user = User::query()->where('email', trim(Str::lower($email)))->first();

        if ($user === null || !Hash::check($password, $user->password)) {
            $this->recordLoginAttempt($email, $ipAddress, false);
            return null;
        }

        $this->recordLoginAttempt($email, $ipAddress, true);

        DB::table('users')->where('id', $user->id)->update([
            'last_login_at' => now(),
            'updated_at' => now(),
        ]);

        return [
            'token' => $user->createToken('workflow-web')->plainTextToken,
            'user' => $this->currentUserPayload($user),
        ];
    }

    public function recordForgotPasswordRequest(string $email, ?string $ipAddress = null): void
    {
        $normalizedEmail = trim(Str::lower($email));

        DB::table('audit_logs')->insert([
            'company_id' => null,
            'user_id' => null,
            'entity_type' => 'auth',
            'entity_id' => $normalizedEmail,
            'action' => 'forgot_password_requested',
            'old_values_json' => null,
            'new_values_json' => json_encode([
                'email' => $normalizedEmail,
            ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'ip_address' => $ipAddress,
            'created_at' => now(),
        ]);

        $mailFrom = config('mail.from.address');
        if (is_string($mailFrom) && $mailFrom !== '') {
            try {
                Mail::raw(
                    implode("\n", [
                        'Workflow parola sifirlama talebiniz alindi.',
                        'Guvenlik nedeniyle sifre sifirlama islemine destek ekibimiz geri donus saglayacaktir.',
                        'Destek e-postasi: ' . $mailFrom,
                    ]),
                    function ($message) use ($normalizedEmail): void {
                        $message
                            ->to($normalizedEmail)
                            ->subject('Workflow parola sifirlama talebi');
                    },
                );
            } catch (Throwable) {
                // SMTP hatasi audit kaydini bozmasin.
            }
        }
    }

    public function recordSignUpRequest(
        string $companyName,
        string $fullName,
        string $email,
        ?string $phone = null,
        ?string $ipAddress = null,
    ): void {
        $normalizedCompanyName = trim($companyName);
        $normalizedFullName = trim($fullName);
        $normalizedEmail = trim(Str::lower($email));
        $normalizedPhone = $phone !== null ? trim($phone) : null;

        DB::table('audit_logs')->insert([
            'company_id' => null,
            'user_id' => null,
            'entity_type' => 'auth',
            'entity_id' => $normalizedEmail,
            'action' => 'sign_up_requested',
            'old_values_json' => null,
            'new_values_json' => json_encode([
                'company_name' => $normalizedCompanyName,
                'full_name' => $normalizedFullName,
                'email' => $normalizedEmail,
                'phone' => $normalizedPhone,
            ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'ip_address' => $ipAddress,
            'created_at' => now(),
        ]);

        $mailFrom = config('mail.from.address');
        if (is_string($mailFrom) && $mailFrom !== '') {
            try {
                Mail::raw(
                    implode("\n", [
                        'Workflow kayit talebiniz alindi.',
                        'Sirket: ' . $normalizedCompanyName,
                        'Iletisim kisisi: ' . $normalizedFullName,
                        'Ekibimiz hesap acilisi icin sizinle iletisime gececek.',
                        'Destek e-postasi: ' . $mailFrom,
                    ]),
                    function ($message) use ($normalizedEmail): void {
                        $message
                            ->to($normalizedEmail)
                            ->subject('Workflow kayit talebi alindi');
                    },
                );
            } catch (Throwable) {
                // SMTP hatasi audit kaydini bozmasin.
            }
        }
    }

    public function completeOnboarding(User $user, array $payload): array
    {
        $context = $this->context($user);
        $departmentId = $this->findOrCreateDepartment($context['company_id'], $payload['department']);
        $positionId = $this->findOrCreatePosition($context['company_id'], $payload['job_title']);
        $channels = collect($payload['notification_channels'] ?? []);

        DB::table('users')->where('id', $user->id)->update([
            'name' => trim($payload['full_name']),
            'department_id' => $departmentId,
            'position_id' => $positionId,
            'work_preference' => trim((string) ($payload['work_preference'] ?? '')),
            'wants_quick_tour' => (bool) $payload['wants_quick_tour'],
            'is_first_login' => false,
            'updated_at' => now(),
        ]);

        DB::table('user_settings')->upsert([
            [
                'user_id' => $user->id,
                'theme_preference' => 'light',
                'language' => 'tr',
                'wants_quick_tour' => (bool) $payload['wants_quick_tour'],
                'default_dashboard_view' => 'panel',
                'updated_at' => now(),
            ],
        ], ['user_id'], ['theme_preference', 'language', 'wants_quick_tour', 'default_dashboard_view', 'updated_at']);

        DB::table('notification_preferences')->upsert([
            [
                'user_id' => $user->id,
                'in_app_enabled' => true,
                'email_enabled' => $channels->contains('email'),
                'slack_enabled' => $channels->contains('slack'),
                'daily_summary_enabled' => true,
                'report_ready_enabled' => true,
                'revision_alert_enabled' => true,
                'updated_at' => now(),
            ],
        ], ['user_id'], [
            'in_app_enabled',
            'email_enabled',
            'slack_enabled',
            'daily_summary_enabled',
            'report_ready_enabled',
            'revision_alert_enabled',
            'updated_at',
        ]);

        return $this->currentUserPayload($user->fresh() ?? $user);
    }

    public function currentUserPayload(User $user): array
    {
        $context = $this->context($user);
        $preferences = DB::table('notification_preferences')
            ->where('user_id', $user->id)
            ->first();

        return [
            'id' => (string) $context['user_id'],
            'user_code' => $this->trimCode($context['user_code']),
            'company_id' => (string) $context['company_id'],
            'company_code' => $this->trimCode($context['company_code']),
            'name' => $context['name'],
            'email' => $context['email'],
            'role' => $context['role'],
            'department' => $context['department'] ?? '',
            'job_title' => $context['job_title'] ?? '',
            'position_name' => $context['position_name'] ?? '',
            'team_name' => $context['team_name'] ?? '',
            'work_preference' => $context['work_preference'] ?? '',
            'notification_channels' => array_values(array_filter([
                ($preferences?->in_app_enabled ?? true) ? 'system' : null,
                ($preferences?->email_enabled ?? false) ? 'email' : null,
                ($preferences?->slack_enabled ?? false) ? 'slack' : null,
            ])),
            'permissions' => $this->permissions((int) $user->id),
            'is_first_login' => (bool) $context['is_first_login'],
            'wants_quick_tour' => (bool) $context['wants_quick_tour'],
        ];
    }

    protected function context(User $user): array
    {
        $row = DB::table('users as u')
            ->leftJoin('companies as c', 'c.id', '=', 'u.company_id')
            ->leftJoin('departments as d', 'd.id', '=', 'u.department_id')
            ->leftJoin('positions as p', 'p.id', '=', 'u.position_id')
            ->leftJoin('teams as t', 't.id', '=', 'u.team_id')
            ->where('u.id', $user->id)
            ->select([
                'u.id as user_id',
                'u.user_code',
                'u.company_id',
                'u.name',
                'u.email',
                'u.status',
                'u.is_first_login',
                'u.wants_quick_tour',
                'u.work_preference',
                'u.team_id',
                'c.company_code',
                'c.name as company_name',
                'd.name as department',
                'p.name as job_title',
                'p.name as position_name',
                't.name as team_name',
            ])
            ->first();

        if ($row === null || $row->company_id === null) {
            throw new RuntimeException('Kullanıcı şirket bağlamı bulunamadı.');
        }

        return [
            'user_id' => (int) $row->user_id,
            'user_code' => $row->user_code,
            'company_id' => (int) $row->company_id,
            'company_code' => $row->company_code,
            'company_name' => $row->company_name,
            'name' => $row->name,
            'email' => $row->email,
            'department' => $row->department,
            'job_title' => $row->job_title,
            'position_name' => $row->position_name,
            'team_name' => $row->team_name,
            'team_id' => $row->team_id ? (int) $row->team_id : null,
            'work_preference' => $row->work_preference,
            'is_first_login' => (bool) $row->is_first_login,
            'wants_quick_tour' => (bool) $row->wants_quick_tour,
            'role' => $this->roleForUser((int) $row->user_id),
        ];
    }

    protected function roleForUser(int $userId): string
    {
        $roles = DB::table('user_roles as ur')
            ->join('roles as r', 'r.id', '=', 'ur.role_id')
            ->where('ur.user_id', $userId)
            ->pluck('r.code')
            ->all();

        if (in_array('manager', $roles, true)) {
            return 'manager';
        }
        if (in_array('team_lead', $roles, true)) {
            return 'team_lead';
        }
        return 'employee';
    }

    protected function permissions(int $userId): array
    {
        $base = DB::table('user_roles as ur')
            ->join('role_permissions as rp', 'rp.role_id', '=', 'ur.role_id')
            ->join('permissions as p', 'p.id', '=', 'rp.permission_id')
            ->where('ur.user_id', $userId)
            ->pluck('p.code')
            ->all();

        $overrides = DB::table('user_permission_overrides as upo')
            ->join('permissions as p', 'p.id', '=', 'upo.permission_id')
            ->where('upo.user_id', $userId)
            ->get(['p.code', 'upo.is_allowed']);

        $effective = collect($base)->flip();
        foreach ($overrides as $override) {
            if ($override->is_allowed) {
                $effective[$override->code] = true;
            } else {
                $effective->forget($override->code);
            }
        }

        return $effective->keys()->values()->all();
    }

    protected function recordLoginAttempt(string $email, ?string $ipAddress, bool $isSuccess): void
    {
        DB::table('login_attempts')->insert([
            'email' => trim(Str::lower($email)),
            'ip_address' => $ipAddress,
            'is_success' => $isSuccess,
            'attempted_at' => now(),
        ]);
    }

    public function dashboard(User $user): array
    {
        $context = $this->context($user);
        $tasks = $this->scopedTaskQuery($context);
        $activeCount = (clone $tasks)->whereNotIn('ts.code', ['delivered'])->count();
        $reviewCount = (clone $tasks)->where('ts.code', 'in_review')->count();
        $overdueCount = (clone $tasks)
            ->whereNotIn('ts.code', ['delivered'])
            ->whereNotNull('t.due_at')
            ->where('t.due_at', '<', now())
            ->count();
        $deliveredCount = (clone $tasks)->where('ts.code', 'delivered')->count();
        $revisionCount = $this->scopedRevisionQuery($context)
            ->whereIn('r.status', ['pending_review', 'in_revision'])
            ->count();

        $notifications = DB::table('alerts')
            ->where('company_id', $context['company_id'])
            ->where('is_resolved', false)
            ->orderByDesc('created_at')
            ->limit(4)
            ->get()
            ->map(fn ($alert) => [
                'title' => Str::headline((string) $alert->alert_type),
                'subtitle' => $alert->message,
                'accent' => $this->severityAccent((string) $alert->severity),
            ])
            ->values()
            ->all();

        if ($notifications === []) {
            $notifications = [[
                'title' => 'Açık alarm bulunmuyor',
                'subtitle' => 'Panel için yeni bir risk sinyali yok.',
                'accent' => 'success',
            ]];
        }

        $projects = DB::table('projects')
            ->where('company_id', $context['company_id'])
            ->orderByDesc('updated_at')
            ->limit(4)
            ->get()
            ->map(function ($project) {
                $total = DB::table('tasks')->where('project_id', $project->id)->count();
                $closed = DB::table('tasks as t')
                    ->join('task_statuses as ts', 'ts.id', '=', 't.status_id')
                    ->where('t.project_id', $project->id)
                    ->where('ts.code', 'delivered')
                    ->count();

                return [
                    'name' => $project->name,
                    'type' => $project->client_name ?: ucfirst((string) $project->status),
                    'progress' => $total > 0 ? round($closed / $total, 2) : 0,
                ];
            })
            ->values()
            ->all();

        $firstName = Str::of($context['name'])->before(' ')->value();

        return [
            'title' => "Hoş geldiniz, {$firstName}",
            'subtitle' => $this->dashboardSubtitle($context['role']),
            'hero_title' => 'Workflow İş Takip Platformu',
            'hero_message' => 'Operasyon, revizyon ve ekip görünümü aynı akışta.',
            'hero_highlight' => "{$overdueCount} gecikme, {$revisionCount} revizyon",
            'summary_cards' => [
                ['label' => 'Aktif Görev', 'value' => $activeCount, 'caption' => 'Açık iş kayıtları', 'accent' => 'primary', 'icon' => 'play'],
                ['label' => 'İncelemede', 'value' => $reviewCount, 'caption' => 'Karar bekleyen teslimler', 'accent' => 'warning', 'icon' => 'review'],
                ['label' => 'Geciken', 'value' => $overdueCount, 'caption' => 'Takip gerektiren işler', 'accent' => 'danger', 'icon' => 'schedule'],
                ['label' => 'Teslim', 'value' => $deliveredCount, 'caption' => 'Tamamlanan kayıtlar', 'accent' => 'success', 'icon' => 'done'],
            ],
            'kpi_cards' => [
                ['label' => 'Açık Revizyon', 'value' => $revisionCount, 'caption' => 'Aktif revizyon çevrimi', 'accent' => 'violet', 'icon' => 'sync'],
                ['label' => 'Panel Bildirimi', 'value' => count($notifications), 'caption' => 'Anlık uyarılar', 'accent' => 'warning', 'icon' => 'timer'],
            ],
            'notifications' => $notifications,
            'focus_items' => [
                ['title' => 'Revizyon kuyruğunu temizle', 'subtitle' => "{$revisionCount} kayıt bugün işlem bekliyor.", 'badge' => 'Öncelik'],
                ['title' => 'Geciken işlere odaklan', 'subtitle' => "{$overdueCount} görev teslim tarihini geçti.", 'badge' => 'Risk'],
            ],
            'projects' => $projects,
        ];
    }

    public function tasks(User $user, array $filters = []): array
    {
        $context = $this->context($user);
        $query = $this->scopedTaskQuery($context)
            ->when($filters['q'] ?? null, function ($q, $value) {
                $q->where(function ($sub) use ($value) {
                    $sub->where('t.title', 'ilike', '%' . $value . '%')
                        ->orWhere('p.name', 'ilike', '%' . $value . '%')
                        ->orWhere('assignee.name', 'ilike', '%' . $value . '%');
                });
            })
            ->when($filters['status'] ?? null, fn ($q, $value) => $q->where('ts.code', $value))
            ->when($filters['priority'] ?? null, fn ($q, $value) => $q->where('t.priority', $value))
            ->when($filters['assignee'] ?? null, fn ($q, $value) => $q->where('assignee.name', $value))
            ->when($filters['tag'] ?? null, function ($q, $value) {
                $q->whereExists(function ($sub) use ($value) {
                    $sub->selectRaw('1')
                        ->from('task_label_links as tll')
                        ->join('task_labels as tl', 'tl.id', '=', 'tll.label_id')
                        ->whereColumn('tll.task_id', 't.id')
                        ->where('tl.name', $value);
                });
            });

        if (($filters['date_filter'] ?? null) === 'today') {
            $query->whereBetween('t.due_at', [now()->startOfDay(), now()->endOfDay()]);
        } elseif (($filters['date_filter'] ?? null) === 'this_week') {
            $query->whereBetween('t.due_at', [now()->startOfDay(), now()->endOfWeek()]);
        } elseif (($filters['date_filter'] ?? null) === 'overdue') {
            $query->where('t.due_at', '<', now());
        }

        return $query
            ->orderByRaw('CASE WHEN t.due_at IS NULL THEN 1 ELSE 0 END')
            ->orderBy('t.due_at')
            ->limit(60)
            ->get()
            ->map(fn ($task) => $this->taskPayload((int) $task->id))
            ->values()
            ->all();
    }

    public function taskMeta(User $user): array
    {
        $context = $this->context($user);
        $this->ensureTaskAssignmentAllowed($user);

        return [
            'projects' => $this->taskProjectOptions($context),
            'assignees' => $this->taskAssigneeOptions($context),
            'tag_suggestions' => $this->taskTagSuggestions($context['company_id']),
        ];
    }

    public function createTask(User $user, array $payload): array
    {
        $context = $this->context($user);
        $this->ensureTaskAssignmentAllowed($user);

        $project = $this->taskProjectQuery($context)
            ->where('p.id', (int) $payload['project_id'])
            ->select(['p.id'])
            ->firstOrFail();

        $assignee = $this->taskAssigneeQuery($context)
            ->where('u.id', (int) $payload['assignee_id'])
            ->select(['u.id'])
            ->firstOrFail();

        $statusId = $this->statusId($context['company_id'], 'pending');
        if ($statusId === null) {
            throw new RuntimeException('Task status tanimi bulunamadi.');
        }

        $taskId = DB::transaction(function () use ($context, $payload, $user, $project, $assignee, $statusId): int {
            $taskId = (int) DB::table('tasks')->insertGetId([
                'company_id' => $context['company_id'],
                'project_id' => $project->id,
                'task_no' => $this->nextTaskNo($context['company_id']),
                'title' => trim((string) $payload['title']),
                'description' => trim((string) ($payload['description'] ?? '')),
                'status_id' => $statusId,
                'priority' => $payload['priority'],
                'primary_assignee_id' => $assignee->id,
                'created_by' => $user->id,
                'due_at' => Carbon::parse($payload['due_at']),
                'estimated_minutes' => $payload['estimated_minutes'] ?? null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('task_assignments')->upsert([
                [
                    'task_id' => $taskId,
                    'user_id' => $assignee->id,
                    'assignment_type' => 'primary',
                    'assigned_by' => $user->id,
                    'assigned_at' => now(),
                ],
            ], ['task_id', 'user_id', 'assignment_type'], ['assigned_by', 'assigned_at']);

            $tag = trim((string) ($payload['tag'] ?? ''));
            if ($tag !== '') {
                $labelId = $this->findOrCreateTaskLabel($context['company_id'], $tag);
                DB::table('task_label_links')->insertOrIgnore([
                    [
                        'task_id' => $taskId,
                        'label_id' => $labelId,
                    ],
                ]);
            }

            $this->recordTaskStatusHistory($taskId, null, $statusId, (int) $user->id, 'Gorev kaydi olusturuldu.');

            return $taskId;
        });

        return $this->taskPayload($taskId);
    }

    public function startTask(User $user, string $taskId): array
    {
        $context = $this->context($user);
        $task = $this->taskRow($taskId, $context['company_id']);
        $nextStatusId = $this->statusId($context['company_id'], 'in_progress');

        DB::table('tasks')->where('id', $task->id)->update([
            'status_id' => $nextStatusId,
            'started_at' => $task->started_at ?? now(),
            'updated_at' => now(),
        ]);

        $this->recordTaskStatusHistory((int) $task->id, $task->status_id, $nextStatusId, (int) $user->id, 'Görev başlatıldı.');
        return $this->taskPayload((int) $task->id);
    }

    public function commentTask(User $user, string $taskId, string $message): array
    {
        $context = $this->context($user);
        $task = $this->taskRow($taskId, $context['company_id']);

        DB::table('task_comments')->insert([
            'task_id' => $task->id,
            'user_id' => $user->id,
            'body' => trim($message),
            'comment_type' => 'comment',
            'created_at' => now(),
        ]);

        return $this->taskPayload((int) $task->id);
    }

    public function scheduleTaskMeeting(User $user, string $taskId): array
    {
        $context = $this->context($user);
        $task = $this->taskRow($taskId, $context['company_id']);
        $slug = Str::slug($task->title . '-' . $task->id . '-' . now()->timestamp);

        DB::table('task_comments')->insert([
            'task_id' => $task->id,
            'user_id' => $user->id,
            'body' => "https://meet.jit.si/{$slug}",
            'comment_type' => 'meeting',
            'created_at' => now(),
        ]);

        return $this->taskPayload((int) $task->id);
    }

    public function submitTask(User $user, string $taskId): array
    {
        $context = $this->context($user);
        $task = $this->taskRow($taskId, $context['company_id']);
        $nextStatusId = $this->statusId($context['company_id'], 'in_review');

        DB::table('tasks')->where('id', $task->id)->update([
            'status_id' => $nextStatusId,
            'updated_at' => now(),
        ]);

        $this->recordTaskStatusHistory((int) $task->id, $task->status_id, $nextStatusId, (int) $user->id, 'Teslim incelemeye gönderildi.');
        return $this->taskPayload((int) $task->id);
    }

    public function revisions(User $user, array $filters = []): array
    {
        $context = $this->context($user);

        return $this->scopedRevisionQuery($context)
            ->when($filters['q'] ?? null, function ($q, $value) {
                $q->where(function ($sub) use ($value) {
                    $sub->where('t.title', 'ilike', '%' . $value . '%')
                        ->orWhere('p.name', 'ilike', '%' . $value . '%')
                        ->orWhere('owner.name', 'ilike', '%' . $value . '%');
                });
            })
            ->orderByDesc('r.updated_at')
            ->limit(50)
            ->get()
            ->map(fn ($revision) => $this->revisionPayload((int) $revision->id, $context['company_id']))
            ->values()
            ->all();
    }

    public function approveRevision(User $user, string $revisionId): array
    {
        $context = $this->context($user);
        $revision = $this->revisionRow($revisionId, $context['company_id']);
        $task = $this->taskRow((string) $revision->task_id, $context['company_id']);
        $deliveredStatusId = $this->statusId($context['company_id'], 'delivered');

        DB::table('approvals')->insert([
            'task_id' => $revision->task_id,
            'revision_id' => $revision->id,
            'approver_user_id' => $user->id,
            'decision' => 'approved',
            'decision_note' => 'Revizyon onaylandı.',
            'decided_at' => now(),
        ]);

        DB::table('revisions')->where('id', $revision->id)->update([
            'status' => 'completed',
            'resolved_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('tasks')->where('id', $revision->task_id)->update([
            'status_id' => $deliveredStatusId,
            'completed_at' => now(),
            'updated_at' => now(),
        ]);

        $this->recordTaskStatusHistory((int) $task->id, $task->status_id, $deliveredStatusId, (int) $user->id, 'Revizyon onaylandı ve görev kapatıldı.');
        return $this->revisionPayload((int) $revision->id, $context['company_id']);
    }

    public function requestRevision(User $user, string $revisionId, string $reason): array
    {
        $context = $this->context($user);
        $revision = $this->revisionRow($revisionId, $context['company_id']);
        $warningThreshold = (int) (DB::table('company_settings')->where('company_id', $context['company_id'])->value('revision_warning_threshold') ?? 3);
        $nextCount = (int) $revision->revision_no + 1;

        DB::table('revisions')->where('id', $revision->id)->update([
            'reason' => trim($reason),
            'status' => 'in_revision',
            'revision_no' => $nextCount,
            'is_warning_triggered' => $nextCount >= $warningThreshold,
            'updated_at' => now(),
        ]);

        DB::table('revision_messages')->insert([
            'revision_id' => $revision->id,
            'user_id' => $user->id,
            'message' => trim($reason),
            'message_type' => 'request',
            'created_at' => now(),
        ]);

        DB::table('tasks')->where('id', $revision->task_id)->update([
            'revision_count' => $nextCount,
            'updated_at' => now(),
        ]);

        return $this->revisionPayload((int) $revision->id, $context['company_id']);
    }

    public function markRevisionUpdated(User $user, string $revisionId, string $note): array
    {
        $context = $this->context($user);
        $revision = $this->revisionRow($revisionId, $context['company_id']);

        DB::table('revisions')->where('id', $revision->id)->update([
            'status' => 'pending_review',
            'updated_at' => now(),
        ]);

        DB::table('revision_messages')->insert([
            'revision_id' => $revision->id,
            'user_id' => $user->id,
            'message' => trim($note),
            'message_type' => 'employee_update',
            'created_at' => now(),
        ]);

        return $this->revisionPayload((int) $revision->id, $context['company_id']);
    }

    public function team(User $user, array $filters = []): array
    {
        $context = $this->context($user);
        $members = DB::table('users as u')
            ->leftJoin('positions as p', 'p.id', '=', 'u.position_id')
            ->where('u.company_id', $context['company_id'])
            ->when($context['role'] === 'team_lead' && $context['team_id'] !== null, fn ($q) => $q->where('u.team_id', $context['team_id']))
            ->when($filters['q'] ?? null, fn ($q, $value) => $q->where('u.name', 'ilike', '%' . $value . '%'))
            ->orderBy('u.name')
            ->get(['u.id', 'u.name', 'u.status', 'p.name as position_name'])
            ->map(function ($member) use ($context) {
                $active = DB::table('tasks as t')
                    ->leftJoin('task_statuses as ts', 'ts.id', '=', 't.status_id')
                    ->where('t.company_id', $context['company_id'])
                    ->where('t.primary_assignee_id', $member->id)
                    ->whereNotIn('ts.code', ['delivered'])
                    ->count();
                $completed = DB::table('tasks as t')
                    ->leftJoin('task_statuses as ts', 'ts.id', '=', 't.status_id')
                    ->where('t.company_id', $context['company_id'])
                    ->where('t.primary_assignee_id', $member->id)
                    ->where('ts.code', 'delivered')
                    ->count();
                $late = DB::table('tasks as t')
                    ->leftJoin('task_statuses as ts', 'ts.id', '=', 't.status_id')
                    ->where('t.company_id', $context['company_id'])
                    ->where('t.primary_assignee_id', $member->id)
                    ->whereNotIn('ts.code', ['delivered'])
                    ->where('t.due_at', '<', now())
                    ->count();
                $revision = DB::table('revisions as r')
                    ->join('tasks as t', 't.id', '=', 'r.task_id')
                    ->where('t.primary_assignee_id', $member->id)
                    ->whereIn('r.status', ['pending_review', 'in_revision'])
                    ->count();
                $lastNote = DB::table('audit_logs')
                    ->where('entity_type', 'team_member')
                    ->where('entity_id', (string) $member->id)
                    ->where('action', 'manager_note')
                    ->selectRaw("new_values_json->>'note' as last_note")
                    ->orderByDesc('created_at')
                    ->value('last_note');

                return [
                    'id' => (string) $member->id,
                    'name' => $member->name,
                    'role' => $member->position_name ?: 'Çalışan',
                    'status' => $member->status ?? 'active',
                    'active_tasks' => $active,
                    'completed_tasks' => $completed,
                    'performance_score' => max(0, min(100, 70 + ($completed * 4) - ($late * 10) - ($revision * 6))),
                    'focus_note' => $this->memberFocusNote($late, $revision, $active),
                    'risk_level' => $late > 0 || $revision >= 3 ? 'high' : ($revision > 0 || $active >= 5 ? 'medium' : 'low'),
                    'last_manager_note' => $lastNote,
                ];
            });

        if (($filters['flagged_only'] ?? null) === '1') {
            $members = $members->filter(fn ($member) => $member['risk_level'] !== 'low')->values();
        }

        return [
            'members' => $members->values()->all(),
            'corrections' => DB::table('revisions as r')
                ->join('tasks as t', 't.id', '=', 'r.task_id')
                ->leftJoin('users as owner', 'owner.id', '=', 't.primary_assignee_id')
                ->where('t.company_id', $context['company_id'])
                ->whereIn('r.status', ['pending_review', 'in_revision'])
                ->orderByDesc('r.updated_at')
                ->limit(6)
                ->get()
                ->map(fn ($item) => [
                    'id' => (string) $item->id,
                    'title' => $item->title,
                    'owner' => $item->name ?: 'Atanmamış',
                    'summary' => $item->reason,
                    'age_label' => $this->ageLabel(Carbon::parse($item->updated_at)),
                ])
                ->values()
                ->all(),
            'alerts' => DB::table('alerts as a')
                ->leftJoin('tasks as t', 't.id', '=', 'a.task_id')
                ->leftJoin('projects as p', 'p.id', '=', 't.project_id')
                ->where('a.company_id', $context['company_id'])
                ->where('a.is_resolved', false)
                ->orderByDesc('a.created_at')
                ->limit(6)
                ->get()
                ->map(fn ($alert) => [
                    'id' => (string) $alert->id,
                    'title' => Str::headline((string) $alert->alert_type),
                    'detail' => $alert->message,
                    'project' => $alert->name ?: 'Genel',
                    'risk_level' => $alert->severity === 'critical' ? 'high' : ($alert->severity === 'warning' ? 'medium' : 'low'),
                ])
                ->values()
                ->all(),
        ];
    }

    public function addManagerNote(User $user, string $memberId, string $note, ?string $ipAddress = null): void
    {
        $context = $this->context($user);

        DB::table('audit_logs')->insert([
            'company_id' => $context['company_id'],
            'user_id' => $user->id,
            'entity_type' => 'team_member',
            'entity_id' => (string) $memberId,
            'action' => 'manager_note',
            'old_values_json' => null,
            'new_values_json' => json_encode(['note' => trim($note)], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'ip_address' => $ipAddress,
            'created_at' => now(),
        ]);
    }

    public function performance(User $user, array $filters = []): array
    {
        $context = $this->context($user);
        $range = $filters['range'] ?? 'last_30_days';
        $start = $range === 'last_6_months' ? now()->subMonths(5)->startOfMonth() : now()->subDays(29)->startOfDay();
        $end = now()->endOfDay();

        $tasks = $this->scopedTaskQuery($context)
            ->whereBetween('t.updated_at', [$start, $end])
            ->get();

        $completed = $tasks->where('status_code', 'delivered')->count();
        $late = $tasks->filter(fn ($task) => $task->due_at !== null && Carbon::parse($task->due_at)->lt(now()) && $task->status_code !== 'delivered')->count();
        $avgRevision = round((float) $tasks->avg('revision_count'), 1);
        $avgQuality = (int) round((float) $tasks->filter(fn ($task) => $task->quality_score !== null)->avg('quality_score'));

        $trendPoints = collect();
        if ($range === 'last_6_months') {
            foreach (range(5, 0) as $index) {
                $cursor = now()->subMonths($index);
                $periodTasks = $this->scopedTaskQuery($context)
                    ->whereBetween('t.updated_at', [$cursor->copy()->startOfMonth(), $cursor->copy()->endOfMonth()])
                    ->get();
                $trendPoints->push([
                    'label' => $cursor->format('M'),
                    'score' => $this->performanceScoreFromTasks($periodTasks),
                    'target' => 82,
                ]);
            }
        } else {
            foreach (range(3, 0) as $index) {
                $periodStart = now()->subWeeks($index)->startOfWeek();
                $periodEnd = now()->subWeeks($index)->endOfWeek();
                $trendPoints->push([
                    'label' => 'H' . (4 - $index),
                    'score' => $this->performanceScoreFromTasks(
                        $this->scopedTaskQuery($context)->whereBetween('t.updated_at', [$periodStart, $periodEnd])->get()
                    ),
                    'target' => 80,
                ]);
            }
        }

        return [
            'metrics' => [
                ['label' => 'Tamamlanan', 'value' => $completed, 'caption' => 'Seçili aralıkta kapanan görev'],
                ['label' => 'Geciken', 'value' => $late, 'caption' => 'Teslim riski taşıyan iş'],
                ['label' => 'Ort. Revizyon', 'value' => $avgRevision, 'caption' => 'Görev başına revizyon'],
                ['label' => 'Kalite', 'value' => $avgQuality, 'caption' => 'Ortalama kalite skoru'],
            ],
            'trend_points' => $trendPoints->all(),
            'rows' => $this->scopedTaskQuery($context)
                ->whereNotNull('t.completed_at')
                ->orderByDesc('t.completed_at')
                ->limit(8)
                ->get()
                ->map(fn ($task) => [
                    'task_title' => $task->title,
                    'owner' => $task->assignee_name ?: 'Atanmamış',
                    'completed_at' => Carbon::parse($task->completed_at)->format('d.m.Y H:i'),
                    'revision_count' => (int) $task->revision_count,
                    'quality_score' => (int) ($task->quality_score ?? 0),
                    'duration_label' => $this->durationLabel($task->actual_minutes, $task->estimated_minutes),
                    'status_label' => $task->status_name ?: 'Belirsiz',
                ])
                ->values()
                ->all(),
        ];
    }

    public function reports(User $user, array $filters = []): array
    {
        $context = $this->context($user);

        return [
            'metrics' => [
                ['label' => 'Rapor Çalıştırma', 'value' => DB::table('report_runs')->where('company_id', $context['company_id'])->count(), 'caption' => 'Toplam rapor üretimi'],
                ['label' => 'Hazır', 'value' => DB::table('report_runs')->where('company_id', $context['company_id'])->where('status', 'ready')->count(), 'caption' => 'İndirilebilir rapor'],
                ['label' => 'Takım', 'value' => DB::table('teams')->where('company_id', $context['company_id'])->count(), 'caption' => 'Raporlanabilir ekip'],
                ['label' => 'Kullanıcı', 'value' => DB::table('users')->where('company_id', $context['company_id'])->count(), 'caption' => 'Seçilebilir çalışan'],
            ],
            'status_counts' => DB::table('tasks as t')
                ->join('task_statuses as ts', 'ts.id', '=', 't.status_id')
                ->where('t.company_id', $context['company_id'])
                ->selectRaw('ts.name as label, count(*) as count, ts.sort_order')
                ->groupBy('ts.name', 'ts.sort_order')
                ->orderBy('ts.sort_order')
                ->get()
                ->map(fn ($row) => ['label' => $row->label, 'count' => (int) $row->count])
                ->values()
                ->all(),
            'activities' => DB::table('report_runs')
                ->where('company_id', $context['company_id'])
                ->orderByDesc('created_at')
                ->limit(6)
                ->get()
                ->map(fn ($run) => [
                    'title' => Str::headline((string) $run->report_type) . ' raporu üretildi',
                    'subtitle' => Carbon::parse($run->created_at)->diffForHumans(),
                ])
                ->values()
                ->all(),
            'team_options' => DB::table('teams')->where('company_id', $context['company_id'])->orderBy('name')->pluck('name')->all(),
            'user_options' => DB::table('users')->where('company_id', $context['company_id'])->orderBy('name')->pluck('name')->all(),
            'runs' => DB::table('report_runs')
                ->where('company_id', $context['company_id'])
                ->when($filters['type'] ?? null, fn ($q, $value) => $q->where('report_type', $value))
                ->orderByDesc('created_at')
                ->limit(8)
                ->get()
                ->map(fn ($run) => [
                    'id' => (string) $run->id,
                    'title' => Str::headline((string) $run->report_type) . ' Raporu',
                    'scope' => $run->scope_label,
                    'format' => $run->format,
                    'created_at_label' => Carbon::parse($run->created_at)->format('d.m.Y H:i'),
                    'status' => $run->status,
                ])
                ->values()
                ->all(),
        ];
    }

    public function createReport(User $user, array $payload): array
    {
        $context = $this->context($user);

        $id = DB::table('report_runs')->insertGetId([
            'company_id' => $context['company_id'],
            'template_id' => null,
            'requested_by' => $context['user_id'],
            'report_type' => $payload['type'],
            'scope_label' => $payload['scope'],
            'format' => $payload['format'],
            'status' => 'ready',
            'file_path' => null,
            'emailed_to' => null,
            'created_at' => now(),
            'completed_at' => now(),
        ]);

        $run = DB::table('report_runs')->where('id', $id)->first();

        return [
            'id' => (string) $run->id,
            'title' => Str::headline((string) $run->report_type) . ' Raporu',
            'scope' => $run->scope_label,
            'format' => $run->format,
            'created_at_label' => Carbon::parse($run->created_at)->format('d.m.Y H:i'),
            'status' => $run->status,
        ];
    }

    public function generalSettings(User $user): array
    {
        $context = $this->context($user);
        $settings = $this->settingsMap($context['company_id']);

        return [
            'company_name' => $context['company_name'],
            'company_code' => $this->trimCode($context['company_code']),
            'default_language' => $settings['default_language'] ?? 'tr',
            'timezone' => $settings['timezone'] ?? 'Europe/Istanbul',
            'week_starts_on' => $settings['week_starts_on'] ?? 'monday',
            'date_format' => $settings['date_format'] ?? 'dd.MM.yyyy',
            'notification_summary_enabled' => (bool) ($settings['notification_summary_enabled'] ?? true),
            'email_notifications_enabled' => (bool) ($settings['email_notifications_enabled'] ?? true),
            'slack_notifications_enabled' => (bool) ($settings['slack_notifications_enabled'] ?? false),
        ];
    }

    public function saveGeneralSettings(User $user, array $payload): array
    {
        $context = $this->context($user);

        DB::table('companies')->where('id', $context['company_id'])->update([
            'name' => $payload['company_name'],
            'timezone' => $payload['timezone'],
            'locale' => $payload['default_language'],
            'updated_at' => now(),
        ]);

        $this->upsertSystemSetting($context['company_id'], 'default_language', $payload['default_language']);
        $this->upsertSystemSetting($context['company_id'], 'timezone', $payload['timezone']);
        $this->upsertSystemSetting($context['company_id'], 'week_starts_on', $payload['week_starts_on']);
        $this->upsertSystemSetting($context['company_id'], 'date_format', $payload['date_format']);
        $this->upsertSystemSetting($context['company_id'], 'notification_summary_enabled', $payload['notification_summary_enabled'] ? '1' : '0');
        $this->upsertSystemSetting($context['company_id'], 'email_notifications_enabled', $payload['email_notifications_enabled'] ? '1' : '0');
        $this->upsertSystemSetting($context['company_id'], 'slack_notifications_enabled', $payload['slack_notifications_enabled'] ? '1' : '0');

        DB::table('company_settings')->upsert([
            [
                'company_id' => $context['company_id'],
                'allow_email_reports' => (bool) $payload['email_notifications_enabled'],
                'allow_slack_reports' => (bool) $payload['slack_notifications_enabled'],
                'updated_at' => now(),
            ],
        ], ['company_id'], ['allow_email_reports', 'allow_slack_reports', 'updated_at']);

        return $this->generalSettings($user);
    }

    public function helpCenter(User $user, array $filters = []): array
    {
        $context = $this->context($user);
        $settings = $this->settingsMap($context['company_id']);

        return [
            'contact_email' => $settings['support_email'] ?? 'kodver@gudeteknoloji.com.tr',
            'response_sla' => $settings['response_sla'] ?? '4 iş saati',
            'articles' => DB::table('help_articles')
                ->where(function ($q) use ($context) {
                    $q->where('company_id', $context['company_id'])
                        ->orWhereNull('company_id');
                })
                ->where('status', 'published')
                ->when($filters['q'] ?? null, function ($q, $value) {
                    $q->where(function ($sub) use ($value) {
                        $sub->where('title', 'ilike', '%' . $value . '%')
                            ->orWhere('category', 'ilike', '%' . $value . '%')
                            ->orWhere('summary', 'ilike', '%' . $value . '%');
                    });
                })
                ->orderBy('category')
                ->orderBy('title')
                ->limit(24)
                ->get()
                ->map(fn ($article) => [
                    'id' => (string) $article->id,
                    'title' => $article->title,
                    'category' => $article->category,
                    'summary' => $article->summary ?? '',
                ])
                ->values()
                ->all(),
        ];
    }

    protected function settingsMap(int $companyId): array
    {
        return DB::table('system_settings')
            ->where('company_id', $companyId)
            ->pluck('setting_value', 'setting_key')
            ->map(function ($value) {
                if ($value === '1') {
                    return true;
                }
                if ($value === '0') {
                    return false;
                }
                return $value;
            })
            ->all();
    }

    protected function scopedTaskQuery(array $context)
    {
        $query = DB::table('tasks as t')
            ->leftJoin('projects as p', 'p.id', '=', 't.project_id')
            ->leftJoin('users as assignee', 'assignee.id', '=', 't.primary_assignee_id')
            ->leftJoin('task_statuses as ts', 'ts.id', '=', 't.status_id')
            ->where('t.company_id', $context['company_id'])
            ->select([
                't.id',
                't.project_id',
                't.title',
                't.description',
                't.priority',
                't.status_id',
                't.primary_assignee_id',
                't.due_at',
                't.updated_at',
                't.started_at',
                't.completed_at',
                't.actual_minutes',
                't.estimated_minutes',
                't.quality_score',
                't.revision_count',
                'p.name as project_name',
                'assignee.name as assignee_name',
                'ts.name as status_name',
                'ts.code as status_code',
            ]);

        if ($context['role'] === 'employee') {
            $query->where('t.primary_assignee_id', $context['user_id']);
        } elseif ($context['role'] === 'team_lead' && $context['team_id'] !== null) {
            $query->whereIn('t.primary_assignee_id', function ($sub) use ($context) {
                $sub->select('id')->from('users')->where('team_id', $context['team_id']);
            });
        }

        return $query;
    }

    protected function scopedRevisionQuery(array $context)
    {
        $query = DB::table('revisions as r')
            ->join('tasks as t', 't.id', '=', 'r.task_id')
            ->leftJoin('projects as p', 'p.id', '=', 't.project_id')
            ->leftJoin('users as owner', 'owner.id', '=', 't.primary_assignee_id')
            ->where('t.company_id', $context['company_id'])
            ->select([
                'r.id',
                'r.task_id',
                'r.revision_no',
                'r.reason',
                'r.status',
                'r.is_warning_triggered',
                'r.updated_at',
                't.title',
                'p.name as project_name',
                'owner.name as owner_name',
            ]);

        if ($context['role'] === 'employee') {
            $query->where('t.primary_assignee_id', $context['user_id']);
        } elseif ($context['role'] === 'team_lead' && $context['team_id'] !== null) {
            $query->whereIn('t.primary_assignee_id', function ($sub) use ($context) {
                $sub->select('id')->from('users')->where('team_id', $context['team_id']);
            });
        }

        return $query;
    }

    protected function taskProjectQuery(array $context)
    {
        $query = DB::table('projects as p')
            ->where('p.company_id', $context['company_id'])
            ->where('p.status', 'active');

        if ($context['role'] === 'team_lead') {
            if ($context['team_id'] === null) {
                $query->whereRaw('1 = 0');
            } else {
                $query->where('p.team_id', $context['team_id']);
            }
        } elseif ($context['role'] === 'employee') {
            $query->whereRaw('1 = 0');
        }

        return $query;
    }

    protected function taskAssigneeQuery(array $context)
    {
        $query = DB::table('users as u')
            ->where('u.company_id', $context['company_id'])
            ->where('u.status', 'active');

        if ($context['role'] === 'team_lead') {
            if ($context['team_id'] === null) {
                $query->whereRaw('1 = 0');
            } else {
                $query->where('u.team_id', $context['team_id']);
            }
        } elseif ($context['role'] === 'employee') {
            $query->whereRaw('1 = 0');
        }

        return $query;
    }

    protected function taskProjectOptions(array $context): array
    {
        return $this->taskProjectQuery($context)
            ->orderBy('p.name')
            ->get(['p.id', 'p.name'])
            ->map(fn ($project) => [
                'id' => (string) $project->id,
                'label' => $project->name,
            ])
            ->values()
            ->all();
    }

    protected function taskAssigneeOptions(array $context): array
    {
        return $this->taskAssigneeQuery($context)
            ->orderBy('u.name')
            ->get(['u.id', 'u.name'])
            ->map(fn ($assignee) => [
                'id' => (string) $assignee->id,
                'label' => $assignee->name,
            ])
            ->values()
            ->all();
    }

    protected function taskTagSuggestions(int $companyId): array
    {
        return DB::table('task_labels as tl')
            ->leftJoin('task_label_links as tll', 'tll.label_id', '=', 'tl.id')
            ->where('tl.company_id', $companyId)
            ->groupBy('tl.id', 'tl.name')
            ->orderByRaw('COUNT(tll.id) DESC')
            ->orderBy('tl.name')
            ->limit(12)
            ->pluck('tl.name')
            ->values()
            ->all();
    }

    protected function ensureTaskAssignmentAllowed(User $user): void
    {
        if (!$this->userHasPermission((int) $user->id, 'tasks.assign')) {
            throw new AuthorizationException('Bu kullanicinin gorev olusturma yetkisi yok.');
        }
    }

    protected function userHasPermission(int $userId, string $code): bool
    {
        return in_array($code, $this->permissions($userId), true);
    }

    protected function nextTaskNo(int $companyId): string
    {
        $max = 0;
        foreach (DB::table('tasks')->where('company_id', $companyId)->lockForUpdate()->pluck('task_no') as $taskNo) {
            if (preg_match('/(\d+)$/', (string) $taskNo, $matches) === 1) {
                $max = max($max, (int) $matches[1]);
            }
        }

        return 'T-' . str_pad((string) ($max + 1), 4, '0', STR_PAD_LEFT);
    }

    protected function findOrCreateTaskLabel(int $companyId, string $name): int
    {
        $labelId = DB::table('task_labels')
            ->where('company_id', $companyId)
            ->whereRaw('LOWER(name) = ?', [Str::lower($name)])
            ->value('id');

        if ($labelId !== null) {
            return (int) $labelId;
        }

        return (int) DB::table('task_labels')->insertGetId([
            'company_id' => $companyId,
            'name' => $name,
            'created_at' => now(),
        ]);
    }

    protected function taskRow(string $taskId, int $companyId): object
    {
        return DB::table('tasks')
            ->where('id', $taskId)
            ->where('company_id', $companyId)
            ->firstOrFail();
    }

    protected function revisionRow(string $revisionId, int $companyId): object
    {
        return DB::table('revisions as r')
            ->join('tasks as t', 't.id', '=', 'r.task_id')
            ->where('r.id', $revisionId)
            ->where('t.company_id', $companyId)
            ->select('r.*')
            ->firstOrFail();
    }

    protected function taskPayload(int $taskId): array
    {
        $task = DB::table('tasks as t')
            ->leftJoin('projects as p', 'p.id', '=', 't.project_id')
            ->leftJoin('users as assignee', 'assignee.id', '=', 't.primary_assignee_id')
            ->leftJoin('task_statuses as ts', 'ts.id', '=', 't.status_id')
            ->where('t.id', $taskId)
            ->select([
                't.id',
                't.title',
                't.description',
                't.priority',
                't.due_at',
                't.updated_at',
                't.estimated_minutes',
                't.actual_minutes',
                'p.name as project_name',
                'assignee.name as assignee_name',
                'ts.code as status_code',
            ])
            ->firstOrFail();

        $label = DB::table('task_label_links as tll')
            ->join('task_labels as tl', 'tl.id', '=', 'tll.label_id')
            ->where('tll.task_id', $taskId)
            ->orderBy('tl.name')
            ->value('tl.name');

        $meetingLink = DB::table('task_comments')
            ->where('task_id', $taskId)
            ->where('comment_type', 'meeting')
            ->orderByDesc('created_at')
            ->value('body');

        $trackedMinutes = DB::table('task_time_logs')
            ->where('task_id', $taskId)
            ->sum('duration_minutes');

        $dependencies = DB::table('task_dependencies as td')
            ->join('tasks as predecessor', 'predecessor.id', '=', 'td.predecessor_task_id')
            ->leftJoin('task_statuses as pts', 'pts.id', '=', 'predecessor.status_id')
            ->where('td.successor_task_id', $taskId)
            ->orderBy('predecessor.title')
            ->get([
                'predecessor.title',
                'pts.name as status_name',
            ])
            ->map(fn ($item) => [
                'title' => $item->title,
                'status_label' => $item->status_name ?? 'Belirsiz',
            ])
            ->values()
            ->all();

        $timeEntries = DB::table('task_time_logs as ttl')
            ->leftJoin('users as u', 'u.id', '=', 'ttl.user_id')
            ->where('ttl.task_id', $taskId)
            ->orderByDesc('ttl.started_at')
            ->limit(5)
            ->get([
                'u.name',
                'ttl.duration_minutes',
                'ttl.started_at',
            ])
            ->map(fn ($item) => [
                'user_name' => $item->name ?? 'Sistem',
                'duration_label' => $this->durationLabel($item->duration_minutes, null),
                'started_at_label' => $this->ageLabel(Carbon::parse($item->started_at)) . ' once',
            ])
            ->values()
            ->all();

        $requestSource = DB::table('request_submissions as rs')
            ->leftJoin('request_forms as rf', 'rf.id', '=', 'rs.request_form_id')
            ->where('rs.task_id', $taskId)
            ->orderByDesc('rs.created_at')
            ->value('rf.name');

        return [
            'id' => (string) $task->id,
            'title' => $task->title,
            'project' => $task->project_name ?? 'Proje Yok',
            'assignee' => $task->assignee_name ?? 'Atanmamış',
            'status' => $task->status_code ?? 'pending',
            'priority' => $task->priority ?? 'medium',
            'due_at' => $this->iso($task->due_at),
            'updated_at' => $this->iso($task->updated_at),
            'tag' => $label ?? 'Genel',
            'description' => $task->description ?? '',
            'checklist_completed' => DB::table('task_checklists')->where('task_id', $taskId)->where('is_completed', true)->count(),
            'checklist_total' => DB::table('task_checklists')->where('task_id', $taskId)->count(),
            'estimated_minutes' => (int) ($task->estimated_minutes ?? 0),
            'tracked_minutes' => (int) ($trackedMinutes ?: ($task->actual_minutes ?? 0)),
            'blocked_by_count' => DB::table('task_dependencies')->where('successor_task_id', $taskId)->count(),
            'subtask_count' => DB::table('tasks')->where('parent_task_id', $taskId)->count(),
            'dependencies' => $dependencies,
            'time_entries' => $timeEntries,
            'meeting_link' => $meetingLink,
            'request_source' => $requestSource,
            'timeline' => $this->taskTimeline($taskId),
        ];
    }

    protected function taskTimeline(int $taskId): array
    {
        $statusItems = DB::table('task_status_history as h')
            ->leftJoin('users as u', 'u.id', '=', 'h.changed_by')
            ->leftJoin('task_statuses as fs', 'fs.id', '=', 'h.from_status_id')
            ->leftJoin('task_statuses as ts', 'ts.id', '=', 'h.to_status_id')
            ->where('h.task_id', $taskId)
            ->get()
            ->map(fn ($item) => [
                'title' => 'Durum güncellendi',
                'detail' => $item->note ?: trim(($item->fs ?? 'Başlangıç') . ' → ' . ($item->ts ?? 'Belirsiz')),
                'actor' => $item->name ?: 'Sistem',
                'timestamp' => $this->iso($item->created_at),
            ]);

        $commentItems = DB::table('task_comments as c')
            ->leftJoin('users as u', 'u.id', '=', 'c.user_id')
            ->where('c.task_id', $taskId)
            ->get()
            ->map(fn ($item) => [
                'title' => $item->comment_type === 'meeting' ? 'Toplantı planlandı' : 'Yorum eklendi',
                'detail' => $item->body,
                'actor' => $item->name ?: 'Sistem',
                'timestamp' => $this->iso($item->created_at),
            ]);

        return $statusItems->merge($commentItems)->sortByDesc('timestamp')->values()->all();
    }

    protected function revisionPayload(int $revisionId, int $companyId): array
    {
        $revision = DB::table('revisions as r')
            ->join('tasks as t', 't.id', '=', 'r.task_id')
            ->leftJoin('projects as p', 'p.id', '=', 't.project_id')
            ->leftJoin('users as owner', 'owner.id', '=', 't.primary_assignee_id')
            ->where('r.id', $revisionId)
            ->where('t.company_id', $companyId)
            ->select([
                'r.id',
                'r.revision_no',
                'r.reason',
                'r.status',
                'r.is_warning_triggered',
                'r.updated_at',
                't.title',
                't.quality_score',
                'p.name as project_name',
                'owner.name as owner_name',
            ])
            ->firstOrFail();

        $histories = collect([[
            'title' => 'Revizyon kaydı',
            'detail' => $revision->reason,
            'actor' => $revision->owner_name ?: 'Sistem',
            'timestamp' => $this->iso($revision->updated_at),
        ]])->merge(
            DB::table('revision_messages as rm')
                ->leftJoin('users as u', 'u.id', '=', 'rm.user_id')
                ->where('rm.revision_id', $revisionId)
                ->get()
                ->map(fn ($item) => [
                    'title' => $item->message_type === 'employee_update' ? 'Çalışan güncellemesi' : 'Revizyon notu',
                    'detail' => $item->message,
                    'actor' => $item->name ?: 'Sistem',
                    'timestamp' => $this->iso($item->created_at),
                ])
        )->merge(
            DB::table('approvals as a')
                ->leftJoin('users as u', 'u.id', '=', 'a.approver_user_id')
                ->where('a.revision_id', $revisionId)
                ->get()
                ->map(fn ($item) => [
                    'title' => $item->decision === 'approved' ? 'Onay verildi' : 'Karar kaydı',
                    'detail' => $item->decision_note ?: 'Karar işlendi.',
                    'actor' => $item->name ?: 'Yönetici',
                    'timestamp' => $this->iso($item->decided_at),
                ])
        )->sortByDesc('timestamp')->values()->all();

        return [
            'id' => (string) $revision->id,
            'title' => $revision->title,
            'project' => $revision->project_name ?? 'Proje Yok',
            'owner' => $revision->owner_name ?? 'Atanmamış',
            'stage' => $this->revisionStage((string) $revision->status),
            'revision_count' => (int) $revision->revision_no,
            'updated_at' => $this->iso($revision->updated_at),
            'category' => ((int) $revision->revision_no) >= 3 ? 'Kritik revizyon' : 'Kalite kontrol',
            'summary' => Str::limit($revision->reason, 110),
            'revision_reason' => $revision->reason,
            'early_warning' => (bool) $revision->is_warning_triggered,
            'performance_ready' => ((int) ($revision->quality_score ?? 0)) >= 80,
            'histories' => $histories,
        ];
    }

    protected function statusId(int $companyId, string $code): ?int
    {
        $value = DB::table('task_statuses')
            ->where('company_id', $companyId)
            ->where('code', $code)
            ->value('id');

        return $value !== null ? (int) $value : null;
    }

    protected function recordTaskStatusHistory(int $taskId, ?int $fromStatusId, ?int $toStatusId, int $userId, string $note): void
    {
        DB::table('task_status_history')->insert([
            'task_id' => $taskId,
            'from_status_id' => $fromStatusId,
            'to_status_id' => $toStatusId,
            'changed_by' => $userId,
            'note' => $note,
            'created_at' => now(),
        ]);
    }

    protected function findOrCreateDepartment(int $companyId, string $name): int
    {
        $code = Str::slug($name, '_');
        $existing = DB::table('departments')->where('company_id', $companyId)->where('code', $code)->value('id');
        if ($existing !== null) {
            return (int) $existing;
        }

        return (int) DB::table('departments')->insertGetId([
            'company_id' => $companyId,
            'name' => $name,
            'code' => $code,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    protected function findOrCreatePosition(int $companyId, string $name): int
    {
        $code = Str::slug($name, '_');
        $existing = DB::table('positions')->where('company_id', $companyId)->where('code', $code)->value('id');
        if ($existing !== null) {
            return (int) $existing;
        }

        return (int) DB::table('positions')->insertGetId([
            'company_id' => $companyId,
            'name' => $name,
            'code' => $code,
            'level' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    protected function upsertSystemSetting(int $companyId, string $key, string $value): void
    {
        DB::table('system_settings')->upsert([
            [
                'company_id' => $companyId,
                'setting_key' => $key,
                'setting_value' => $value,
                'updated_at' => now(),
            ],
        ], ['company_id', 'setting_key'], ['setting_value', 'updated_at']);
    }

    protected function memberFocusNote(int $lateCount, int $revisionCount, int $activeTasks): string
    {
        if ($lateCount > 0) {
            return 'Geciken işler nedeniyle yakın takip gerekiyor.';
        }
        if ($revisionCount > 0) {
            return 'Revizyon geri dönüşleri için odak süresi ayrılmalı.';
        }
        if ($activeTasks >= 5) {
            return 'Yük dengesi artıyor, planlamayı gözden geçir.';
        }
        return 'İş yükü dengeli ilerliyor.';
    }

    protected function revisionStage(string $status): string
    {
        return match ($status) {
            'in_revision' => 'in_revision',
            'completed' => 'completed',
            default => 'pending_review',
        };
    }

    protected function ageLabel(Carbon $timestamp): string
    {
        $hours = (int) $timestamp->diffInHours(now());
        if ($hours < 24) {
            return "{$hours} saat";
        }
        return $timestamp->diffInDays(now()) . ' gün';
    }

    protected function durationLabel(?int $actualMinutes, ?int $estimatedMinutes): string
    {
        if ($actualMinutes !== null && $actualMinutes > 0) {
            return $actualMinutes . ' dk';
        }
        if ($estimatedMinutes !== null && $estimatedMinutes > 0) {
            return 'Plan ' . $estimatedMinutes . ' dk';
        }
        return 'Süre kaydı yok';
    }

    protected function performanceScoreFromTasks(Collection $tasks): float
    {
        $completed = $tasks->where('status_code', 'delivered')->count();
        $late = $tasks->filter(fn ($task) => $task->due_at !== null && Carbon::parse($task->due_at)->lt(now()) && $task->status_code !== 'delivered')->count();
        $avgQuality = (float) $tasks->filter(fn ($task) => $task->quality_score !== null)->avg('quality_score');

        return round(max(0, min(100, 55 + ($completed * 5) - ($late * 10) + ($avgQuality * 0.25))), 1);
    }

    protected function severityAccent(string $severity): string
    {
        return match ($severity) {
            'critical' => 'danger',
            'warning' => 'warning',
            default => 'success',
        };
    }

    protected function dashboardSubtitle(string $role): string
    {
        return match ($role) {
            'manager' => 'Operasyon, ekip yükü, revizyon kuyruğu ve öncelikler tek görünümde.',
            'team_lead' => 'Ekibinin aktif görevleri, riskleri ve geri bildirim akışı burada.',
            default => 'Günlük görevlerin, revizyonların ve kişisel görünümün burada.',
        };
    }

    protected function iso(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }
        return Carbon::parse($value)->toIso8601String();
    }

    protected function trimCode(mixed $value): string
    {
        return trim((string) $value);
    }
}
