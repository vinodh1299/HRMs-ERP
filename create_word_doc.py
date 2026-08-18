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
    run_title = p_title.add_run("HRMs-ERP & HRMs-AI Engine\nMaster Architecture & RAG Ingestion Blueprint")
    run_title.font.name = 'Arial'
    run_title.font.size = Pt(24)
    run_title.font.bold = True
    run_title.font.color.rgb = PRIMARY
    
    # Subtitle
    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_sub = p_sub.add_run("Enterprise Architecture, RAG Knowledge Feeding Pipeline & Advanced Technology Roadmap\nVersion 2.5.0 Production | August 2026")
    run_sub.font.name = 'Arial'
    run_sub.font.size = Pt(11)
    run_sub.font.color.rgb = MUTED
    
    doc.add_paragraph() # Spacer

    # Helper function for section headings
    def add_heading(text, level=1):
        h = doc.add_paragraph()
        run = h.add_run(text)
        run.font.name = 'Arial'
        run.font.size = Pt(16 if level==1 else 13)
        run.font.bold = True
        run.font.color.rgb = PRIMARY
        h.paragraph_format.space_before = Pt(14)
        h.paragraph_format.space_after = Pt(6)
        return h

    # Section 1: Executive Summary
    add_heading("1. Executive Summary", level=1)
    p = doc.add_paragraph()
    r = p.add_run(
        "The HRMs-ERP & HRMs-AI System combines a Flutter 3.x multi-platform ERP frontend with a dedicated Node.js/Express AI microservice powered by Google Gemini generative models. "
        "The architecture delivers Policy RAG Document Search, Prompt-Driven Autonomous Action Execution (Tickets, Leaves, Messages), hands-free Speech-To-Text input, and automatic Text-To-Speech Voice-Over audio responses."
    )
    r.font.name = 'Arial'
    r.font.size = Pt(10.5)

    # Section 2: Master Architecture Chart
    add_heading("2. Master System Architecture Chart", level=1)
    
    chart_box = doc.add_paragraph()
    chart_box.paragraph_format.space_before = Pt(8)
    chart_box.paragraph_format.space_after = Pt(8)
    
    chart_text = (
        "+-----------------------------------------------------------------------------------------+\n"
        "|  1. FRAMEWORKS & UI ENGINE (Port 4000)                                                  |\n"
        "|  Flutter 3.x (Dart) | Riverpod & GoRouter | Web Speech STT + SpeechSynthesis TTS        |\n"
        "+-----------------------------------------------------------------------------------------+\n"
        "                                        |                                                  \n"
        "                                        v                                                  \n"
        "+-----------------------------------------------------------------------------------------+\n"
        "|  2. ERP APPLICATION MODULES                                                             |\n"
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
        "|  4. HRMs-AI ENGINE & RAG KNOWLEDGE INGESTION                                            |\n"
        "|  RAG Grounded Policy Chatbot (ragService)  |  Autonomous Action Agent (agentService)    |\n"
        "|  Tools: createTicket, assignTicket, applyLeave, sendMessageToUserOrChannel             |\n"
        "+-----------------------------------------------------------------------------------------+\n"
        "                                        |                                                  \n"
        "                                        v                                                  \n"
        "+-----------------------------------------------------------------------------------------+\n"
        "|  5. ENTERPRISE DATABASE & CLOUD LAYER                                                   |\n"
        "|  Google Gemini (gemini-3.6-flash / embedding-001) <-> Enterprise Relational Database    |\n"
        "+-----------------------------------------------------------------------------------------+\n"
        "                                        : (Next Phase)                                     \n"
        "                                        v                                                  \n"
        "+-----------------------------------------------------------------------------------------+\n"
        "|  6. ADVANCED TECHNOLOGIES ROADMAP                                                       |\n"
        "|  Vision AI OCR | Multi-Agent Swarm | SSE Real-time Streaming | GraphRAG | On-Device SLM   |\n"
        "+-----------------------------------------------------------------------------------------+"
    )
    
    r_chart = chart_box.add_run(chart_text)
    r_chart.font.name = 'Courier New'
    r_chart.font.size = Pt(8.5)
    r_chart.font.bold = True
    r_chart.font.color.rgb = PRIMARY

    # Section 3: Feeding Knowledge to the AI Agent (RAG Pipeline)
    add_heading("3. Feeding Knowledge to the AI Agent (RAG Ingestion Pipeline)", level=1)
    
    rag_steps = [
        ("Step 1: Document Collection & Raw Extraction", "Company knowledge is gathered from raw files including HR Leave Manuals, Employee Handbooks, IT/AV SOPs, Benefits Guidelines, and Resolved Ticket Histories."),
        ("Step 2: Semantic Chunking & Metadata Tagging", "Long documents are broken into optimal 500-1000 character overlapping text chunks. Each chunk is tagged with structured metadata (category, department, target_role, updated_timestamp)."),
        ("Step 3: High-Dimensional Vector Embedding", "Text chunks are passed through the Google Gemini Embedding API (gemini-embedding-001) to generate 3072-dimensional math vector representations."),
        ("Step 4: Dual Indexing (Vector + BM25 Full-Text)", "Chunks, metadata, and 3072-dim vector embeddings are stored in the knowledge_chunks database table with both BM25 Full-Text and Cosine Similarity vector indexes."),
        ("Step 5: Real-Time Hybrid Retrieval & Prompt Grounding", "When an employee asks a question, the query vector is generated and searched using Hybrid Search (Cosine Similarity + BM25). Top K matched contexts are injected into Gemini system prompts for zero-hallucination answers.")
    ]

    for step_title, step_desc in rag_steps:
        p_step = doc.add_paragraph()
        p_step.paragraph_format.space_before = Pt(4)
        p_step.paragraph_format.space_after = Pt(4)
        
        r_st = p_step.add_run(f"• {step_title}: ")
        r_st.font.name = 'Arial'
        r_st.font.size = Pt(10)
        r_st.font.bold = True
        r_st.font.color.rgb = PRIMARY

        r_sd = p_step.add_run(step_desc)
        r_sd.font.name = 'Arial'
        r_sd.font.size = Pt(10)
        r_sd.font.color.rgb = TEXT_DARK

    # Section 4: Layer Specifications Table
    add_heading("4. Core Subsystem Layer Breakdown", level=1)
    
    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    
    hdr_cells = table.rows[0].cells
    hdr_titles = ["Layer", "Architecture Component", "Technologies & Key Features"]
    for i, title in enumerate(hdr_titles):
        hdr_cells[i].text = title
        shading = parse_xml(r'<w:shd {} w:fill="003470"/>'.format(nsdecls('w')))
        hdr_cells[i]._tc.get_or_add_tcPr().append(shading)
        for p in hdr_cells[i].paragraphs:
            for run in p.runs:
                run.font.name = 'Arial'
                run.font.size = Pt(10)
                run.font.bold = True
                run.font.color.rgb = RGBColor(255, 255, 255)

    layers_data = [
        ("Layer 1", "Frameworks & UI Engine", "Flutter 3.x (Dart), Riverpod, GoRouter, HTML5 Web Speech API (STT), Web SpeechSynthesis API (TTS)."),
        ("Layer 2", "ERP Application Modules", "Dashboard (Presence, Clock-In), Me (Attendance, Leaves), Helpdesk (8 Departments), Teams Chat."),
        ("Layer 3", "API Gateways & Sync", "Central ChatService Event Bus (ValueNotifier) <-> Express API Gateway (http://localhost:4001/api/ai)."),
        ("Layer 4", "HRMs-AI Engine", "Intent Router, RAG Grounded Policy Chatbot (ragService.js), Autonomous Action Agent (agentService.js), Function Tools."),
        ("Layer 5", "Database & AI Cloud", "Google Gemini Cloud (gemini-3.6-flash & gemini-embedding-001), Enterprise Relational Database."),
        ("Layer 6", "Advanced Tech Roadmap", "Vision AI OCR, Multi-Agent Swarm, Real-Time SSE Token Streaming, GraphRAG Knowledge Graphs, Qdrant Vector DB, On-Device Whisper.")
    ]

    for layer_id, name, desc in layers_data:
        row_cells = table.add_row().cells
        row_cells[0].text = layer_id
        row_cells[1].text = name
        row_cells[2].text = desc
        for cell in row_cells:
            for p in cell.paragraphs:
                for run in p.runs:
                    run.font.name = 'Arial'
                    run.font.size = Pt(9.5)
                    run.font.color.rgb = TEXT_DARK

    # Section 5: Advanced Technologies Roadmap
    add_heading("5. Advanced Technologies Roadmap", level=1)
    
    tech_items = [
        ("📸 Vision AI OCR Analysis", "Integrate Gemini Vision to parse expense receipts, travel invoices, medical bills, and employee ID proofs into tickets."),
        ("👥 Multi-Agent Swarm Architecture", "Decouple monolithic AI into specialized subagents (Payroll Agent, Attendance Audit Agent, IT Diagnostic Agent) via Redis Pub/Sub."),
        ("⚡ Real-Time SSE Token Streaming", "Use Server-Sent Events (SSE) and WebSockets for token-by-token live typing effects and instant push alerts."),
        ("🔍 GraphRAG & Knowledge Graphs", "Integrate Neo4j / Memgraph to map employee reporting hierarchies, asset dependencies, and escalation trees."),
        ("💾 Dedicated Vector Database", "Migrate vector storage to Qdrant or pgvector with HNSW indexing for sub-millisecond similarity search."),
        ("📱 Zero-Latency On-Device Voice AI", "Run quantized Whisper models via WebAssembly inside browser clients for offline voice recognition.")
    ]

    for title, desc in tech_items:
        p_item = doc.add_paragraph()
        p_item.paragraph_format.space_before = Pt(4)
        p_item.paragraph_format.space_after = Pt(4)
        
        r_t = p_item.add_run(f"• {title}: ")
        r_t.font.name = 'Arial'
        r_t.font.size = Pt(10)
        r_t.font.bold = True
        r_t.font.color.rgb = PRIMARY

        r_d = p_item.add_run(desc)
        r_d.font.name = 'Arial'
        r_d.font.size = Pt(10)
        r_d.font.color.rgb = TEXT_DARK

    doc.save(filename)
    print(f"Successfully generated Word document: {filename}")

if __name__ == "__main__":
    create_architecture_doc("/Users/acamedia/VINODH/KEKA CLONE/PROJECT_OVERALL_ARCHITECTURE.docx")
    create_architecture_doc("/Users/acamedia/VINODH/KEKA CLONE/docs/PROJECT_OVERALL_ARCHITECTURE.docx")
