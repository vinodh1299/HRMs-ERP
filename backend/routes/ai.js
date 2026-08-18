import express from 'express';
import agentService from '../services/ai/agentService.js';
import ragService from '../services/ai/ragService.js';

const router = express.Router();

/**
 * Health check endpoint
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'HRMS-AI Engine',
    provider: 'Self-Hosted Open Weights',
    thirdPartyApiKeys: false,
    timestamp: new Date().toISOString()
  });
});

/**
 * Main AI Chat & Action endpoint
 */
router.post('/chat', async (req, res) => {
  try {
    const { prompt, userId } = req.body;
    if (!prompt) {
      return res.status(400).json({ error: 'Prompt string is required.' });
    }

    const result = await agentService.processUserPrompt(prompt, userId || 'EMP001');
    res.json(result);
  } catch (err) {
    console.error('[HRMS-AI Route Error]:', err);
    res.status(500).json({ error: 'Internal AI Service Error', details: err.message });
  }
});

/**
 * Direct RAG policy search endpoint
 */
router.post('/rag/query', async (req, res) => {
  try {
    const { query } = req.body;
    if (!query) {
      return res.status(400).json({ error: 'Query string is required.' });
    }

    const result = await ragService.answerPolicyQuestion(query);
    res.json(result);
  } catch (err) {
    console.error('[HRMS-AI RAG Error]:', err);
    res.status(500).json({ error: 'RAG Search Error', details: err.message });
  }
});

/**
 * HITL Staged Action Confirmation endpoint
 */
router.post('/action/confirm', async (req, res) => {
  try {
    const { actionId } = req.body;
    if (!actionId) {
      return res.status(400).json({ error: 'actionId is required.' });
    }

    const result = await agentService.confirmStagedAction(actionId);
    res.json(result);
  } catch (err) {
    console.error('[HRMS-AI Confirm Error]:', err);
    res.status(500).json({ error: 'Action Confirmation Error', details: err.message });
  }
});

export default router;
