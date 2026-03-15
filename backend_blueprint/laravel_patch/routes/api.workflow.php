<?php

use App\Http\Controllers\Api\Workflow\AuthController;
use App\Http\Controllers\Api\Workflow\WorkspaceController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function (): void {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
});

Route::middleware('auth:sanctum')->group(function (): void {
    Route::prefix('auth')->group(function (): void {
        Route::put('/onboarding', [AuthController::class, 'onboarding']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });

    Route::get('/dashboard', [WorkspaceController::class, 'dashboard']);

    Route::get('/tasks', [WorkspaceController::class, 'tasks']);
    Route::get('/tasks/meta', [WorkspaceController::class, 'taskMeta']);
    Route::post('/tasks', [WorkspaceController::class, 'createTask']);
    Route::post('/tasks/{taskId}/start', [WorkspaceController::class, 'startTask']);
    Route::post('/tasks/{taskId}/comment', [WorkspaceController::class, 'commentTask']);
    Route::post('/tasks/{taskId}/meeting', [WorkspaceController::class, 'scheduleTaskMeeting']);
    Route::post('/tasks/{taskId}/submit', [WorkspaceController::class, 'submitTask']);

    Route::get('/revisions', [WorkspaceController::class, 'revisions']);
    Route::post('/revisions/{revisionId}/approve', [WorkspaceController::class, 'approveRevision']);
    Route::post('/revisions/{revisionId}/request', [WorkspaceController::class, 'requestRevision']);
    Route::post('/revisions/{revisionId}/employee-update', [WorkspaceController::class, 'markRevisionUpdated']);

    Route::get('/team', [WorkspaceController::class, 'team']);
    Route::post('/team/members/{memberId}/note', [WorkspaceController::class, 'addManagerNote']);

    Route::get('/performance', [WorkspaceController::class, 'performance']);

    Route::get('/reports', [WorkspaceController::class, 'reports']);
    Route::post('/reports', [WorkspaceController::class, 'createReport']);

    Route::get('/settings/general', [WorkspaceController::class, 'generalSettings']);
    Route::put('/settings/general', [WorkspaceController::class, 'saveGeneralSettings']);

    Route::get('/help-center', [WorkspaceController::class, 'helpCenter']);
});
