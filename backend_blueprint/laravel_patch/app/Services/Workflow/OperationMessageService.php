<?php

namespace App\Services\Workflow;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class OperationMessageService
{
    public function inbox(User $user): array
    {
        $context = $this->context($user);
        $this->ensureMessagingAllowed($context);

        $threads = collect($this->threadIdsForUser($context['company_id'], $context['user_id']))
            ->map(fn (int $threadId) => $this->threadSummaryPayload($context, $threadId))
            ->values()
            ->all();

        return [
            'threads' => $threads,
            'contacts' => $this->contactOptions($context),
            'poll_interval_seconds' => 8,
        ];
    }

    public function openThread(User $user, int $counterpartUserId): array
    {
        $context = $this->context($user);
        $this->ensureMessagingAllowed($context);
        $counterpart = $this->allowedCounterpart($context, $counterpartUserId);

        $threadId = DB::transaction(function () use ($context, $counterpart): int {
            $conversationKey = $this->directConversationKey($context['user_id'], (int) $counterpart->id);
            $existing = DB::table('operation_threads')
                ->where('company_id', $context['company_id'])
                ->where('conversation_key', $conversationKey)
                ->value('id');

            if ($existing !== null) {
                $threadId = (int) $existing;
            } else {
                $threadId = (int) DB::table('operation_threads')->insertGetId([
                    'company_id' => $context['company_id'],
                    'task_id' => null,
                    'thread_type' => 'direct',
                    'conversation_key' => $conversationKey,
                    'title' => $this->threadTitle($context, $counterpart),
                    'created_by' => $context['user_id'],
                    'last_message_at' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            DB::table('operation_thread_participants')->insertOrIgnore([
                [
                    'thread_id' => $threadId,
                    'user_id' => $context['user_id'],
                    'joined_at' => now(),
                ],
                [
                    'thread_id' => $threadId,
                    'user_id' => (int) $counterpart->id,
                    'joined_at' => now(),
                ],
            ]);

            return $threadId;
        });

        $this->markThreadAsRead($context['user_id'], $threadId);
        return $this->threadPayload($context, $threadId);
    }

    public function thread(User $user, int $threadId): array
    {
        $context = $this->context($user);
        $this->ensureMessagingAllowed($context);
        $this->participantThreadRow($context, $threadId);
        $this->markThreadAsRead($context['user_id'], $threadId);

        return $this->threadPayload($context, $threadId);
    }

    public function sendMessage(User $user, int $threadId, string $body): array
    {
        $context = $this->context($user);
        $this->ensureMessagingAllowed($context);
        $thread = $this->participantThreadRow($context, $threadId);
        $normalizedBody = trim($body);
        if ($normalizedBody === '') {
            throw new RuntimeException('Mesaj boş olamaz.');
        }

        $messageId = (int) DB::table('operation_thread_messages')->insertGetId([
            'thread_id' => $thread->id,
            'sender_user_id' => $context['user_id'],
            'body' => $normalizedBody,
            'created_at' => now(),
        ]);

        DB::table('operation_threads')->where('id', $thread->id)->update([
            'last_message_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('operation_thread_reads')->updateOrInsert(
            [
                'thread_id' => $thread->id,
                'user_id' => $context['user_id'],
            ],
            [
                'last_read_message_id' => $messageId,
                'last_read_at' => now(),
            ]
        );

        return $this->threadPayload($context, (int) $thread->id);
    }

    public function markRead(User $user, int $threadId): array
    {
        $context = $this->context($user);
        $this->ensureMessagingAllowed($context);
        $this->participantThreadRow($context, $threadId);
        $this->markThreadAsRead($context['user_id'], $threadId);

        return [
            'thread_id' => (string) $threadId,
            'unread_count' => 0,
        ];
    }

    protected function context(User $user): array
    {
        $row = DB::table('users as u')
            ->leftJoin('companies as c', 'c.id', '=', 'u.company_id')
            ->leftJoin('teams as t', 't.id', '=', 'u.team_id')
            ->where('u.id', $user->id)
            ->select([
                'u.id as user_id',
                'u.company_id',
                'u.team_id',
                'u.name',
                'u.email',
                'c.name as company_name',
                't.name as team_name',
            ])
            ->first();

        if ($row === null || $row->company_id === null) {
            throw new RuntimeException('Kullanıcı şirket bağlamı bulunamadı.');
        }

        return [
            'user_id' => (int) $row->user_id,
            'company_id' => (int) $row->company_id,
            'company_name' => $row->company_name ?? '',
            'team_id' => $row->team_id !== null ? (int) $row->team_id : null,
            'team_name' => $row->team_name ?? '',
            'name' => $row->name ?? '',
            'email' => $row->email ?? '',
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

    protected function ensureMessagingAllowed(array $context): void
    {
        if (!in_array($context['role'], ['manager', 'team_lead'], true)) {
            throw new AuthorizationException('Operasyon mesaj docku yalnızca yönetici ve ekip lideri rollerinde açık.');
        }
    }

    protected function participantThreadRow(array $context, int $threadId): object
    {
        return DB::table('operation_threads as ot')
            ->join('operation_thread_participants as otp', 'otp.thread_id', '=', 'ot.id')
            ->where('ot.company_id', $context['company_id'])
            ->where('ot.id', $threadId)
            ->where('otp.user_id', $context['user_id'])
            ->select(['ot.id', 'ot.title', 'ot.last_message_at', 'ot.updated_at'])
            ->firstOrFail();
    }

    protected function threadIdsForUser(int $companyId, int $userId): array
    {
        return DB::table('operation_threads as ot')
            ->join('operation_thread_participants as otp', 'otp.thread_id', '=', 'ot.id')
            ->where('ot.company_id', $companyId)
            ->where('otp.user_id', $userId)
            ->orderByRaw('COALESCE(ot.last_message_at, ot.updated_at) DESC')
            ->pluck('ot.id')
            ->map(fn ($value) => (int) $value)
            ->all();
    }

    protected function contactOptions(array $context): array
    {
        $targetRole = $context['role'] === 'manager' ? 'team_lead' : 'manager';

        return DB::table('users as u')
            ->join('user_roles as ur', 'ur.user_id', '=', 'u.id')
            ->join('roles as r', 'r.id', '=', 'ur.role_id')
            ->leftJoin('teams as t', 't.id', '=', 'u.team_id')
            ->where('u.company_id', $context['company_id'])
            ->where('u.status', 'active')
            ->where('r.code', $targetRole)
            ->where('u.id', '<>', $context['user_id'])
            ->orderBy('u.name')
            ->get([
                'u.id',
                'u.name',
                'u.email',
                't.name as team_name',
                'r.code as role_code',
            ])
            ->unique('id')
            ->map(fn ($contact) => [
                'id' => (string) $contact->id,
                'name' => $contact->name,
                'email' => $contact->email,
                'team_name' => $contact->team_name,
                'role_code' => $contact->role_code,
                'role_label' => $this->roleLabelFromCode((string) $contact->role_code),
            ])
            ->values()
            ->all();
    }

    protected function allowedCounterpart(array $context, int $counterpartUserId): object
    {
        $targetRole = $context['role'] === 'manager' ? 'team_lead' : 'manager';

        $counterpart = DB::table('users as u')
            ->join('user_roles as ur', 'ur.user_id', '=', 'u.id')
            ->join('roles as r', 'r.id', '=', 'ur.role_id')
            ->leftJoin('teams as t', 't.id', '=', 'u.team_id')
            ->where('u.company_id', $context['company_id'])
            ->where('u.status', 'active')
            ->where('u.id', $counterpartUserId)
            ->where('r.code', $targetRole)
            ->select([
                'u.id',
                'u.name',
                'u.email',
                't.name as team_name',
                'r.code as role_code',
            ])
            ->first();

        if ($counterpart === null) {
            throw new RuntimeException('Seçilen operasyon kişisi bulunamadı.');
        }

        return $counterpart;
    }

    protected function directConversationKey(int $leftUserId, int $rightUserId): string
    {
        $small = min($leftUserId, $rightUserId);
        $large = max($leftUserId, $rightUserId);

        return "direct:{$small}:{$large}";
    }

    protected function threadTitle(array $context, object $counterpart): string
    {
        if ($context['role'] === 'manager' && !empty($counterpart->team_name)) {
            return $counterpart->team_name . ' Operasyon';
        }

        if ($context['role'] === 'team_lead' && $context['team_name'] !== '') {
            return $context['team_name'] . ' Operasyon';
        }

        return trim(($counterpart->name ?? 'Operasyon') . ' Mesajları');
    }

    protected function threadSummaryPayload(array $context, int $threadId): array
    {
        $thread = DB::table('operation_threads')
            ->where('id', $threadId)
            ->where('company_id', $context['company_id'])
            ->firstOrFail();

        $counterpart = $this->threadCounterpart($threadId, $context['user_id']);
        $latestMessage = DB::table('operation_thread_messages')
            ->where('thread_id', $threadId)
            ->orderByDesc('id')
            ->first(['id', 'body', 'created_at']);

        return [
            'id' => (string) $thread->id,
            'title' => $thread->title,
            'counterpart_id' => $counterpart !== null ? (string) $counterpart->id : null,
            'counterpart_name' => $counterpart->name ?? 'Operasyon',
            'counterpart_role' => $counterpart->role_code ?? '',
            'counterpart_role_label' => $counterpart !== null
                ? $this->roleLabelFromCode((string) $counterpart->role_code)
                : 'Operasyon',
            'counterpart_team_name' => $counterpart->team_name ?? '',
            'last_message_preview' => $latestMessage !== null
                ? mb_strimwidth((string) $latestMessage->body, 0, 90, '...')
                : 'Henüz mesaj yok.',
            'unread_count' => $this->unreadCount($threadId, $context['user_id']),
            'updated_at' => $this->iso($thread->updated_at),
            'last_message_at' => $this->iso($thread->last_message_at),
        ];
    }

    protected function threadPayload(array $context, int $threadId): array
    {
        $summary = $this->threadSummaryPayload($context, $threadId);
        $messages = DB::table('operation_thread_messages as otm')
            ->leftJoin('users as u', 'u.id', '=', 'otm.sender_user_id')
            ->where('otm.thread_id', $threadId)
            ->orderByDesc('otm.id')
            ->limit(60)
            ->get([
                'otm.id',
                'otm.sender_user_id',
                'otm.body',
                'otm.created_at',
                'u.name as sender_name',
            ])
            ->reverse()
            ->values()
            ->map(fn ($message) => [
                'id' => (string) $message->id,
                'sender_user_id' => $message->sender_user_id !== null ? (string) $message->sender_user_id : null,
                'sender_name' => $message->sender_name ?? 'Sistem',
                'body' => $message->body,
                'created_at' => $this->iso($message->created_at),
                'is_mine' => (int) ($message->sender_user_id ?? 0) === $context['user_id'],
            ])
            ->all();

        return [
            ...$summary,
            'messages' => $messages,
        ];
    }

    protected function threadCounterpart(int $threadId, int $currentUserId): ?object
    {
        return DB::table('operation_thread_participants as otp')
            ->join('users as u', 'u.id', '=', 'otp.user_id')
            ->leftJoin('teams as t', 't.id', '=', 'u.team_id')
            ->where('otp.thread_id', $threadId)
            ->where('otp.user_id', '<>', $currentUserId)
            ->select([
                'u.id',
                'u.name',
                't.name as team_name',
            ])
            ->get()
            ->map(function ($participant) {
                $participant->role_code = $this->roleForUser((int) $participant->id);
                return $participant;
            })
            ->first();
    }

    protected function unreadCount(int $threadId, int $userId): int
    {
        $lastReadMessageId = DB::table('operation_thread_reads')
            ->where('thread_id', $threadId)
            ->where('user_id', $userId)
            ->value('last_read_message_id');

        return (int) DB::table('operation_thread_messages')
            ->where('thread_id', $threadId)
            ->where('sender_user_id', '<>', $userId)
            ->when(
                $lastReadMessageId !== null,
                fn ($query) => $query->where('id', '>', $lastReadMessageId)
            )
            ->count();
    }

    protected function markThreadAsRead(int $userId, int $threadId): void
    {
        $latestMessageId = DB::table('operation_thread_messages')
            ->where('thread_id', $threadId)
            ->orderByDesc('id')
            ->value('id');

        DB::table('operation_thread_reads')->updateOrInsert(
            [
                'thread_id' => $threadId,
                'user_id' => $userId,
            ],
            [
                'last_read_message_id' => $latestMessageId,
                'last_read_at' => now(),
            ]
        );
    }

    protected function roleLabelFromCode(string $roleCode): string
    {
        return match ($roleCode) {
            'manager' => 'Yönetici',
            'team_lead' => 'Ekip Lideri',
            default => 'Çalışan',
        };
    }

    protected function iso(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return Carbon::parse($value)->toIso8601String();
    }
}
