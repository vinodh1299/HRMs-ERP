# Asian Christian Academy of India — HRMS-ERP & Self-Hosted AI Engine Architecture Blueprint

**Document Version**: 1.0.0 (Self-Hosted Open-Weight AI Architecture)  
**Document Status**: Enterprise Master Blueprint  
**Last Reviewed**: August 2026  

---

## 1. Executive Summary & Self-Hosted AI Vision

This master architectural blueprint defines the technical specification, system design, agent portfolio, and infrastructure stack for building a **100% self-hosted, privately fine-tuned AI Engine for Asian Christian Academy of India**.

The vision transitions the system from third-party cloud API dependencies (zero OpenAI, zero Claude, zero Gemini API keys) to an **independent, self-hosted open-weight neural model runtime**. This guarantees:
1. **100% Data Privacy & Security**: Enterprise HR records, employee contracts, and attendance data never leave local private infrastructure.
2. **Zero Cloud API Billing**: Unlimited usage across all enterprise employees with zero recurring per-prompt API token costs.
3. **Low Latency Performance**: Optimized vLLM PagedAttention inference serving yielding 30–150 ms time-to-first-token (TTFT) for voice and chat touchpoints.

---

## 2. Master System Architecture Chart

```mermaid
flowchart TD
    subgraph L1 ["1. Global Client UI Engine"]
        FlutterApp["Flutter 3.x Multi-Platform App<br/>(Web, iOS, Android, Desktop)"]
        StateMgmt["Riverpod State Management & GoRouter"]
        VoiceTech["Self-hosted STT (whisper.cpp)<br/>+ platform TTS voice-over"]
        FlutterApp --> StateMgmt
        FlutterApp --> VoiceTech
    end

    subgraph L2 ["2. ACA India HRMS-ERP Modules"]
        DashMod["Home Dashboard<br/>(Clock-In/Out & Presence)"]
        MeMod["Me Module<br/>(Attendance & Leave Logs)"]
        HelpMod["Helpdesk Portals<br/>(IT, HR, Maint, Finance, CPD, HOB)"]
        ChatMod["Teams Chat Module<br/>(#general, #maintenance, DMs)"]
    end

    subgraph L3 ["3. Edge & API Gateway"]
        Edge["nginx / Cloudflare<br/>TLS 1.3 termination, WAF, rate limit"]
        ChatSync["ChatService Event Bus<br/>(ValueNotifier cross-window sync)"]
        APIGateway["Node.js / Express API<br/>(JWT auth + RBAC policy check)"]
        Edge --> APIGateway
        ChatSync -->|HTTPS / REST| Edge
    end

    subgraph L4 ["4. AI Agent Ecosystem"]
        IntentRouter{"Intent Router"}
        RAGAssistant["RAG Policy Search Agent"]
        ActionAgent["Autonomous Action Agent"]
        PayrollAgent["Payroll & Tax Intelligence"]
        AuditAgent["Attendance & Shift Audit"]
        VisionAgent["Vision OCR Expense Agent"]
        IntentRouter --> RAGAssistant
        IntentRouter --> ActionAgent
        IntentRouter -.-Node1["Planned"]-.- PayrollAgent
        IntentRouter -.-Node2["Planned"]-.- AuditAgent
        IntentRouter -.-Node3["Planned"]-.- VisionAgent
    end

    subgraph L5 ["5. Self-Hosted Inference & Data"]
        CustomLLM["Privately fine-tuned open-weight LLM<br/>(LoRA adapters, served on vLLM, single region)"]
        EnterpriseDB[("Postgres 16 + pgvector<br/>knowledge_chunks, tickets, leaves,<br/>agent_pending_actions, audit_log")]
    end

    subgraph LSEC ["Cross-cutting: Security & Operations"]
        IdP["SSO / Identity Provider"]
        Queue["Job Queue (BullMQ + Redis)"]
        Obs["Metrics, Tracing, Audit Log"]
        Backup["Encrypted Backups (RPO 24h / RTO 4h)"]
    end

    subgraph L6 ["6. Future Roadmap"]
        RustCore["Rust tensor engine (Candle)"]
        SwarmOrch["Multi-agent swarm collaboration"]
        SSEStream["Real-time SSE token streaming"]
        GraphRAG["GraphRAG knowledge graphs"]
        OnDeviceAI["WebAssembly on-device speech"]
    end

    DashMod --> ChatSync
    MeMod --> ChatSync
    HelpMod --> ChatSync
    ChatMod --> ChatSync
    L1 --> L2
    APIGateway --> IntentRouter
    L4 <--> CustomLLM
    CustomLLM <--> EnterpriseDB
    ActionAgent -->|HITL staging| EnterpriseDB
    APIGateway --- IdP
    L4 --- Queue
    L5 --- Obs
    EnterpriseDB --- Backup

    RustCore -.- CustomLLM
    GraphRAG -.- EnterpriseDB
    SSEStream -.- APIGateway
    OnDeviceAI -.- VoiceTech
    SwarmOrch -.- IntentRouter
```

---

## 3. Custom AI Infrastructure & Engineering Stack

The Asian Christian Academy of India AI Engine is developed as an in-house, self-hosted neural platform running privately fine-tuned open-weight models. The tech stack, codebase, and infrastructure components include:

1. **Model Fine-Tuning Framework (Python, PyTorch & LoRA)**:
   * The core intelligence engine uses open-weight base models (e.g. Llama 3 / Gemma 2) fine-tuned on Asian Christian Academy of India HR policies, leave rules, and SOP documents using **PyTorch**, **HuggingFace Transformers**, and **PEFT / LoRA (Low-Rank Adaptation)**.
2. **Dual-Tier Self-Hosted Inference Runtime (vLLM & llama.cpp)**:
   * Model serving is structured in two operational tiers: **vLLM (PagedAttention)** provides primary GPU serving for high concurrent campus traffic (achieving 30–150 ms time-to-first-token), with **llama.cpp (GGUF Quantization)** acting as a low-power CPU fallback server.
3. **Private Self-Hosted STT & Native Platform TTS**:
   * To preserve complete data privacy, client voice input uses self-hosted **whisper.cpp / faster-whisper** speech-to-text models hosted on the local gateway, paired with native platform SpeechSynthesis voice-over engines on client devices.
4. **Edge Security & TLS Termination (nginx & Express API Gateway)**:
   * All traffic from mobile, web, and campus devices is encrypted in transit using **TLS 1.3 HTTPS** terminated at an **nginx / Cloudflare edge node** (with WAF and rate limiting) before routing to the **Node.js / Express API service** with **JWT user authentication** and **RBAC policy enforcement**.
5. **Unified Relational & Vector Storage (Postgres 16 + pgvector)**:
   * Relational ERP tables (employees, leaves, tickets, audit logs) and 1536-dimensional RAG document embeddings (`knowledge_chunks`) are stored in a unified **Postgres 16 + pgvector** database, guaranteeing transactional consistency and simplified single-node backup routines (RPO 24h / RTO 4h).
6. **Cross-Cutting Operations (BullMQ, Redis & Security Services)**:
   * Long-running background tasks are managed via a **BullMQ + Redis** job queue. System health is monitored through open metrics and structured logging, backed by automated nightly AES-256 encrypted backups.

---

## 4. Asian Christian Academy AI Agent Ecosystem

### 4.1 Active Core Agents & Services
- **📚 RAG Policy Search Agent (`ragService.js`)**: Grounded policy Q&A over indexed HR, IT, and leave SOP documents.
- **⚡ Autonomous Action Agent (`agentService.js`)**: Converts prompts into backend tool calls (`createTicket`, `applyLeave`, `sendMessageToUserOrChannel`).
- **💬 Central Event Bus (`ChatService`)**: Cross-window synchronization service broadcasting live chat updates.
- **🎙️ Voice I/O Interface (`VoiceHelper`)**: Client-side voice interaction wrapper managing mic audio and TTS playback.
- **🛡️ HITL Safety Manager**: Staging service placing high-risk database mutations in `agent_pending_actions` for confirmation.

### 4.2 Planned Expansion Agents
- **💰 Payroll & Tax Intelligence Agent**: Payslip breakdowns, tax optimization advice, and reimbursement processing.
- **⏰ Attendance & Shift Anomaly Agent**: Automatically detects clock-in anomalies and suggests regularizations.
- **📸 Multi-Modal Vision & OCR Agent**: Auto-scans expense receipts, medical bills, and onboarding IDs into ERP tickets.
- **🏷️ IT Diagnostic & Asset Specialist**: Monitors asset health, compares vendor pricing, and tracks PO approvals above ₹1 Lakh.
- **🔍 Hierarchical Escalation Agent**: Traverses organizational reporting graphs for complex cross-department escalations.

---

## 5. Strategic Programming Language Evaluation

| Language | Evaluation & Suitability | Strengths for Self-Hosted AI | Target Architecture Role |
| :--- | :--- | :--- | :--- |
| **Rust** | 5/5 &mdash; Recommended Core | Memory safety without GC pauses, zero-cost abstractions, native C/CUDA interop, high-speed tensor libraries (Candle / Burn), WASM compilation. | **Evaluated for Future High-Throughput Native Inference Core** |
| **Python** | 4/5 &mdash; Essential Fine-Tuning | Unrivaled AI ecosystem (PyTorch, JAX, HuggingFace, vLLM). Standard language for dataset preparation and LoRA adapter fine-tuning. | **Dataset Preparation, Fine-Tuning (LoRA) & Training** |
| **C++ / CUDA** | 4/5 &mdash; Low-Level GPU Kernels | Foundation of GGUF, llama.cpp, and TensorRT. Maximum low-level GPU hardware control. | **Low-Level CUDA GPU Kernel Execution** |
| **Mojo** | 3/5 &mdash; Emerging AI Tech | Python superset compiling to native C speed with high-performance matrix math capabilities. | **Research Exploration** |

### 💡 Asian Christian Academy AI Architecture Strategy
* **Python (PyTorch & vLLM)**: Model Fine-Tuning (LoRA) & High-Concurrency GPU Inference Serving.
* **C++ / Rust (llama.cpp / Candle)**: CPU Fallback Engine & Evaluated Future High-Performance Core.
* **Node.js / Express behind nginx**: Edge API Gateway, TLS 1.3 Termination, & Application Routing.
* **Dart (Flutter)**: Cross-Platform Client UI for Web, Mobile & Desktop.
