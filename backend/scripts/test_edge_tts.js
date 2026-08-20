import edgeTtsService from '../services/ai/edgeTtsService.js';
import fs from 'fs';
import path from 'path';

async function testEdgeTts() {
  console.log('🧪 Testing Microsoft Edge Neural Speech Synthesis...');
  try {
    const text = "Hello Vinodh! I am Mark, your voice assistant. I can navigate screens, apply leaves, and manage your HRMS ERP.";
    const buffer = await edgeTtsService.generateSpeechBuffer(text);
    console.log(`✅ Success! Generated ${buffer.length} bytes of neural MP3 audio stream.`);
    
    const outputPath = path.join(process.cwd(), 'test_edge_output.mp3');
    fs.writeFileSync(outputPath, buffer);
    console.log(`📁 Test neural audio saved to ${outputPath}`);
  } catch (err) {
    console.error('❌ Edge TTS Test Failed:', err);
  }
}

testEdgeTts();
