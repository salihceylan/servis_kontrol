<?php

namespace App\Http\Controllers\Api\Workflow;

use App\Http\Controllers\Controller;
use App\Services\Workflow\WorkflowApiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(
        private readonly WorkflowApiService $workflow,
    ) {
    }

    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $session = $this->workflow->attemptLogin(
            email: $credentials['email'],
            password: $credentials['password'],
            ipAddress: $request->ip(),
        );

        if ($session === null) {
            throw ValidationException::withMessages([
                'email' => ['E-posta veya parola gecersiz.'],
            ]);
        }

        return response()->json($session);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $this->workflow->recordForgotPasswordRequest(
            email: $payload['email'],
            ipAddress: $request->ip(),
        );

        return response()->json([
            'message' => 'Parola sifirlama baglantisi gonderildi.',
        ]);
    }

    public function signUpRequest(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'company_name' => ['required', 'string', 'max:160'],
            'full_name' => ['required', 'string', 'max:160'],
            'email' => ['required', 'email'],
            'phone' => ['nullable', 'string', 'max:40'],
        ]);

        $this->workflow->recordSignUpRequest(
            companyName: $payload['company_name'],
            fullName: $payload['full_name'],
            email: $payload['email'],
            phone: $payload['phone'] ?? null,
            ipAddress: $request->ip(),
        );

        return response()->json([
            'message' => 'Kayit talebiniz alindi.',
        ]);
    }

    public function onboarding(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'full_name' => ['required', 'string', 'max:160'],
            'department' => ['required', 'string', 'max:120'],
            'job_title' => ['required', 'string', 'max:120'],
            'work_preference' => ['nullable', 'string', 'max:120'],
            'notification_channels' => ['array'],
            'notification_channels.*' => ['string', 'in:system,email,slack'],
            'wants_quick_tour' => ['required', 'boolean'],
        ]);

        /** @var \App\Models\User $user */
        $user = $request->user();

        return response()->json([
            'user' => $this->workflow->completeOnboarding($user, $payload),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        if ($user->currentAccessToken() !== null) {
            $user->currentAccessToken()->delete();
        }

        Auth::guard('web')->logout();

        return response()->json([
            'message' => 'Oturum kapatildi.',
        ]);
    }
}
