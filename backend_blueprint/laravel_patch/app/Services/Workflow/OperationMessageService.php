<?php

namespace App\Services\Workflow;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class OperationMessageService
{
    protected const POLL_INTERVAL_SECONDS = 8;

    public function __construct(
        private readonly WorkflowNotificationService $notificationCenter,
    ) {
    }

    public function inbox(User $user): array
    {
        $context = $this->context($user);
        $this->ensureMessagingAccess($context);
        $this->syncRelevantBroadcasts($context);

        $threads = collect($this->threadIdsForUser($context['company_id'], $context['user_id']))
            ->map(fn (int $threadId) => $this->threadSummaryPayload($context, $threadId))
            ->values()
            ->all();

        return [
            'threads' => $threads,
            'contacts' => $this->contactOptions($context),
            'broadcast_targets' => $this->broadcastTargets($context),
            'poll_interval_seconds' => self::POLL_INTERVAL_SECONDS,
        ];
    }

    public function openThread(User $user, int $counterpartUserId): array
    {
        $context = $this->context($user);
        $this->ensureDirectMessagingAccess($context);
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

    public function openBroadcast(User $user, string $targetId): array
    {
        $context = $this->context($user);
        $this->ensureBroadcastCreationAccess($context);
        $target = $this->broadcastTargetDefinition($context, $targetId);

        $threadId = DB::transaction(function () use ($context, $target): int {
            $existing = DB::table('operation_threads')
                ->where('company_id', $context['company_id'])
                ->where('conversation_key', $target['conversation_key'])
                ->value('id');

            if ($existing !== null) {
                $threadId = (int) $existing;
            } else {
                $threadId = (int) DB::table('operation_threads')->insertGetId([
                    'company_id' => $context['company_id'],
                    'task_id' => null,
                    'thread_type' => $target['thread_type'],
                    'conversation_key' => $target['conversation_key'],
                    'title' => $target['title'],
                    'created_by' => $context['user_id'],
                    'last_message_at' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            $this->syncBroadcastParticipants(
                $threadId,
                $target,
                $context['company_id'],
                $context['user_id'],
            );

            return $threadId;
        });

        $this->markThreadAsRead($context['user_id'], $threadId);

        return $this->threadPayload($context, $threadId);
    }

    public function thread(User $user, int $threadId): array
    {
        $context = $this->context($user);
        $this->ensureMessagingAccess($context);
        $this->syncThreadParticipants($context, $threadId);
        $this->participantThreadRow($context, $threadId);
        $this->markThreadAsRead($context['user_id'], $threadId);

        return $this->threadPayload($context, $threadId);
    }

    public function sendMessage(User $user, int $threadId, string $body): array
    {
        $context = $this->context($user);
        $this->ensureMessagingAccess($context);
        $this->syncThreadParticipants($context, $threadId);
        $thread = $this->participantThreadRow($context, $threadId);
        $normalizedBody = trim($body);
        if ($normalizedBody === '') {
            throw new RuntimeException('Mesaj boş olamaz.');
        }
        if (!$this->canSendToThread($context, $thread)) {
            throw new AuthorizationException('Bu kanalda mesaj gönderme yetkin bulunmuyor.');
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

        $this->notifyThreadParticipants($context, $thread, $normalizedBody);
        return $this->threadPayload($context, (int) $thread->id);
    }

    public function markRead(User $user, int $threadId): array
    {
        $context = $this->context($user);
        $this->ensureMessagingAccess($context);
        $this->syncThreadParticipants($context, $threadId);
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

    protected function ensureMessagingAccess(array $context): void
    {
        if (!in_array($context['role'], ['manager', 'team_lead', 'employee'], true)) {
            throw new AuthorizationException('Operasyon mesaj docku yalnızca ekip kullanıcılarında açık.');
        }
    }

    protected function ensureDirectMessagingAccess(array $context): void
    {
        if (!in_array($context['role'], ['manager', 'team_lead'], true)) {
            throw new AuthorizationException('Direkt operasyon konuşmaları yalnızca yönetici ve ekip liderinde açık.');
        }
    }

    protected function ensureBroadcastCreationAccess(array $context): void
    {
        if (!in_array($context['role'], ['manager', 'team_lead'], true)) {
            throw new AuthorizationException('Duyuru kanalı açma yetkisi yalnızca yönetici ve ekip liderinde açık.');
        }
    }

    protected function participantThreadRow(array $context, int $threadId): object
    {
        return DB::table('operation_threads as ot')
            ->join('operation_thread_participants as otp', 'otp.thread_id', '=', 'ot.id')
            ->where('ot.company_id', $context['company_id'])
            ->where('ot.id', $threadId)
            ->where('otp.user_id', $context['user_id'])
            ->select([
                'ot.id',
                'ot.title',
                'ot.thread_type',
                'ot.conversation_key',
                'ot.last_message_at',
                'ot.updated_at',
            ])
            ->firstOrFail();
    }

    protected function threadRow(array $context, int $threadId): object
    {
        return DB::table('operation_threads')
            ->where('company_id', $context['company_id'])
            ->where('id', $threadId)
            ->select(['id', 'title', 'thread_type', 'conversation_key', 'last_message_at', 'updated_at'])
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
        if ($context['role'] === 'employee') {
            return [];
        }

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

    protected function broadcastTargets(array $context): array
    {
        if ($context['role'] === 'employee') {
            return [];
        }

        $targets = [];
        if ($context['role'] === 'manager') {
            $targets[] = [
                'id' => 'company',
                'scope_code' => 'company',
                'label' => 'Şirket kanalı',
                'description' => 'Tüm aktif kullanıcılar',
                'participant_count' => $this->activeCompanyUserCount($context['company_id']),
            ];

            $teamTargets = DB::table('teams')
                ->where('company_id', $context['company_id'])
                ->orderBy('name')
                ->get(['id', 'name'])
                ->map(fn ($team) => [
                    'id' => 'team:' . $team->id,
                    'scope_code' => 'team',
                    'label' => ($team->name ?? 'Takım') . ' kanalı',
                    'description' => 'Takım duyurusu ve görev koordinasyonu',
                    'participant_count' => $this->activeTeamUserCount($context['company_id'], (int) $team->id),
                ])
                ->values()
                ->all();

            return [...$targets, ...$teamTargets];
        }

        if ($context['team_id'] === null) {
            return [];
        }

        return [[
            'id' => 'team:' . $context['team_id'],
            'scope_code' => 'team',
            'label' => ($context['team_name'] !== '' ? $context['team_name'] : 'Takım') . ' kanalı',
            'description' => 'Takım üyelerine toplu duyuru gönder',
            'participant_count' => $this->activeTeamUserCount($context['company_id'], $context['team_id']),
        ]];
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

    protected function broadcastTargetDefinition(array $context, string $targetId): array
    {
        if ($targetId === 'company') {
            if ($context['role'] !== 'manager') {
                throw new AuthorizationException('Şirket kanalı yalnızca yönetici tarafından açılabilir.');
            }

            return [
                'thread_type' => 'company_broadcast',
                'conversation_key' => 'broadcast:company',
                'title' => 'Şirket Operasyon Hattı',
                'scope_code' => 'company',
                'team_id' => null,
            ];
        }

        if (!str_starts_with($targetId, 'team:')) {
            throw new RuntimeException('Seçilen duyuru kanalı bulunamadı.');
        }

        $teamId = (int) substr($targetId, 5);
        $team = DB::table('teams')
            ->where('company_id', $context['company_id'])
            ->where('id', $teamId)
            ->first(['id', 'name']);

        if ($team === null) {
            throw new RuntimeException('Seçilen takım kanalı bulunamadı.');
        }

        if ($context['role'] === 'team_lead' && (int) ($context['team_id'] ?? 0) !== (int) $team->id) {
            throw new AuthorizationException('Yalnızca kendi takım kanalını açabilirsin.');
        }

        return [
            'thread_type' => 'team_broadcast',
            'conversation_key' => 'broadcast:team:' . $team->id,
            'title' => ($team->name ?? 'Takım') . ' Operasyon Hattı',
            'scope_code' => 'team',
            'team_id' => (int) $team->id,
        ];
    }

    protected function threadSummaryPayload(array $context, int $threadId): array
    {
        $thread = $this->threadRow($context, $threadId);
        $counterpart = $thread->thread_type === 'direct'
            ? $this->threadCounterpart($threadId, $context['user_id'])
            : null;
        $latestMessage = DB::table('operation_thread_messages')
            ->where('thread_id', $threadId)
            ->orderByDesc('id')
            ->first(['id', 'body', 'created_at']);

        return [
            'id' => (string) $thread->id,
            'title' => $thread->title,
            'thread_type' => $thread->thread_type,
            'channel_label' => $this->channelLabelFromThreadType((string) $thread->thread_type),
            'participant_count' => $this->participantCount((int) $thread->id),
            'counterpart_id' => $counterpart !== null ? (string) $counterpart->id : null,
            'counterpart_name' => $counterpart->name ?? $thread->title,
            'counterpart_role' => $counterpart->role_code ?? '',
            'counterpart_role_label' => $counterpart !== null
                ? $this->roleLabelFromCode((string) $counterpart->role_code)
                : $this->threadAudienceLabel((string) $thread->thread_type),
            'counterpart_team_name' => $counterpart->team_name ?? '',
            'last_message_preview' => $latestMessage !== null
                ? mb_strimwidth((string) $latestMessage->body, 0, 90, '...')
                : 'Henüz mesaj yok.',
            'unread_count' => $this->unreadCount($threadId, $context['user_id']),
            'can_reply' => $this->canSendToThread($context, $thread),
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
            ->limit(80)
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

    protected function syncRelevantBroadcasts(array $context): void
    {
        $companyThreadId = DB::table('operation_threads')
            ->where('company_id', $context['company_id'])
            ->where('conversation_key', 'broadcast:company')
            ->value('id');

        if ($companyThreadId !== null) {
            $this->syncCompanyBroadcastParticipants($context['company_id'], (int) $companyThreadId);
        }

        if ($context['role'] === 'manager') {
            $teamThreads = DB::table('operation_threads')
                ->where('company_id', $context['company_id'])
                ->where('thread_type', 'team_broadcast')
                ->pluck('id', 'conversation_key');

            foreach ($teamThreads as $conversationKey => $threadId) {
                $teamId = $this->teamIdFromConversationKey((string) $conversationKey);
                if ($teamId !== null) {
                    $this->syncTeamBroadcastParticipants($context['company_id'], $teamId, (int) $threadId, $context['user_id']);
                }
            }

            return;
        }

        if ($context['team_id'] === null) {
            return;
        }

        $teamThreadId = DB::table('operation_threads')
            ->where('company_id', $context['company_id'])
            ->where('conversation_key', 'broadcast:team:' . $context['team_id'])
            ->value('id');

        if ($teamThreadId !== null) {
            $this->syncTeamBroadcastParticipants(
                $context['company_id'],
                $context['team_id'],
                (int) $teamThreadId,
                $context['role'] === 'manager' ? $context['user_id'] : null,
            );
        }
    }

    protected function syncThreadParticipants(array $context, int $threadId): void
    {
        $thread = $this->threadRow($context, $threadId);

        if ($thread->thread_type === 'company_broadcast') {
            $this->syncCompanyBroadcastParticipants($context['company_id'], (int) $thread->id);
            return;
        }

        if ($thread->thread_type !== 'team_broadcast') {
            return;
        }

        $teamId = $this->teamIdFromConversationKey((string) $thread->conversation_key);
        if ($teamId === null) {
            return;
        }

        $includeUserId = $context['role'] === 'manager' ? $context['user_id'] : null;
        $this->syncTeamBroadcastParticipants($context['company_id'], $teamId, (int) $thread->id, $includeUserId);
    }

    protected function syncBroadcastParticipants(int $threadId, array $target, int $companyId, int $senderUserId): void
    {
        if ($target['scope_code'] === 'company') {
            $this->syncCompanyBroadcastParticipants($companyId, $threadId, $senderUserId);
            return;
        }

        $this->syncTeamBroadcastParticipants($companyId, (int) $target['team_id'], $threadId, $senderUserId);
    }

    protected function syncCompanyBroadcastParticipants(int $companyId, int $threadId, ?int $includeUserId = null): void
    {
        $userIds = DB::table('users')
            ->where('company_id', $companyId)
            ->where('status', 'active')
            ->pluck('id')
            ->map(fn ($id) => (int) $id);

        if ($includeUserId !== null) {
            $userIds->push($includeUserId);
        }

        $this->replaceThreadParticipants($threadId, $userIds);
    }

    protected function syncTeamBroadcastParticipants(int $companyId, int $teamId, int $threadId, ?int $includeUserId = null): void
    {
        $userIds = DB::table('users')
            ->where('company_id', $companyId)
            ->where('status', 'active')
            ->where('team_id', $teamId)
            ->pluck('id')
            ->map(fn ($id) => (int) $id);

        if ($includeUserId !== null) {
            $userIds->push($includeUserId);
        }

        $this->replaceThreadParticipants($threadId, $userIds);
    }

    protected function replaceThreadParticipants(int $threadId, Collection $userIds): void
    {
        $uniqueIds = $userIds
            ->filter(fn ($id) => (int) $id > 0)
            ->unique()
            ->values();

        if ($uniqueIds->isEmpty()) {
            return;
        }

        DB::table('operation_thread_participants')
            ->where('thread_id', $threadId)
            ->whereNotIn('user_id', $uniqueIds->all())
            ->delete();

        $rows = $uniqueIds
            ->map(fn ($userId) => [
                'thread_id' => $threadId,
                'user_id' => (int) $userId,
                'joined_at' => now(),
            ])
            ->all();

        DB::table('operation_thread_participants')->insertOrIgnore($rows);
    }

    protected function participantCount(int $threadId): int
    {
        return (int) DB::table('operation_thread_participants')
            ->where('thread_id', $threadId)
            ->count();
    }

    protected function activeCompanyUserCount(int $companyId): int
    {
        return (int) DB::table('users')
            ->where('company_id', $companyId)
            ->where('status', 'active')
            ->count();
    }

    protected function activeTeamUserCount(int $companyId, int $teamId): int
    {
        return (int) DB::table('users')
            ->where('company_id', $companyId)
            ->where('team_id', $teamId)
            ->where('status', 'active')
            ->count();
    }

    protected function teamIdFromConversationKey(string $conversationKey): ?int
    {
        if (!str_starts_with($conversationKey, 'broadcast:team:')) {
            return null;
        }

        $value = (int) substr($conversationKey, 15);
        return $value > 0 ? $value : null;
    }

    protected function canSendToThread(array $context, object $thread): bool
    {
        return match ((string) $thread->thread_type) {
            'direct' => in_array($context['role'], ['manager', 'team_lead'], true),
            'company_broadcast' => $context['role'] === 'manager',
            'team_broadcast' => $context['role'] === 'manager'
                || ($context['role'] === 'team_lead'
                    && $context['team_id'] !== null
                    && $this->teamIdFromConversationKey((string) $thread->conversation_key) === (int) $context['team_id']),
            default => false,
        };
    }

    protected function notifyThreadParticipants(array $context, object $thread, string $messageBody): void
    {
        $recipientIds = DB::table('operation_thread_participants')
            ->where('thread_id', $thread->id)
            ->pluck('user_id')
            ->map(fn ($value) => (int) $value)
            ->filter(fn ($value) => $value > 0 && $value !== (int) $context['user_id'])
            ->unique()
            ->values()
            ->all();

        if ($recipientIds === []) {
            return;
        }

        $title = match ((string) $thread->thread_type) {
            'company_broadcast' => 'Yeni sirket duyurusu',
            'team_broadcast' => 'Yeni takim duyurusu',
            default => 'Yeni operasyon mesaji',
        };

        $preview = mb_strimwidth($messageBody, 0, 120, '...');
        $body = match ((string) $thread->thread_type) {
            'company_broadcast', 'team_broadcast' => "{$context['name']} {$thread->title} kanalinda yeni bir mesaj paylasti: {$preview}",
            default => "{$context['name']} size yeni bir operasyon mesaji gonderdi: {$preview}",
        };

        $this->notificationCenter->notifyUsers(
            $context['company_id'],
            $recipientIds,
            $title,
            $body,
            'operation_message',
            excludeUserIds: [(int) $context['user_id']],
        );
    }

    protected function channelLabelFromThreadType(string $threadType): string
    {
        return match ($threadType) {
            'company_broadcast' => 'Şirket hattı',
            'team_broadcast' => 'Takım hattı',
            default => 'Direkt hat',
        };
    }

    protected function threadAudienceLabel(string $threadType): string
    {
        return match ($threadType) {
            'company_broadcast' => 'Şirket duyurusu',
            'team_broadcast' => 'Takım duyurusu',
            default => 'Operasyon',
        };
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
