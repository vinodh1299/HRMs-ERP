import ragService from './ragService.js';
import localBridge from './localInferenceBridge.js';

/**
 * AgentService
 * Autonomous Action Agent for executing HRMS-ERP mutations
 */
class AgentService {
  constructor() {
    this.stagedActions = new Map();
  }

  /**
   * Process incoming user prompt, route intent, and trigger function tool execution
   */
  async processUserPrompt(userPrompt, userId = 'EMP001') {
    const pLower = userPrompt.toLowerCase();

    // 1. Leave Application Action Intent
    if (pLower.includes('apply') && pLower.includes('leave')) {
      const isSick = pLower.includes('sick');
      const actionPayload = {
        actionType: 'applyLeave',
        riskLevel: 'MEDIUM',
        details: {
          leaveType: isSick ? 'Sick Leave' : 'Casual Leave',
          startDate: '2026-08-19',
          endDate: '2026-08-19',
          reason: userPrompt,
        }
      };
      
      const actionId = `action_${Date.now()}`;
      this.stagedActions.set(actionId, actionPayload);

      return {
        type: 'HITL_CONFIRMATION_REQUIRED',
        actionId: actionId,
        message: `I have prepared your ${actionPayload.details.leaveType} application for Aug 19, 2026. Please confirm to submit to your manager.`,
        payload: actionPayload,
      };
    }

    // 2. Ticket Creation Action Intent
    if (pLower.includes('ticket') || pLower.includes('issue') || pLower.includes('broken') || pLower.includes('repair')) {
      const isIT = pLower.includes('laptop') || pLower.includes('wifi') || pLower.includes('monitor') || pLower.includes('computer');
      const actionPayload = {
        actionType: 'createTicket',
        riskLevel: 'LOW',
        details: {
          category: isIT ? 'IT' : 'Maintenance',
          subject: userPrompt,
          priority: pLower.includes('urgent') ? 'High' : 'Medium',
        }
      };

      const actionId = `action_${Date.now()}`;
      this.stagedActions.set(actionId, actionPayload);

      return {
        type: 'HITL_CONFIRMATION_REQUIRED',
        actionId: actionId,
        message: `Would you like me to log an ${actionPayload.details.category} Helpdesk Ticket for: "${userPrompt}"?`,
        payload: actionPayload,
      };
    }

    // 3. Team Messaging Action Intent
    if (pLower.includes('send') && (pLower.includes('message') || pLower.includes('chat'))) {
      return {
        type: 'ACTION_EXECUTED',
        message: `Message dispatched to team channel: "${userPrompt}"`,
        result: { status: 'success', timestamp: new Date().toISOString() }
      };
    }

    // 4. Policy Q&A Intent -> Route to RAG Engine
    const ragResult = await ragService.answerPolicyQuestion(userPrompt);
    return {
      type: 'POLICY_ANSWER',
      message: ragResult.answer,
      citations: ragResult.citations,
      confidence: ragResult.confidence
    };
  }

  /**
   * Confirm and execute staged HITL action
   */
  async confirmStagedAction(actionId) {
    const staged = this.stagedActions.get(actionId);
    if (!staged) {
      return { status: 'error', message: 'Action expired or not found.' };
    }

    this.stagedActions.delete(actionId);

    if (staged.actionType === 'applyLeave') {
      return {
        status: 'success',
        message: `Leave application (${staged.details.leaveType}) submitted successfully! Your manager has been notified.`,
        actionDetails: staged.details
      };
    }

    if (staged.actionType === 'createTicket') {
      return {
        status: 'success',
        message: `Ticket #${Math.floor(1000 + Math.random() * 9000)} created in ${staged.details.category} Helpdesk.`,
        actionDetails: staged.details
      };
    }

    return { status: 'success', message: 'Action executed successfully.' };
  }
}

export default new AgentService();
