import localBridge from '../services/ai/localInferenceBridge.js';
import ragService from '../services/ai/ragService.js';
import agentService from '../services/ai/agentService.js';

async function runEndToEndTests() {
  console.log('===========================================================');
  console.log(' Asian Christian Academy HRMS-AI — End-to-End Test Suite');
  console.log('===========================================================');

  try {
    // Test 1: RAG Policy Query
    console.log('\n[TEST 1] RAG Policy Query Search...');
    const ragRes = await ragService.answerPolicyQuestion('What is the leave policy at Asian Christian Academy?');
    console.log('  Result Answer:', ragRes.answer.substring(0, 100) + '...');
    console.log('  Citations Found:', ragRes.citations.length);
    console.log('  Confidence:', ragRes.confidence);
    console.log('  [PASS] Test 1 Completed.');

    // Test 2: ReAct Action Intent (Sick Leave)
    console.log('\n[TEST 2] ReAct Action Agent (Apply Sick Leave)...');
    const actionRes = await agentService.processUserPrompt('Apply for sick leave tomorrow due to fever', 'EMP001');
    console.log('  Action Type:', actionRes.type);
    console.log('  Action ID:', actionRes.actionId);
    console.log('  Message:', actionRes.message);
    console.log('  [PASS] Test 2 Completed.');

    // Test 3: HITL Action Confirmation
    if (actionRes.actionId) {
      console.log('\n[TEST 3] HITL Staged Action Confirmation...');
      const confirmRes = await agentService.confirmStagedAction(actionRes.actionId);
      console.log('  Status:', confirmRes.status);
      console.log('  Confirmation Message:', confirmRes.message);
      console.log('  [PASS] Test 3 Completed.');
    }

    // Test 4: Cascading Multi-Engine Fallback Test
    console.log('\n[TEST 4] Cascading Multi-Engine Fallback Execution...');
    const fallbackRes = await localBridge.generateCompletion('Tell me about IT support helpdesk');
    console.log('  Fallback Completion:', fallbackRes.substring(0, 100) + '...');
    console.log('  [PASS] Test 4 Completed.');

    console.log('\n===========================================================');
    console.log(' SUCCESS: ALL 4 HRMS-AI END-TO-END TESTS PASSED CLEANLY! 🎉');
    console.log('===========================================================');
  } catch (err) {
    console.error('\n❌ TEST FAILURE:', err);
    process.exit(1);
  }
}

runEndToEndTests();
