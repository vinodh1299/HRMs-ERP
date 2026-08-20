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
    provider: 'ElevenLabs + Self-Hosted Open Weights',
    elevenLabsEnabled: !!process.env.ELEVENLABS_API_KEY,
    timestamp: new Date().toISOString()
  });
});

/**
 * ElevenLabs Text-to-Speech Endpoint
 */
router.post('/tts', async (req, res) => {
  try {
    const { text, voiceId } = req.body;
    if (!text) {
      return res.status(400).json({ error: 'Text is required for TTS.' });
    }

    const apiKey = process.env.ELEVENLABS_API_KEY;
    // Default ElevenLabs Deep Male Voice ID ("Adam")
    const targetVoice = voiceId || 'pNInz6obpgDQGcFmaJgB';

    if (apiKey) {
      const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${targetVoice}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': apiKey,
        },
        body: JSON.stringify({
          text,
          model_id: 'eleven_monolingual_v1',
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
          },
        }),
      });

      if (!response.ok) {
        throw new Error(`ElevenLabs API error: ${response.statusText}`);
      }

      const audioBuffer = await response.arrayBuffer();
      res.set('Content-Type', 'audio/mpeg');
      return res.send(Buffer.from(audioBuffer));
    } else {
      // Return TTS metadata fallback if key not configured
      return res.json({
        fallback: true,
        message: 'ElevenLabs key not set. Using high-clarity Web Audio Speech engine.',
        text
      });
    }
  } catch (err) {
    console.error('[ElevenLabs TTS Error]:', err);
    res.status(500).json({ error: 'TTS Generation Error', details: err.message });
  }
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
