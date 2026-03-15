<?php

namespace App\Http\Controllers\Api\Workflow;

use App\Http\Controllers\Controller;
use App\Services\Workflow\WorkflowApiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WorkspaceController extends Controller
{
    public function __construct(
        private readonly WorkflowApiService $workflow,
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
            'project_id' => ['required', 'integer'],
            'assignee_id' => ['required', 'integer'],
            'priority' => ['required', 'string', 'in:low,medium,high'],
            'due_at' => ['required', 'date'],
            'estimated_minutes' => ['nullable', 'integer', 'min:1', 'max:10080'],
            'tag' => ['nullable', 'string', 'max:80'],
        ]);

        return response()->json([
            'task' => $this->workflow->createTask($request->user(), $payload),
        ]);
    }

    public function startTask(Request $request, string $taskId): JsonResponse
    {
        return response()->json([
            'task' => $this->workflow->startTask($request->user(), $taskId),
        ]);
    }

    public function commentTask(Request $request, string $taskId): JsonResponse
    {
        $payload = $request->validate([
            'message' => ['required', 'string', 'max:5000'],
        ]);

        return response()->json([
            'task' => $this->workflow->commentTask($request->user(), $taskId, $payload['message']),
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
        return response()->json([
            'task' => $this->workflow->submitTask($request->user(), $taskId),
        ]);
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

    public function addManagerNote(Request $request, string $memberId): JsonResponse
    {
        $payload = $request->validate([
            'note' => ['required', 'string', 'max:5000'],
        ]);

        $this->workflow->addManagerNote($request->user(), $memberId, $payload['note'], $request->ip());

        return response()->json([
            'message' => 'Yonetici notu kaydedildi.',
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
