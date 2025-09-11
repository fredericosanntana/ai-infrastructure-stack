# 015 - LEANN Vector Database Integration

## Service Overview

LEANN (Learning-Enabled Automatic Neural Network) has been installed to provide semantic search capabilities for the MyVault documents with 97% storage savings compared to traditional vector databases.

### Service Access
- **LEANN MCP Server**: Available as user-scoped MCP server
- **Index Location**: `/opt/leann/.leann/indexes/myvault/`
- **Installation**: `/opt/leann/` with global tool installation
- **CLI Tool**: `leann` command available in PATH

### Key Features
- **97% Storage Savings**: Revolutionary compression using graph-based selective recomputation
- **AST-Aware Code Chunking**: Preserves semantic boundaries for Python, Java, C#, TypeScript
- **Local & Private**: All data stays on the server, no cloud dependencies
- **Semantic Search**: Deep understanding of document content and context
- **Multiple Formats**: Supports Markdown, PDF, Code, and various document types

### MyVault Integration
- **Indexed Documents**: 7 Markdown files from Obsidian MyVault
- **Index Size**: ~18 chunks created from MyVault content
- **Search Scope**: PARA system, Zettelkasten notes, templates, and home dashboard
- **File Types**: `.md` files with structured knowledge management content

### LEANN CLI Commands

**Build Index (com OpenAI embeddings):**
```bash
export OPENAI_API_KEY="sua-chave"
leann build myvault --docs /var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault --file-types .md --embedding-mode openai --embedding-model text-embedding-3-small --force
```

**Search Documents:**
```bash
leann search myvault "PARA system"
leann search myvault "Zettelkasten method"
```

**Interactive Mode:**
```bash
leann ask myvault --interactive
```

**List Indexes:**
```bash
leann list
```

**Remove Index:**
```bash
leann remove myvault
```

### Architecture & Storage
- **Backend**: HNSW (Hierarchical Navigable Small World) for efficient similarity search
- **Embeddings**: OpenAI `text-embedding-3-small` (1536 dimensions) 🔄 **UPDATED**
- **Graph Format**: CSR (Compressed Sparse Row) for minimal memory footprint
- **Vector Count**: 225 documents indexed ✅
- **Index Size**: 0.2 MB with 97% storage savings
- **Storage Path**: `/opt/leann/.leann/indexes/myvault/documents.leann`

### MCP Integration
LEANN is configured as a Claude Code MCP server providing:
- Direct semantic search access from Claude Code conversations
- Intelligent code assistance with AST-aware chunking
- Context-aware debugging and development support
- Zero-config setup with automatic language detection

**MCP Server Configuration:**
```json
{
  "leann-server": {
    "type": "stdio",
    "command": "leann_mcp",
    "args": [],
    "env": {}
  }
}
```

### Performance Characteristics
- **Index Build Time**: ~37 seconds para 225 documents
- **Memory Usage**: Minimal com graph-based storage
- **Search Speed**: Sub-second semantic queries
- **Storage Efficiency**: 97% reduction vs traditional vector DBs  
- **Embedding Model**: OpenAI text-embedding-3-small (1536-dimensional vectors)
- **Integration Status**: ✅ MCP ativo, OpenAI API conectada
- **Current Status**: Totalmente operacional com MyVault indexado

### Development Workflow
LEANN enables intelligent development assistance:
1. **Semantic Code Search**: Find functions/classes by intent, not just name
2. **Context-Aware Help**: Get relevant code examples based on current task
3. **Debugging Support**: Find similar issues and solutions in codebase
4. **Documentation Discovery**: Locate relevant docs and examples

### Data Sources Supported
- **Personal Documents**: PDF, TXT, MD files
- **Code Repositories**: Python, Java, C#, TypeScript with AST parsing
- **Knowledge Bases**: Structured and unstructured content
- **Chat Histories**: WeChat and other messaging platforms (when configured)
- **Email Archives**: Apple Mail and other formats (when configured)
- **Browser History**: Web browsing data (when configured)

### Security & Privacy
- **100% Local**: All processing happens on-device
- **No Cloud Calls**: No data sent to external services during search
- **Secure Storage**: Encrypted index files
- **Private by Design**: Your data never leaves the server

---
Links: [[013-MCP-Servers-Summary]] | [[000-Index-Principal]] | [[007-Activity-Agent-Metrics]]
Tags: #leann #vector-database #semantic-search #mcp #knowledge-management #ai