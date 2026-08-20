import { MsEdgeTTS, OUTPUT_FORMAT } from 'msedge-tts';

class EdgeTtsService {
  constructor() {
    this.defaultVoice = 'en-US-GuyNeural'; // Crisp, bold deep male voice
    this.indianMaleVoice = 'en-IN-PrabhatNeural'; // Indian English neural male voice
  }

  /**
   * Generate MP3 audio buffer from text using Microsoft Edge Neural TTS
   * @param {string} text Text to synthesize
   * @param {string} voice Optional voice ID
   * @returns {Promise<Buffer>} MP3 Audio Buffer
   */
  async generateSpeechBuffer(text, voice = null) {
    const selectedVoice = voice || this.defaultVoice;
    const tts = new MsEdgeTTS();

    try {
      await tts.setMetadata(selectedVoice, OUTPUT_FORMAT.AUDIO_24KHZ_96KBITRATE_MONO_MP3);
      const { audioStream } = tts.toStream(text);

      const chunks = [];
      return new Promise((resolve, reject) => {
        audioStream.on('data', (chunk) => chunks.push(chunk));
        audioStream.on('end', () => resolve(Buffer.concat(chunks)));
        audioStream.on('error', (err) => reject(err));
      });
    } catch (err) {
      console.error('[EdgeTTS Service Error]:', err);
      throw err;
    }
  }
}

export default new EdgeTtsService();
