import ragService from '../services/ai/ragService.js';

/**
 * Asian Christian Academy of India - Knowledge Base Feeding Script
 * Use this script to add new organizational policies, SOPs, and handbooks to the AI.
 */

const newAcaPolicies = [
  {
    id: "aca_policy_leave_2026",
    category: "HR & Leave Policy",
    title: "Asian Christian Academy Faculty & Staff Leave Policy",
    content: "Asian Christian Academy of India provides 12 Casual Leaves (CL), 12 Sick Leaves (SL), and 15 Earned Leaves (EL) annually for permanent staff. Maternity leave is 26 weeks with full pay. Paternity leave is 7 calendar days. All leave requests must be applied at least 2 days in advance unless emergency sick leave."
  },
  {
    id: "aca_policy_it_assets_2026",
    category: "IT & Hardware",
    title: "ACA India IT Asset Allocation & Helpdesk SOP",
    content: "IT assets (laptops, desktop workstations, projectors) are assigned to ACA staff via IT Helpdesk ticket requests. Laptops damaged due to negligence carry a 20% deductible fee. Purchase requisitions above ₹1 Lakh require Finance & HOB sign-off."
  },
  {
    id: "aca_policy_travel_2026",
    category: "Finance & Accounts",
    title: "ACA Travel & Out-of-Pocket Expense Policy",
    content: "Out-of-station official travel requires pre-approval from the Department Head. Daily meal allowance is capped at ₹800/day for Tier-1 cities and ₹500/day for Tier-2 cities. Original bills must be submitted within 15 days of travel."
  }
];

function feedKnowledge() {
  console.log('--------------------------------------------------');
  console.log('Feeding Organizational Knowledge to ACA HRMS-AI...');
  console.log('--------------------------------------------------');

  for (const policy of newAcaPolicies) {
    ragService.knowledgeChunks.push(policy);
    console.log(`[SUCCESS] Loaded Policy: "${policy.title}" (${policy.category})`);
  }

  console.log('\nTotal Knowledge Chunks Loaded:', ragService.knowledgeChunks.length);
  console.log('HRMS-AI Engine is now updated with ACA India policies!');
}

feedKnowledge();
