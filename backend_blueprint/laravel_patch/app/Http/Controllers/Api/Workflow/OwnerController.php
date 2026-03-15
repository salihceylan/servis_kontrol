<?php

namespace App\Http\Controllers\Api\Workflow;

use App\Http\Controllers\Controller;
use App\Services\Workflow\OwnerPortalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OwnerController extends Controller
{
    public function __construct(
        private readonly OwnerPortalService $ownerPortal,
    ) {
    }

    public function dashboard(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json($this->ownerPortal->dashboard($user));
    }

    public function companies(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json($this->ownerPortal->companies($user));
    }

    public function createCompany(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'company_name' => ['required', 'string', 'max:160'],
            'admin_name' => ['required', 'string', 'max:160'],
            'admin_email' => ['required', 'email'],
            'admin_password' => ['required', 'string', 'min:8'],
            'department_name' => ['nullable', 'string', 'max:120'],
            'team_name' => ['nullable', 'string', 'max:120'],
            'timezone' => ['required', 'string', 'max:64'],
            'locale' => ['required', 'string', 'max:12'],
            'plan_name' => ['required', 'string', 'max:80'],
            'user_limit' => ['required', 'integer', 'min:1', 'max:5000'],
            'storage_limit_gb' => ['required', 'integer', 'min:1', 'max:10000'],
            'license_ends_at' => ['required', 'date'],
            'support_email' => ['required', 'email'],
            'response_sla' => ['required', 'string', 'max:60'],
            'modules' => ['array'],
            'modules.reports' => ['boolean'],
            'modules.revisions' => ['boolean'],
            'modules.automations' => ['boolean'],
            'modules.request_forms' => ['boolean'],
        ]);

        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json(
            $this->ownerPortal->createCompany($user, $payload),
            201,
        );
    }

    public function companyDetail(Request $request, int $companyId): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json($this->ownerPortal->companyDetail($user, $companyId));
    }

    public function updateCompany(Request $request, int $companyId): JsonResponse
    {
        $payload = $request->validate([
            'company_name' => ['required', 'string', 'max:160'],
            'status' => ['required', 'string', 'in:active,paused,inactive'],
            'timezone' => ['required', 'string', 'max:64'],
            'locale' => ['required', 'string', 'max:12'],
            'support_email' => ['required', 'email'],
            'response_sla' => ['required', 'string', 'max:60'],
        ]);

        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json($this->ownerPortal->updateCompany($user, $companyId, $payload));
    }

    public function updateSubscription(Request $request, int $companyId): JsonResponse
    {
        $payload = $request->validate([
            'plan_name' => ['required', 'string', 'max:80'],
            'user_limit' => ['required', 'integer', 'min:1', 'max:5000'],
            'storage_limit_gb' => ['required', 'integer', 'min:1', 'max:10000'],
            'license_ends_at' => ['required', 'date'],
            'modules' => ['array'],
            'modules.reports' => ['boolean'],
            'modules.revisions' => ['boolean'],
            'modules.automations' => ['boolean'],
            'modules.request_forms' => ['boolean'],
        ]);

        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json($this->ownerPortal->updateSubscription($user, $companyId, $payload));
    }

    public function support(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json($this->ownerPortal->support($user));
    }

    public function requests(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json($this->ownerPortal->requests($user));
    }

    public function registerSupportAccess(Request $request, int $companyId): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json($this->ownerPortal->registerSupportAccess($user, $companyId));
    }
}
