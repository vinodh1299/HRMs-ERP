import localBridge from './localInferenceBridge.js';

/**
 * RAGService
 * Grounded Retrieval-Augmented Generation for ACA India Policies & Documents
 */
class RAGService {
  constructor() {
    this.knowledgeChunks = [
      {
        id: "chunk_leave_01",
        category: "HR & Leaves",
        title: "Asian Christian Academy Leave & Holiday Policy",
        content: "Employees at Asian Christian Academy of India receive 12 Casual Leaves (CL), 12 Sick Leaves (SL), and 15 Earned Leaves (EL) per calendar year. Unused SL up to 30 days can be accumulated. Maternity leave is 26 weeks with full pay.",
      },
      {
        id: "chunk_attendance_01",
        category: "Attendance & Shifts",
        title: "Working Hours & Attendance Regularization",
        content: "Standard campus operating hours are 9:00 AM to 5:30 PM, Monday through Friday. A grace period of 15 minutes is allowed up to 3 times per month. Regularization requests must be submitted within 3 working days of missed clock-ins.",
      },
      {
        id: "chunk_it_01",
        category: "IT & Assets",
        title: "IT Equipment & Support Helpdesk SOP",
        content: "All hardware assets (laptops, projectors, workstations) issued to faculty and staff are managed by the IT Helpdesk. High-value equipment purchase requests exceeding ₹1 Lakh require Finance Department and HOB approval.",
      },
      {
        id: "chunk_finance_01",
        category: "Finance & Expenses",
        title: "Travel & Expense Reimbursement SOP",
        content: "Travel claims and out-of-pocket expenses must be filed with valid receipt scans within 15 days of expenditure. Claims above ₹5,000 require department head sign-off.",
      }
    ];
  }

  /**
   * Search knowledge base using hybrid query matching
   */
  async searchPolicyDocuments(query, topK = 3) {
    const qLower = query.toLowerCase();
    const words = qLower.split(/\s+/).filter(w => w.length > 2);

    const scored = this.knowledgeChunks.map(chunk => {
      let score = 0;
      const textLower = (chunk.title + " " + chunk.content).toLowerCase();

      for (const word of words) {
        if (textLower.includes(word)) {
          score += 1.0;
        }
      }

      return {
        id: chunk.id,
        title: chunk.title,
        category: chunk.category,
        content: chunk.content,
        score: score / (words.length || 1),
      };
    });

    scored.sort((a, b) => b.score - a.score);
    return scored.slice(0, topK);
  }

  /**
   * Generates grounded RAG response
   */
  async answerPolicyQuestion(query) {
    const relevantDocs = await this.searchPolicyDocuments(query, 2);

    if (relevantDocs.length === 0 || relevantDocs[0].score === 0) {
      const fallbackAns = await localBridge.generateCompletion(query);
      return {
        answer: fallbackAns,
        citations: [],
        confidence: "Medium"
      };
    }

    const contextText = relevantDocs.map(d => `[${d.title}]: ${d.content}`).join("\n\n");
    const prompt = `Context Information:\n${contextText}\n\nQuestion: ${query}\n\nAnswer the question concisely based ONLY on the context provided above.`;

    const generatedAns = await localBridge.generateCompletion(prompt);

    return {
      answer: generatedAns,
      citations: relevantDocs.map(d => ({ title: d.title, category: d.category })),
      confidence: "High (Grounded Policy Match)"
    };
  }
}

export default new RAGService();
