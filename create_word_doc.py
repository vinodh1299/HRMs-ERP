import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def create_architecture_doc(filename):
    doc = docx.Document()
    
    # Page setup - 1 inch margins
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(1)
        section.bottom_margin = Inches(1)
        section.left_margin = Inches(1)
        section.right_margin = Inches(1)

    # Styles & Colors
    PRIMARY = RGBColor(0, 52, 112)       # Deep Navy
    SECONDARY = RGBColor(0, 163, 224)    # Cyan Blue
    TEXT_DARK = RGBColor(30, 41, 59)     # Slate Dark
    MUTED = RGBColor(100, 116, 139)      # Muted Slate

    # Title
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_title = p_title.add_run("Asian Christian Academy of India\nHRMs-ERP & Proprietary Custom AI Engine Blueprint")
    run_title.font.name = 'Arial'
    run_title.font.size = Pt(22)
    run_title.font.bold = True
    run_title.font.color.rgb = PRIMARY
    
    # Subtitle
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_sub = p_sub.add_run("Proprietary AI Strategy, Development Frameworks, Agent Portfolio & Language Evaluation\nVersion 3.0.0 Custom AI")
    run_sub.font.name = 'Arial'
    run_sub.font.size = Pt(11)
    run_sub.font.color.rgb = MUTED
    
    doc.add_paragraph() # Spacer

    # Helper function for section headings
    def add_heading(text, level=1):
        h = doc.add_paragraph()
        run = h.add_run(text)
        run.font.name = 'Arial'
        run.font.size = Pt(15 if level==1 else 12.5)
        run.font.bold = True
        run.font.color.rgb = PRIMARY
        h.paragraph_format.space_before = Pt(14)
        h.paragraph_format.space_after = Pt(6)
        return h

    # Section 1: Executive Summary
    add_heading("1. Executive Summary & Proprietary AI Vision", level=1)
    p = doc.add_paragraph()
    r = p.add_run(
        "This master architectural blueprint defines the technical specification, system design, agent portfolio, and custom development stack for building a 100% proprietary, self-hosted AI Engine for Asian Christian Academy of India. "
        "The system operates with total independence—eliminating third-party cloud API keys (zero OpenAI, zero Claude, zero Gemini API keys)—guaranteeing complete data privacy, zero per-token API costs, and sub-millisecond execution over a self-hosted neural model architecture."
    )
    r.font.name = 'Arial'
    r.font.size = Pt(10)

    # Section 2: Master Architecture Chart
    add_heading("2. Master System Architecture Chart (Self-Hosted Custom AI)", level=1)
    
    chart_box = doc.add_paragraph()
    chart_box.paragraph_format.space_before = Pt(6)
    chart_box.paragraph_format.space_after = Pt(6)
    
    chart_text = (
        "+-----------------------------------------------------------------------------------------+\n"
        "|  1. FRAMEWORKS & UI ENGINE (Port 4000)                                                  |\n"
        "|  Flutter 3.x (Dart) | Riverpod & GoRouter | Web Speech STT + SpeechSynthesis TTS        |\n"
        "+-----------------------------------------------------------------------------------------+\n"
        "                                        |                                                  \n"
        "                                        v                                                  \n"
        "+-----------------------------------------------------------------------------------------+\n"
        "|  2. ASIAN CHRISTIAN ACADEMY ERP APPLICATION MODULES                                     |\n"
        "|  Dashboard (Presence/Polls) | Me (Attendance/Leaves) | Helpdesk (8 Depts) | Teams Chat |\n"
        "+-----------------------------------------------------------------------------------------+\n"
        "                                        |                                                  \n"
        "                                        v                                                  \n"
        "+-----------------------------------------------------------------------------------------+\n"
        "|  3. API GATEWAYS & BRIDGES                                                              |\n"
        "|  Central ChatService Engine (ValueNotifier Event Bus) -> Express API (Port 4001)        |\n"
        "+-----------------------------------------------------------------------------------------+\n"
        "                                        |                                                  \n"
        "                                        v                                                  \n"
        "+-----------------------------------------------------------------------------------------+\n"
        "|  4. ACTIVE & PLANNED AI AGENT ECOSYSTEM                                                 |\n"
        "|  RAG Policy Agent | Action Agent | Payroll Agent | Attendance Audit Agent | Vision Agent |\n"
        "+-----------------------------------------------------------------------------------------+\n"
        "                                        |                                                  \n"
        "                                        v                                                  \n"
        "+-----------------------------------------------------------------------------------------+\n"
        "|  5. PROPRIETARY NATIVE AI ENGINE (Self-Hosted Custom Stack)                            |\n"
        "|  Proprietary LLM & Tensor Engine (Zero API Keys) <-> Enterprise Relational & Vector DB  |\n"
        "+-----------------------------------------------------------------------------------------+\n"
        "                                        : (Expansion Phase)                                \n"
        "                                        v                                                  \n"
        "+-----------------------------------------------------------------------------------------+\n"
        "|  6. FUTURE AI TECHNOLOGY ROADMAP                                                        |\n"
        "|  Rust High-Performance Engine | Multi-Agent Swarm | SSE Streaming | GraphRAG | On-Device  |\n"
        "+-----------------------------------------------------------------------------------------+"
    )
    
    r_chart = chart_box.add_run(chart_text)
    r_chart.font.name = 'Courier New'
    r_chart.font.size = Pt(8)
    r_chart.font.bold = True
    r_chart.font.color.rgb = PRIMARY

    # Section 3: Custom AI Development Stack & Codebase Engineering
    add_heading("3. Custom AI Development Stack & Codebase Engineering", level=1)
    
    tech_stack = [
        ("1. AI Model Fine-Tuning Framework (Python, PyTorch & LoRA)", "The neural model is fine-tuned on custom Asian Christian Academy of India HR policies, leave rules, and SOPs using PyTorch, HuggingFace Transformers, and PEFT / LoRA (Low-Rank Adaptation)."),
        ("2. Low-Latency Local Inference Engine (vLLM & llama.cpp)", "Model execution runs on a self-hosted inference engine powered by vLLM and llama.cpp (GGUF / GGML 4-bit & 8-bit Quantization), giving sub-millisecond tensor response speeds while keeping 100% of employee data private on local servers."),
        ("3. Custom BPE Tokenizer & Domain Lexicon", "A custom Byte-Pair Encoding (BPE) tokenizer vocabulary is trained on ACA India organizational terminology, department codes (CPD, HOB, Media, Maintenance), and employee designations."),
        ("4. High-Performance Core Language Strategy (Rust & C++)", "For core high-throughput tensor operations and vector search indexing, the underlying engine uses Rust (Burn / Candle framework) and C++ / CUDA for memory-safe execution on GPU hardware."),
        ("5. Backend Gateway & Microservice Codebase (Node.js / Express)", "The backend microservice (port 4001) manages RAG document retrieval (ragService.js), autonomous function calling (agentService.js), and Human-In-The-Loop safety staging (agent_pending_actions)."),
        ("6. Multi-Platform Client & Voice Interface (Flutter & Web Speech API)", "The client app (port 4000) is built with Flutter 3.x (Dart), featuring hands-free Speech-To-Text mic recognition (Web Speech API) and automatic SpeechSynthesis Voice-Over output with manual replay speaker buttons.")
    ]

    for title, desc in tech_stack:
        p_t = doc.add_paragraph()
        p_t.paragraph_format.space_before = Pt(3); p_t.paragraph_format.space_after = Pt(3)
        r_title = p_t.add_run(f"• {title}: ")
        r_title.font.name = 'Arial'; r_title.font.size = Pt(9.5); r_title.font.bold = True; r_title.font.color.rgb = PRIMARY
        r_desc = p_t.add_run(desc)
        r_desc.font.name = 'Arial'; r_desc.font.size = Pt(9.5); r_desc.font.color.rgb = TEXT_DARK

    # Section 4: AI Agent Portfolio (Created vs Planned)
    add_heading("4. Asian Christian Academy AI Agent Ecosystem", level=1)
    
    active_agents = [
        ("📚 RAG Policy Search Agent (ragService.js)", "Performs grounded vector & BM25 search over indexed company policy documents."),
        ("⚡ Autonomous Action Agent (agentService.js)", "Converts user prompts into backend tool calls (createTicket, applyLeave, sendMessageToUserOrChannel)."),
        ("💬 Central Synchronization Agent (ChatService)", "Event bus synchronizing chat messages across floating chatbots, drawers, and team channels."),
        ("🎙️ Voice & Speech Agent (VoiceHelper)", "Hands-free mic speech recognition & automatic SpeechSynthesis Voice-Over output."),
        ("🛡️ HITL Safety Agent", "Evaluates risk classification (LOW/MEDIUM/HIGH) and stages high-risk actions in agent_pending_actions.")
    ]

    add_heading("4.1 Active Agents Created So Far", level=2)
    for title, desc in active_agents:
        p_a = doc.add_paragraph()
        r_t = p_a.add_run(f"• {title}: ")
        r_t.font.name = 'Arial'; r_t.font.size = Pt(9.5); r_t.font.bold = True; r_t.font.color.rgb = PRIMARY
        r_d = p_a.add_run(desc)
        r_d.font.name = 'Arial'; r_d.font.size = Pt(9.5); r_d.font.color.rgb = TEXT_DARK

    future_agents = [
        ("💰 Payroll & Tax Intelligence Agent", "Computes salary breakdowns, tax regime optimizations, and reimbursement claims."),
        ("⏰ Attendance & Shift Anomaly Audit Agent", "Scans clock-in patterns and proactively suggests regularization workflows."),
        ("📸 Multi-Modal Vision & OCR Agent", "Extracts line items from expense receipts, medical bills, and onboarding ID cards."),
        ("🏷️ IT Diagnostic & Procurement Specialist", "Tracks asset health, compares vendor pricing, and monitors PO approvals (> ₹1 Lakh)."),
        ("🔍 Hierarchical Escalation Agent", "Traverses organizational reporting trees for complex cross-department escalations.")
    ]

    add_heading("4.2 New AI Agents Planned for Future Development", level=2)
    for title, desc in future_agents:
        p_f = doc.add_paragraph()
        r_t = p_f.add_run(f"• {title}: ")
        r_t.font.name = 'Arial'; r_t.font.size = Pt(9.5); r_t.font.bold = True; r_t.font.color.rgb = PRIMARY
        r_d = p_f.add_run(desc)
        r_d.font.name = 'Arial'; r_d.font.size = Pt(9.5); r_d.font.color.rgb = TEXT_DARK

    # Section 5: Programming Language Evaluation
    add_heading("5. Programming Language Evaluation for Custom AI Development", level=1)
    
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    
    hdr_cells = table.rows[0].cells
    hdr_titles = ["Language", "Suitability", "Strengths for Proprietary AI Development"]
    for i, title in enumerate(hdr_titles):
        hdr_cells[i].text = title
        shading = parse_xml(r'<w:shd {} w:fill="003470"/>'.format(nsdecls('w')))
        hdr_cells[i]._tc.get_or_add_tcPr().append(shading)
        for p in hdr_cells[i].paragraphs:
            for run in p.runs:
                run.font.name = 'Arial'; run.font.size = Pt(9.5); run.font.bold = True; run.font.color.rgb = RGBColor(255, 255, 255)

    lang_data = [
        ("🦀 Rust (RECOMMENDED CORE)", "Highest (5/5 Stars)", "Memory safety without GC pauses, zero-cost abstractions, native C/CUDA interop, blazing fast tensor execution (Burn, Candle), WebAssembly compilation."),
        ("🐍 Python", "High (4/5 Stars - R&D)", "Unrivaled AI ecosystem (PyTorch, JAX, HuggingFace, vLLM). Essential for model fine-tuning & research."),
        ("⚡ C++ / CUDA", "High (4/5 Stars - Low Level)", "Foundation of GGML, llama.cpp, and TensorRT. Maximum low-level GPU hardware control."),
        ("🔥 Mojo / Julia", "Emerging (3/5 Stars)", "Mojo compiles Python syntax to native C speed. High-performance matrix math capabilities.")
    ]

    for lang, star, desc in lang_data:
        row_cells = table.add_row().cells
        row_cells[0].text = lang
        row_cells[1].text = star
        row_cells[2].text = desc
        for cell in row_cells:
            for p in cell.paragraphs:
                for run in p.runs:
                    run.font.name = 'Arial'; run.font.size = Pt(9); run.font.color.rgb = TEXT_DARK

    doc.save(filename)
    print(f"Successfully generated Word document: {filename}")

if __name__ == "__main__":
    create_architecture_doc("/Users/acamedia/VINODH/KEKA CLONE/PROJECT_OVERALL_ARCHITECTURE.docx")
    create_architecture_doc("/Users/acamedia/VINODH/KEKA CLONE/docs/PROJECT_OVERALL_ARCHITECTURE.docx")
