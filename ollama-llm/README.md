# Ollama LLM Local Integration

## Overview
Local Large Language Model (LLM) implementation using Ollama for private, on-premise AI processing without external API dependencies.

## Technical Specifications

### Installed Model
- **Model**: Qwen 2.5 3B Instruct
- **Version**: qwen2.5:3b-instruct-q4_0
- **Size**: 1.8 GB
- **Quantization**: Q4_0 (4-bit)
- **Performance**: ~120 MB/s download, 2-3s response time
- **Memory**: 2.2 GB RAM required
- **Context Window**: 4096 tokens (configured)
- **Max Context**: 32768 tokens (capacity)

### Server Configuration
- **Host**: 0.0.0.0 (all interfaces)
- **Port**: 11434
- **Backend**: CPU (Intel Haswell)
- **Threads**: 8
- **Batch Size**: 512

## n8n Integration

### Main Endpoint
```
http://172.18.0.1:11434/api/generate
```

### HTTP Request Node Configuration
```json
{
  "method": "POST",
  "url": "http://172.18.0.1:11434/api/generate",
  "bodyType": "json",
  "jsonBody": {
    "model": "qwen2.5:3b-instruct-q4_0",
    "prompt": "{{ $json.prompt }}",
    "stream": false,
    "options": {
      "temperature": 0.7,
      "top_p": 0.9,
      "max_tokens": 2048
    }
  }
}
```

## Available Endpoints

### Text Generation
- **URL**: `http://172.18.0.1:11434/api/generate`
- **Method**: POST
- **Purpose**: Text generation and responses

### Chat Completion
- **URL**: `http://172.18.0.1:11434/api/chat`
- **Method**: POST
- **Purpose**: Contextual conversation

### Embeddings
- **URL**: `http://172.18.0.1:11434/api/embeddings`
- **Method**: POST
- **Purpose**: Text vectorization

### Model Management
- **List Models**: `GET http://172.18.0.1:11434/api/tags`
- **Pull Model**: `POST http://172.18.0.1:11434/api/pull`
- **Delete Model**: `DELETE http://172.18.0.1:11434/api/delete`

## Use Cases

### 1. Sentiment Analysis
```javascript
const response = await $http.request({
  method: 'POST',
  url: 'http://172.18.0.1:11434/api/generate',
  body: {
    model: 'qwen2.5:3b-instruct-q4_0',
    prompt: `Analyze the sentiment: "${$json.text}"`,
    stream: false
  }
});
```

### 2. Document Summarization
```javascript
const summary = await $http.post('http://172.18.0.1:11434/api/generate', {
  model: 'qwen2.5:3b-instruct-q4_0',
  prompt: `Summarize: ${$json.document}`,
  stream: false,
  options: { max_tokens: 500 }
});
```

### 3. Ticket Classification
```json
{
  "model": "qwen2.5:3b-instruct-q4_0",
  "prompt": "Classify this support ticket: [text]",
  "stream": false
}
```

## Performance Metrics

### Response Times
- **First request**: ~12.8s (cold start + model loading)
- **Subsequent requests**: 2-3s
- **Long prompts (>20k tokens)**: 2-3 minutes
- **Token generation**: ~30-50 tokens/second

### Resource Usage
- **RAM idle**: ~31MB
- **RAM with model**: ~2.2GB
- **CPU during inference**: 60-80% (8 threads)
- **Disk space**: 1.8GB (model)

## Security & Privacy

### Advantages of Local LLM
✅ **100% Private Data** - No information leaves the server
✅ **No API Costs** - Completely free after setup
✅ **Reduced Latency** - No cloud round-trip
✅ **Full Control** - Customization and fine-tuning possible
✅ **Compliance** - Automatically meets LGPD/GDPR requirements

## Management Commands

### Service Management
```bash
# Check status
ps aux | grep ollama
netstat -tulpn | grep 11434

# Restart with correct configuration
pkill ollama
OLLAMA_HOST=0.0.0.0:11434 nohup ollama serve > /tmp/ollama.log 2>&1 &

# List installed models
ollama list

# Download new model
ollama pull llama2:7b
ollama pull codellama:13b
```

### Manual Testing
```bash
# Local test
curl -X POST http://localhost:11434/api/generate \
  -d '{"model": "qwen2.5:3b-instruct-q4_0", "prompt": "Hello", "stream": false}'

# From n8n container
curl -X POST http://172.18.0.1:11434/api/generate \
  -d '{"model": "qwen2.5:3b-instruct-q4_0", "prompt": "Test", "stream": false}'
```

## n8n Workflow Integration

### Knowledge Base Q&A
1. **Webhook Trigger** → Receives question
2. **LEANN Search** → Searches context in MyVault
3. **Ollama Generate** → Generates context-based response
4. **Response** → Returns enriched response

### Email Auto-Reply
1. **Email Trigger** → New message
2. **Ollama Classify** → Categorizes email
3. **Switch** → Routes by category
4. **Ollama Generate** → Creates appropriate response
5. **Send Email** → Sends response

## Troubleshooting

### Error: ECONNREFUSED
**Solution**: Ollama not listening on all interfaces
```bash
pkill ollama
OLLAMA_HOST=0.0.0.0:11434 ollama serve &
```

### Error: Model not found
**Solution**: Model was removed, reinstall
```bash
ollama pull qwen2.5:3b-instruct-q4_0
```

### Error: Context length exceeded
**Solution**: Prompt too large, use truncation option
```json
{
  "options": {
    "num_ctx": 2048
  }
}
```

### Slow Performance
**Solutions**:
1. Reduce context window: `"num_ctx": 2048`
2. Use smaller model: `ollama pull qwen2:1.5b`
3. Increase threads: `"num_thread": 16`

## Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Ollama Server | ✅ Operational | Port 11434 |
| Qwen 2.5 Model | ✅ Installed | 1.8GB |
| n8n Integration | ✅ Functional | IP 172.18.0.1 |
| Performance | ✅ Adequate | 2-3s response |
| Logs | ✅ Active | /tmp/ollama.log |

## Next Steps

1. **Fine-tuning**: Train model with domain-specific data
2. **Multi-model**: Add specialized models (code, math, etc)
3. **Caching**: Implement response caching for frequent queries
4. **Monitoring**: Grafana dashboard for Ollama metrics
5. **Backup**: Model backup system
6. **GPU Support**: Investigate GPU acceleration

## Related Resources

- [n8n Advanced AI Workflows](../ai-agents/README.md)
- [LEANN Semantic Search](../leann-system/README.md)
- [Docker Infrastructure](../docker-configs/README.md)