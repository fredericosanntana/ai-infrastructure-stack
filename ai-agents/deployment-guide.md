# 🤖 N8N AI Agents Deployment Guide

## 📋 Overview
Este guia fornece instruções completas para implementar os agentes de IA no n8n integrados com LEANN API.

## 🏗️ Agentes Implementados

### 1. **Base AI Agent Template** (`base-agent-template.json`)
- Template base para todos os agentes
- Integração padrão LEANN API
- Webhook trigger configurável
- Error handling básico

### 2. **Knowledge Manager Agent** (`knowledge-manager-agent.json`)
- **Função**: Curadoria automática de conhecimento PARA/Zettelkasten
- **Webhook**: `/knowledge-manager`
- **Recursos**:
  - Análise semântica de conteúdo
  - Categorização automática PARA
  - Criação de links bidirecionais Zettelkasten
  - Auto-cleanup do Inbox (cron: `0 */6 * * *`)

### 3. **Task Intelligence Agent** (`task-intelligence-agent.json`)
- **Função**: Automação inteligente de tarefas
- **Webhook**: `/task-intelligence`
- **Recursos**:
  - Análise contextual de tarefas
  - Seleção automática de ferramentas
  - Execução multi-step com retry logic
  - Suporte HTTP e Command execution

### 4. **Communication Hub Agent** (`communication-hub-agent.json`)
- **Função**: Processamento inteligente de comunicações
- **Webhook**: `/communication-hub`
- **Recursos**:
  - Monitoramento IMAP automático (cron: `*/2 * * * *`)
  - Análise de sentiment e intent
  - Respostas automáticas contextuais
  - Escalação inteligente para casos críticos

### 5. **Monitoring & Analytics Agent** (`monitoring-analytics-agent.json`)
- **Função**: Análise proativa de métricas
- **Webhook**: `/monitoring-alert`
- **Recursos**:
  - Coleta de métricas Prometheus (cron: `*/15 * * * *`)
  - Análise LEANN cache performance
  - Detecção de anomalias automatizada
  - Alertas críticos e ações corretivas

### 6. **Content Intelligence Agent** (`content-intelligence-agent.json`)
- **Função**: Processamento avançado de conteúdo web
- **Webhook**: `/content-intelligence`
- **Recursos**:
  - Web scraping inteligente
  - Análise de relevância contextual
  - Curadoria automática para MyVault
  - Discovery diário de conteúdo (cron: `0 6 * * *`)

## 🚀 Deployment Instructions

### Pré-requisitos
1. ✅ n8n container rodando com environment variables configuradas
2. ✅ LEANN HTTP API ativa (porta 3001)
3. ✅ OpenAI API Key configurada
4. ✅ BillionMail SMTP configurado

### Passo 1: Verificar Infraestrutura
```bash
# Verificar status dos serviços
cd /opt/docker-compose && docker compose ps

# Verificar LEANN API
curl http://localhost:3001/health

# Verificar n8n API (aguardar se necessário)
curl -k https://www.n8n.dpo2u.com/rest/active-workflows
```

### Passo 2: Importar Workflows

#### Via Interface n8n (Recomendado):
1. Acesse https://www.n8n.dpo2u.com
2. Vá em "Import from File"
3. Importe cada arquivo JSON na seguinte ordem:
   - `base-agent-template.json` (para referência)
   - `knowledge-manager-agent.json`
   - `task-intelligence-agent.json`
   - `communication-hub-agent.json`
   - `monitoring-analytics-agent.json`
   - `content-intelligence-agent.json`

#### Via n8n CLI (Alternativo):
```bash
# Para cada arquivo de agente
n8n import:workflow --input /opt/n8n-agents/knowledge-manager-agent.json
```

### Passo 3: Configurar Credenciais

#### SMTP Credentials (BillionMail):
```json
{
  "name": "BillionMail SMTP",
  "type": "smtp",
  "data": {
    "user": "admin@dpo2u.com",
    "password": "BillionMail2025!",
    "host": "mail.dpo2u.com",
    "port": 587,
    "secure": false
  }
}
```

#### HTTP Bearer Token (LEANN):
```json
{
  "name": "LEANN API Token",
  "type": "httpHeaderAuth",
  "data": {
    "name": "Authorization",
    "value": "Bearer leann_api_2025"
  }
}
```

### Passo 4: Ativar Workflows
1. Para cada workflow importado:
   - Clique em "Activate Workflow"
   - Verifique se não há erros de configuração
   - Teste conexões críticas (LEANN, SMTP)

### Passo 5: Configurar Webhooks
Os seguintes endpoints estarão disponíveis:
- `https://www.n8n.dpo2u.com/webhook/knowledge-manager`
- `https://www.n8n.dpo2u.com/webhook/task-intelligence`
- `https://www.n8n.dpo2u.com/webhook/communication-hub`
- `https://www.n8n.dpo2u.com/webhook/monitoring-alert`
- `https://www.n8n.dpo2u.com/webhook/content-intelligence`

## 🧪 Testing

### Test Knowledge Manager Agent
```bash
curl -X POST https://www.n8n.dpo2u.com/webhook/knowledge-manager \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Knowledge",
    "content": "This is a test content for knowledge management",
    "source": "manual-test"
  }'
```

### Test Task Intelligence Agent
```bash
curl -X POST https://www.n8n.dpo2u.com/webhook/task-intelligence \
  -H "Content-Type: application/json" \
  -d '{
    "task_description": "Check system status and generate report",
    "priority": "medium",
    "auto_execute": false
  }'
```

### Test Content Intelligence Agent
```bash
curl -X POST https://www.n8n.dpo2u.com/webhook/content-intelligence \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/article"
  }'
```

## 📊 Monitoring & Logs

### Log Files
- Communication Hub: `/var/log/communication-hub.log`
- Monitoring Analytics: `/var/log/monitoring-analytics.log`
- Content Intelligence: `/var/log/content-intelligence.log`

### Monitoring Commands
```bash
# Monitor n8n logs
docker logs n8n --tail 50 -f

# Monitor LEANN API
systemctl status leann-api
tail -f /var/log/leann-auto-reindex.log

# Check workflow executions
curl -k https://www.n8n.dpo2u.com/rest/executions
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Workflow Import Errors
- Verificar se n8n container está com environment variables corretas
- Verificar se `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true`

#### 2. LEANN API Connection Issues
- Usar `http://172.18.0.1:3001` dentro do container n8n
- Verificar se `LEANN_API_TOKEN=leann_api_2025`

#### 3. SMTP Authentication Errors
- Verificar credenciais BillionMail
- Testar conectividade: `telnet mail.dpo2u.com 587`

#### 4. OpenAI Rate Limits
- Monitorar usage via OpenAI dashboard
- Implementar delays entre chamadas se necessário

### Performance Optimization

#### Redis Cache (LEANN)
```bash
# Monitor cache performance
curl -H "Authorization: Bearer leann_api_2025" http://localhost:3001/cache/stats

# Clear cache if needed
curl -X POST -H "Authorization: Bearer leann_api_2025" http://localhost:3001/cache/clear
```

#### Workflow Optimization
- Ajustar `timeout` em HTTP requests conforme necessário
- Usar `batch processing` para workflows com alta frequência
- Implementar `retry logic` para operações críticas

## 📈 Success Metrics

### Performance Targets
- **Latência**: < 2s para decisões simples
- **Cache Hit Rate**: > 80%
- **Availability**: > 99.5%
- **Accuracy**: > 85% para categorização

### Business Metrics
- **Automação**: > 70% redução em tarefas manuais
- **Knowledge Coverage**: > 1000 documentos indexados
- **Response Time**: < 5min para comunicações
- **Error Rate**: < 5% em execuções de workflow

## 🔐 Security Considerations

1. **API Keys**: Armazenadas em environment variables
2. **Authentication**: Bearer tokens para todas as APIs
3. **Rate Limiting**: Configurado por agente
4. **Audit Trail**: Logs completos de todas as ações
5. **Data Privacy**: Dados sensíveis protegidos

## 🚀 Next Steps

1. **Phase 2 Features**:
   - Multi-language support
   - Advanced analytics dashboard
   - Custom workflow templates
   - Integration with external APIs

2. **Optimization**:
   - Performance tuning based on usage patterns
   - AI model fine-tuning
   - Workflow efficiency improvements

3. **Scaling**:
   - Horizontal scaling for high-load scenarios
   - Load balancing between agents
   - Database optimization

---

## 🔗 Resources

- **n8n Documentation**: https://docs.n8n.io/
- **LEANN API Docs**: Available via `curl http://localhost:3001/docs`
- **OpenAI API Docs**: https://platform.openai.com/docs
- **LangChain Docs**: https://js.langchain.com/

**Deployment Status**: ✅ Ready for Production  
**Last Updated**: 2025-09-11T17:00:00.000Z  
**Version**: 1.0.0