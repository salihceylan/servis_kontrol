<?php

namespace App\Http\Controllers\Api\Workflow;

use App\Http\Controllers\Controller;
use App\Services\Workflow\OperationMessageService;
use App\Services\Workflow\WorkflowNotificationService;
use App\Services\Workflow\WorkflowApiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WorkspaceController extends Controller
{
    public function __construct(
        private readonly WorkflowApiService $workflow,
        private readonly OperationMessageService $operationMessages,
        private readonly WorkflowNotificationService $notifications,
    ) {
    }

    public function dashboard(Request $request): JsonResponse
    {
        return response()->json($this->workflow->dashboard($request->user()));
    }

    public function tasks(Request $request): JsonResponse
    {
        return response()->json($this->workflow->tasks($request->user(), $request->query()));
    }

    public function taskMeta(Request $request): JsonResponse
    {
        return response()->json($this->workflow->taskMeta($request->user()));
    }

    public function createTask(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'title' => ['required', 'string', 'max:180'],
            'description' => ['nullable', 'string', 'max:10000'],
            'project_id' => ['nullable', 'integer'],
            'team_id' => ['nullable', 'integer'],
            'assignee_id' => ['required', 'integer'],
            'priority' => ['required', 'string', 'in:low,medium,high'],
            'planned_start_at' => ['nullable', 'date'],
            'due_at' => ['nullable', 'date'],
            'estimated_minutes' => ['nullable', 'integer', 'min:1', 'max:10080'],
            'tag' => ['nullable', 'string', 'max:80'],
            'service_location' => ['nullable', 'string', 'max:255'],
            'contact_name' => ['nullable', 'string', 'max:160'],
            'contact_phone' => ['nullable', 'string', 'max:32'],
            'access_notes' => ['nullable', 'string', 'max:5000'],
            'expected_outcome' => ['nullable', 'string', 'max:5000'],
            'manager_brief' => ['nullable', 'string', 'max:5000'],
            'lead_brief' => ['nullable', 'string', 'max:5000'],
        ]);

        return response()->json([
            'task' => $this->workflow->createTask($request->user(), $payload),
        ]);
    }

    public function startTask(Request $request, string $taskId): JsonResponse
    {
        $payload = $request->validate([
            'start_note' => ['nullable', 'string', 'max:5000'],
        ]);

        return response()->json([
            'task' => $this->workflow->startTask($request->user(), $taskId, $payload['start_note'] ?? null),
        ]);
    }

    public function commentTask(Request $request, string $taskId): JsonResponse
    {
        $payload = $request->validate([
            'message' => ['required', 'string', 'max:5000'],
            'comment_type' => ['nullable', 'string', 'in:comment,manager_note,coordination,field_update'],
        ]);

        return response()->json([
            'task' => $this->workflow->commentTask(
                $request->user(),
                $taskId,
                $payload['message'],
                $payload['comment_type'] ?? 'comment',
            ),
        ]);
    }

    public function scheduleTaskMeeting(Request $request, string $taskId): JsonResponse
    {
        return response()->json([
            'task' => $this->workflow->scheduleTaskMeeting($request->user(), $taskId),
        ]);
    }

    public function submitTask(Request $request, string $taskId): JsonResponse
    {
        $payload = $request->validate([
            'completion_summary' => ['required', 'string', 'max:5000'],
            'field_notes' => ['nullable', 'string', 'max:5000'],
            'blocker_notes' => ['nullable', 'string', 'max:5000'],
            'actual_minutes' => ['nullable', 'integer', 'min:1', 'max:10080'],
        ]);

        return response()->json([
            'task' => $this->workflow->submitTask($request->user(), $taskId, $payload),
        ]);
    }

    public function operationInbox(Request $request): JsonResponse
    {
        return response()->json($this->operationMessages->inbox($request->user()));
    }

    public function notifications(Request $request): JsonResponse
    {
        return response()->json($this->notifications->inbox($request->user()));
    }

    public function openOperationThread(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'counterpart_user_id' => ['required', 'integer'],
        ]);

        return response()->json([
            'thread' => $this->operationMessages->openThread(
                $request->user(),
                (int) $payload['counterpart_user_id'],
            ),
        ]);
    }

    public function openOperationBroadcast(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'target_id' => ['required', 'string', 'max:80'],
        ]);

        return response()->json([
            'thread' => $this->operationMessages->openBroadcast(
                $request->user(),
                $payload['target_id'],
            ),
        ]);
    }

    public function operationThread(Request $request, string $threadId): JsonResponse
    {
        return response()->json([
            'thread' => $this->operationMessages->thread($request->user(), (int) $threadId),
        ]);
    }

    public function sendOperationMessage(Request $request, string $threadId): JsonResponse
    {
        $payload = $request->validate([
            'body' => ['required', 'string', 'max:5000'],
        ]);

        return response()->json([
            'thread' => $this->operationMessages->sendMessage(
                $request->user(),
                (int) $threadId,
                $payload['body'],
            ),
        ]);
    }

    public function markNotificationRead(Request $request, string $notificationId): JsonResponse
    {
        return response()->json(
            $this->notifications->markRead($request->user(), (int) $notificationId),
        );
    }

    public function markAllNotificationsRead(Request $request): JsonResponse
    {
        return response()->json($this->notifications->markAllRead($request->user()));
    }

    public function markOperationThreadRead(Request $request, string $threadId): JsonResponse
    {
        return response()->json(
            $this->operationMessages->markRead($request->user(), (int) $threadId),
        );
    }

    public function revisions(Request $request): JsonResponse
    {
        return response()->json($this->workflow->revisions($request->user(), $request->query()));
    }

    public function approveRevision(Request $request, string $revisionId): JsonResponse
    {
        return response()->json([
            'revision' => $this->workflow->approveRevision($request->user(), $revisionId),
        ]);
    }

    public function requestRevision(Request $request, string $revisionId): JsonResponse
    {
        $payload = $request->validate([
            'reason' => ['required', 'string', 'max:5000'],
        ]);

        return response()->json([
            'revision' => $this->workflow->requestRevision($request->user(), $revisionId, $payload['reason']),
        ]);
    }

    public function markRevisionUpdated(Request $request, string $revisionId): JsonResponse
    {
        $payload = $request->validate([
            'note' => ['required', 'string', 'max:5000'],
        ]);

        return response()->json([
            'revision' => $this->workflow->markRevisionUpdated($request->user(), $revisionId, $payload['note']),
        ]);
    }

    public function team(Request $request): JsonResponse
    {
        return response()->json($this->workflow->team($request->user(), $request->query()));
    }

    public function createTeamMember(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'name' => ['required', 'string', 'max:160'],
            'login_name' => ['required', 'string', 'max:80', 'regex:/^[A-Za-z0-9._-]+$/'],
            'email' => ['nullable', 'email', 'max:160'],
            'password' => ['required', 'string', 'min:8', 'max:160'],
            'role_code' => ['required', 'string', 'in:team_lead,employee'],
            'department' => ['nullable', 'string', 'max:120'],
            'job_title' => ['nullable', 'string', 'max:120'],
            'phone' => ['nullable', 'string', 'max:32'],
            'team_id' => ['nullable', 'integer'],
            'work_preference' => ['nullable', 'string', 'max:120'],
            'status' => ['required', 'string', 'in:active,passive'],
            'permission_codes' => ['array'],
            'permission_codes.*' => ['string', 'max:120'],
        ]);

        return response()->json([
            'member' => $this->workflow->createTeamMember($request->user(), $payload),
        ]);
    }

    public function updateTeamMember(Request $request, string $memberId): JsonResponse
    {
        $payload = $request->validate([
            'name' => ['required', 'string', 'max:160'],
            'login_name' => ['required', 'string', 'max:80', 'regex:/^[A-Za-z0-9._-]+$/'],
            'email' => ['nullable', 'email', 'max:160'],
            'password' => ['nullable', 'string', 'min:8', 'max:160'],
            'role_code' => ['required', 'string', 'in:team_lead,employee'],
            'department' => ['nullable', 'string', 'max:120'],
            'job_title' => ['nullable', 'string', 'max:120'],
            'phone' => ['nullable', 'string', 'max:32'],
            'team_id' => ['nullable', 'integer'],
            'work_preference' => ['nullable', 'string', 'max:120'],
            'status' => ['required', 'string', 'in:active,passive'],
            'permission_codes' => ['array'],
            'permission_codes.*' => ['string', 'max:120'],
        ]);

        return response()->json([
            'member' => $this->workflow->updateTeamMember($request->user(), $memberId, $payload),
        ]);
    }

    public function createTeamGroup(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'manager_user_id' => ['nullable', 'integer'],
        ]);

        return response()->json([
            'team' => $this->workflow->createTeamGroup($request->user(), $payload),
        ]);
    }

    public function updateTeamGroup(Request $request, string $teamId): JsonResponse
    {
        $payload = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'manager_user_id' => ['nullable', 'integer'],
        ]);

        return response()->json([
            'team' => $this->workflow->updateTeamGroup($request->user(), $teamId, $payload),
        ]);
    }

    public function addManagerNote(Request $request, string $memberId): JsonResponse
    {
        $payload = $request->validate([
            'note' => ['required', 'string', 'max:5000'],
        ]);

        $this->workflow->addManagerNote($request->user(), $memberId, $payload['note'], $request->ip());

        return response()->json([
            'message' => 'Yönetici notu kaydedildi.',
        ]);
    }

    public function performance(Request $request): JsonResponse
    {
        return response()->json($this->workflow->performance($request->user(), $request->query()));
    }

    public function reports(Request $request): JsonResponse
    {
        return response()->json($this->workflow->reports($request->user(), $request->query()));
    }

    public function createReport(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'scope' => ['required', 'string', 'max:160'],
            'type' => ['required', 'string', 'in:operational,performance,revision,delivery'],
            'format' => ['required', 'string', 'in:pdf,excel'],
            'team' => ['nullable', 'string', 'max:120'],
            'user' => ['nullable', 'string', 'max:120'],
        ]);

        return response()->json([
            'run' => $this->workflow->createReport($request->user(), $payload),
        ]);
    }

    public function generalSettings(Request $request): JsonResponse
    {
        return response()->json($this->workflow->generalSettings($request->user()));
    }

    public function saveGeneralSettings(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'company_name' => ['required', 'string', 'max:160'],
            'company_code' => ['nullable', 'string', 'size:5'],
            'default_language' => ['required', 'string', 'max:12'],
            'timezone' => ['required', 'string', 'max:64'],
            'week_starts_on' => ['required', 'string', 'max:20'],
            'date_format' => ['required', 'string', 'max:40'],
            'notification_summary_enabled' => ['required', 'boolean'],
            'email_notifications_enabled' => ['required', 'boolean'],
            'slack_notifications_enabled' => ['required', 'boolean'],
        ]);

        return response()->json([
            'settings' => $this->workflow->saveGeneralSettings($request->user(), $payload),
        ]);
    }

    public function helpCenter(Request $request): JsonResponse
    {
        return response()->json($this->workflow->helpCenter($request->user(), $request->query()));
    }
}
