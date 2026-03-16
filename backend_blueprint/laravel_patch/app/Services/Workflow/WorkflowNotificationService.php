<?php

namespace App\Services\Workflow;

use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class WorkflowNotificationService
{
    public function notifyUsers(
        int $companyId,
        iterable $userIds,
        string $title,
        string $body,
        string $notificationType,
        ?int $relatedTaskId = null,
        ?int $relatedRevisionId = null,
        array $excludeUserIds = [],
    ): void {
        $candidateIds = collect($userIds)
            ->map(fn ($value) => (int) $value)
            ->filter(fn ($value) => $value > 0)
            ->reject(fn ($value) => in_array($value, $excludeUserIds, true))
            ->unique()
            ->values();

        if ($candidateIds->isEmpty()) {
            return;
        }

        $enabledUserIds = DB::table('users as u')
            ->leftJoin('notification_preferences as np', 'np.user_id', '=', 'u.id')
            ->where('u.company_id', $companyId)
            ->where('u.status', 'active')
            ->whereIn('u.id', $candidateIds->all())
            ->where(function ($query) {
                $query->whereNull('np.user_id')
                    ->orWhere('np.in_app_enabled', true);
            })
            ->pluck('u.id')
            ->map(fn ($value) => (int) $value)
            ->values();

        if ($enabledUserIds->isEmpty()) {
            return;
        }

        $now = now();
        $rows = $enabledUserIds
            ->map(fn ($userId) => [
                'company_id' => $companyId,
                'user_id' => $userId,
                'title' => $title,
                'body' => $body,
                'notification_type' => $notificationType,
                'related_task_id' => $relatedTaskId,
                'related_revision_id' => $relatedRevisionId,
                'is_read' => false,
                'created_at' => $now,
            ])
            ->all();

        DB::table('notifications')->insert($rows);
    }

    public function inbox(User $user, int $limit = 24): array
    {
        return [
            'unread_count' => $this->unreadCount((int) $user->id),
            'items' => $this->itemsForUser((int) $user->id, $limit),
        ];
    }

    public function markRead(User $user, int $notificationId): array
    {
        DB::table('notifications')
            ->where('id', $notificationId)
            ->where('user_id', $user->id)
            ->update(['is_read' => true]);

        return [
            'notification_id' => (string) $notificationId,
            'unread_count' => $this->unreadCount((int) $user->id),
        ];
    }

    public function markAllRead(User $user): array
    {
        DB::table('notifications')
            ->where('user_id', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return ['unread_count' => 0];
    }

    public function dashboardItems(int $userId, int $limit = 4): array
    {
        return collect($this->itemsForUser($userId, $limit, unreadOnly: true))
            ->map(fn ($item) => [
                'title' => $item['title'],
                'subtitle' => $item['body'],
                'accent' => $item['accent'],
            ])
            ->values()
            ->all();
    }

    protected function unreadCount(int $userId): int
    {
        return (int) DB::table('notifications')
            ->where('user_id', $userId)
            ->where('is_read', false)
            ->count();
    }

    protected function itemsForUser(
        int $userId,
        int $limit,
        bool $unreadOnly = false,
    ): array {
        return DB::table('notifications')
            ->where('user_id', $userId)
            ->when($unreadOnly, fn ($query) => $query->where('is_read', false))
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get([
                'id',
                'title',
                'body',
                'notification_type',
                'related_task_id',
                'related_revision_id',
                'is_read',
                'created_at',
            ])
            ->map(fn ($notification) => $this->notificationPayload($notification))
            ->values()
            ->all();
    }

    protected function notificationPayload(object $notification): array
    {
        return [
            'id' => (string) $notification->id,
            'title' => $notification->title,
            'body' => $notification->body,
            'type' => $notification->notification_type,
            'accent' => $this->accentForType((string) $notification->notification_type),
            'related_task_id' => $notification->related_task_id !== null ? (string) $notification->related_task_id : null,
            'related_revision_id' => $notification->related_revision_id !== null ? (string) $notification->related_revision_id : null,
            'is_read' => (bool) $notification->is_read,
            'created_at' => Carbon::parse($notification->created_at)->toIso8601String(),
            'created_at_label' => $this->createdAtLabel(Carbon::parse($notification->created_at)),
        ];
    }

    protected function accentForType(string $notificationType): string
    {
        return match ($notificationType) {
            'task_assigned', 'task_created', 'task_started', 'operation_message' => 'primary',
            'task_submitted', 'report_ready', 'revision_updated' => 'success',
            'revision_requested', 'task_meeting' => 'warning',
            default => 'danger',
        };
    }

    protected function createdAtLabel(Carbon $createdAt): string
    {
        $now = now();
        if ($createdAt->isSameDay($now)) {
            return $createdAt->format('H:i');
        }

        return $createdAt->format('d.m H:i');
    }
}
