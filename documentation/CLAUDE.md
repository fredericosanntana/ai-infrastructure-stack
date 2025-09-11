# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🔍 Intelligent Documentation Search

Este projeto utiliza o **LEANN Vector Database** para busca semântica inteligente na documentação. Em vez de manter informações estáticas aqui, use os comandos LEANN MCP para encontrar informações atualizadas:

### Como Buscar Informações

**Para informações gerais sobre infraestrutura:**
- Use: `"infrastructure setup docker traefik"`
- Use: `"service management commands"`
- Use: `"container networking"`

**Para serviços específicos:**
- Use: `"obsidian web interface setup"`
- Use: `"n8n workflow automation"`
- Use: `"billionmail email server"`
- Use: `"prometheus grafana monitoring"`

**Para troubleshooting:**
- Use: `"troubleshooting ssl certificates"`
- Use: `"docker port conflicts"`
- Use: `"traefik routing issues"`

**Para configurações MCP:**
- Use: `"mcp servers configuration"`
- Use: `"leann semantic search"`
- Use: `"leann http api rest"`
- Use: `"firecrawl web scraping"`
- Use: `"openai mcp integration"`

### Comandos LEANN Disponíveis

**Via Claude Code MCP:**
- A busca semântica está disponível automaticamente através do LEANN MCP
- Simplesmente pergunte sobre qualquer tópico da infraestrutura
- O sistema buscará automaticamente na documentação do MyVault

**Via linha de comando:**
```bash
leann search myvault "termo de busca"
leann ask myvault --interactive
```

**Via HTTP API (para n8n e automação):**
```bash
# Health check
curl http://localhost:3001/health

# Search semântica
curl -X POST http://localhost:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{"query": "n8n workflow", "index": "myvault", "top_k": 5}'

# Ask contextual
curl -X POST http://localhost:3001/ask \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{"question": "Como configurar webhooks?", "index": "myvault"}'

# Para n8n (usar gateway Docker):
curl -X POST http://172.18.0.1:3001/search \
  -H "Authorization: Bearer leann_api_2025" \
  -H "Content-Type: application/json" \
  -d '{"query": "n8n workflow", "index": "myvault", "top_k": 5}'

# 🆕 Estatísticas do Cache Redis:
curl -H "Authorization: Bearer leann_api_2025" http://localhost:3001/cache/stats

# 🆕 Limpar Cache:
curl -X POST -H "Authorization: Bearer leann_api_2025" http://localhost:3001/cache/clear

# 🆕 Status Auto-Reindexação LEANN:
/opt/leann/leann_reindex_status.sh

# 🆕 Forçar Reindexação:
python3 /opt/leann/leann_auto_reindex.py force

# 🆕 Métricas Redis Cache:
curl http://localhost:3001/metrics | grep redis_

# 🆕 Monitoramento Cache Performance:
curl -H "Authorization: Bearer leann_api_2025" http://localhost:3001/cache/stats
```

### Vantagens da Busca Semântica (com Redis Cache + Monitoring)

✅ **Sempre atualizada**: Documentação centralizada no Obsidian MyVault  
✅ **Busca inteligente**: Encontra informações por contexto, não apenas palavras-chave  
✅ **⚡ Performance extrema**: Redis cache oferece 99.97% boost (44s → 15ms)  
✅ **Cache inteligente**: TTL 1h, chaves MD5 únicas por query  
✅ **🆕 Sistema otimizado**: Zettelkasten auditado e reestruturado (2025-09-11)  
✅ **🆕 MOCs temáticos**: 4 Maps of Content organizacionais ativas  
✅ **🆕 Tags padronizadas**: Taxonomia estruturada implementada  
✅ **🆕 Auditoria automática**: Relatórios mensais automatizados via cron  
✅ **🆕 Monitoramento visual**: 13 painéis Grafana para cache + performance  
✅ **🆕 Métricas Prometheus**: Hit rate, memory usage, response time  
✅ **🆕 Auto-reindexação**: Sistema inteligente baseado em mudanças  
✅ **Multilíngue**: Suporte a português e inglês  
✅ **Conexões**: Mostra links entre conceitos relacionados  
✅ **Histórico**: Mantém versionamento no Obsidian  

## 🚀 Quick Start

### Comandos Essenciais

**Verificar status geral:**
```bash
cd /opt/docker-compose && docker compose ps
```

**Verificar serviços MCP:**
```bash
claude mcp list
```

**Buscar documentação:**
```bash
leann search myvault "seu tópico"
```

### Serviços Principais

| Serviço | URL | Descrição |
|---------|-----|-----------|
| Traefik Dashboard | http://localhost:8080 | Proxy reverso |
| Obsidian | https://www.obsidian.dpo2u.com | Knowledge management |
| n8n | https://www.n8n.dpo2u.com | Automação de workflows |
| Grafana | https://grafana.dpo2u.com | Monitoramento e dashboards |
| Prometheus | http://localhost:9090 | Coleta de métricas |
| AlertManager | http://localhost:9093 | Gerenciamento de alertas |
| Portainer | http://localhost:9000 | Gestão de containers Docker |
| BillionMail | https://mail.dpo2u.com/billion | Servidor de email |
| LEANN HTTP API | http://localhost:3001 | API REST busca semântica + Redis Cache |
| LEANN Auto-Reindex | systemd service | Reindexação automática baseada em mudanças |
| LEANN Grafana Dashboard | https://grafana.dpo2u.com | 13 painéis para monitoramento cache + performance |

### Serviços de Monitoramento

| Serviço | Porta | Função |
|---------|-------|---------|
| Node Exporter | 9100 | Métricas do sistema |
| cAdvisor | 8080 | Métricas de containers |
| Blackbox Exporter | 9115 | Probes HTTP/HTTPS |
| Postgres Exporter | 9187 | Métricas PostgreSQL |
| Redis Exporter | 9121 | Métricas Redis |
| LEANN HTTP API | 3001 | API REST LEANN para n8n/automação |
| LEANN Auto-Reindex | systemd | Monitoramento e reindexação inteligente |

### Para Mais Informações

🔍 **Use a busca semântica LEANN** para encontrar informações detalhadas sobre qualquer serviço, configuração ou procedimento de troubleshooting. O sistema foi projetado para fornecer respostas contextuais e atualizadas baseadas na documentação completa armazenada no MyVault.

**Exemplo de busca:**
- "Como configurar um novo serviço no Traefik?"
- "Resolver problemas de certificado SSL"
- "Configurar alertas no Grafana"
- "Integrar novo webhook no n8n"

---

## 📚 Tópicos de Documentação Disponível

A documentação completa está organizada no **MyVault** e pode ser acessada via busca semântica LEANN. Os principais tópicos incluem:

### 🏗️ Infraestrutura & DevOps
- **Docker & Containers**: Configuração, networking, volumes
- **Traefik**: Reverse proxy, SSL/TLS, routing
- **Monitoring**: Prometheus, Grafana, AlertManager
- **Troubleshooting**: Guias de resolução de problemas

### 🤖 Automação & AI
- **n8n Workflows**: Automação de processos
- **🆕 n8n AI Agents**: Sistema completo de 4 agentes inteligentes
- **Activity Agent**: Relatórios automáticos PARA/Zettelkasten
- **MCP Servers**: Integração de ferramentas AI (LEANN, n8n, Firecrawl, OpenAI)
- **LEANN**: Busca semântica e indexação (OpenAI embedding)
- **LEANN HTTP API**: API REST para acesso do n8n ao LEANN (porta 3001)
- **🆕 LEANN Auto-Reindex**: Reindexação automática baseada em mudanças
- **🆕 Redis Cache**: 99.97% performance boost (44s → 15ms)
- **OpenAI MCP**: Acesso direto à API OpenAI via MCP

### 📧 Comunicação
- **BillionMail**: Servidor de email completo
- **SMTP Configuration**: Integração com containers
- **Webmail**: Interface Roundcube

### 💡 Knowledge Management
- **Obsidian**: Interface web e configuração
- **PARA System**: Organização de projetos e áreas
- **Zettelkasten**: Gestão de conhecimento otimizada
- **🆕 MOCs Temáticos**: 4 Maps of Content organizacionais
- **🆕 Sistema de Tags**: Taxonomia padronizada estruturada
- **🆕 Auditoria Automática**: Análise mensal do sistema

## 🛠️ Comandos de Emergência

### Restart Completo do Sistema
```bash
cd /opt/docker-compose
docker compose down && docker compose up -d
```

### Verificar Status dos Serviços
```bash
# Status geral
docker compose ps

# Serviços MCP (4 ativos)
claude mcp list
# leann-server (busca semântica), n8n-mcp (automação), firecrawl-mcp (web scraping), openai-mcp (GPT-5, embeddings)

# Logs importantes
docker logs traefik --tail 20
docker logs grafana --tail 20
tail -f /var/log/activity-agent/daily.log

# Status LEANN HTTP API (com Redis Cache)
systemctl status leann-api
systemctl status leann-auto-reindex
curl http://localhost:3001/health
curl -H "Authorization: Bearer leann_api_2025" http://localhost:3001/cache/stats
# Para teste de conectividade do n8n:
curl http://172.18.0.1:3001/health

# 🆕 Status Auto-Reindexação LEANN
/opt/leann/leann_reindex_status.sh
tail -f /var/log/leann-auto-reindex.log

# 🆕 Auditoria Zettelkasten (Manual)
cd /opt/zettelkasten-audit
python3 zettelkasten_audit.py
python3 tag_analysis.py
```

### Rebuild do Índice LEANN (OpenAI Embedding)
```bash
# Manual (não recomendado - use auto-reindex)
export OPENAI_API_KEY="sua-chave"
leann build myvault --docs /var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault --file-types .md --embedding-mode openai --embedding-model text-embedding-3-small --force

# 🆕 Reindexação Automática (Recomendado)
# O sistema detecta mudanças automaticamente a cada 5 minutos
# Para forçar reindexação:
python3 /opt/leann/leann_auto_reindex.py force
```

### 🆕 LEANN Auto-Reindexação
```bash
# Status completo do sistema
/opt/leann/leann_reindex_status.sh

# Controlar serviço
systemctl status leann-auto-reindex
systemctl restart leann-auto-reindex

# Monitorar logs
tail -f /var/log/leann-auto-reindex.log

# Status rápido
python3 /opt/leann/leann_auto_reindex.py status
```

---

## 🔗 Links Rápidos

| Categoria | Busca LEANN Sugerida |
|-----------|----------------------|
| **Setup Inicial** | `"infrastructure setup docker traefik"` |
| **Troubleshooting** | `"troubleshooting guide common issues"` |
| **Monitoring** | `"prometheus grafana alertmanager monitoring"` |
| **Email Server** | `"billionmail smtp configuration"` |
| **Automação** | `"n8n workflow automation activity agent"` |
| **🆕 AI Agents** | `"n8n ai agents knowledge task content monitoring"` |
| **LEANN API** | `"leann http api rest n8n integration redis cache"` |
| **🆕 Auto-Reindex** | `"leann auto reindex monitoring changes"` |
| **🆕 Redis Monitoring** | `"redis cache metrics prometheus grafana"` |
| **Knowledge Mgmt** | `"obsidian zettelkasten para system moc tags"` |
| **🆕 Sistema Tags** | `"tag system taxonomy padronizado consistente"` |
| **🆕 Auditoria** | `"zettelkasten audit links orfaos mocs"` |

**💡 Dica**: Em vez de rolar por documentação estática, use a busca semântica LEANN que entende contexto e fornece respostas precisas baseadas na documentação mais atualizada no MyVault.

---

## 🤖 n8n AI Agents System

### Sistema Completo de 4 AI Agents Implementados

O sistema de AI Agents do n8n está **100% operacional** com integração LEANN para automação inteligente:

#### **🧠 Knowledge Manager Agent**
```bash
# Endpoint: POST https://www.n8n.dpo2u.com/webhook/km-agent-test
# Função: Gestão automatizada de conhecimento + PARA categorization
curl -X POST -H "Content-Type: application/json" \
  -d '{"title": "Novo conceito", "content": "Descrição", "source": "origem"}' \
  https://www.n8n.dpo2u.com/webhook/km-agent-test
```
**Capacidades**: Busca LEANN + Análise contextual + Categorização PARA + Recomendações de localização

#### **⚡ Task Intelligence Agent**  
```bash
# Endpoint: POST https://www.n8n.dpo2u.com/webhook/task-intelligence  
# Função: Análise e execução inteligente de tarefas
curl -X POST -H "Content-Type: application/json" \
  -d '{"task_description": "Configure monitoring", "auto_execute": true, "priority": "medium"}' \
  https://www.n8n.dpo2u.com/webhook/task-intelligence
```
**Capacidades**: Análise contextual + Execução condicional + Planejamento automático + LEANN context search

#### **🌐 Content Intelligence Agent**
```bash
# Endpoint: POST https://www.n8n.dpo2u.com/webhook/content-intelligence
# Função: Análise inteligente de conteúdo web + detecção de duplicatas
curl -X POST -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/article"}' \
  https://www.n8n.dpo2u.com/webhook/content-intelligence
```  
**Capacidades**: Web scraping + Análise de conteúdo + Verificação LEANN duplicatas + Categorização

#### **📊 Monitoring Analytics Agent**
```bash
# Endpoint: POST https://www.n8n.dpo2u.com/webhook/monitoring-analytics
# Função: Monitoramento proativo da infraestrutura  
curl -X POST -H "Content-Type: application/json" \
  -d '{"report_type": "health_check", "requester": "admin"}' \
  https://www.n8n.dpo2u.com/webhook/monitoring-analytics
```
**Capacidades**: Health checks Prometheus/LEANN + Análises de performance + Relatórios proativos

### **Performance dos Agentes**
- **Response Time**: 2-5 segundos por agente
- **Concurrent Execution**: 4 agentes simultâneos testados  
- **Error Rate**: <1% (robust error handling)
- **LEANN Integration**: 100% funcional com cache Redis
- **Uptime**: 24/7 operational

### **Integração Técnica**
- **Webhook Triggers**: Endpoints REST únicos para cada agente
- **LEANN API**: http://172.18.0.1:3001/search (Bearer leann_api_2025)
- **JavaScript Processing**: Lógica customizada em Code nodes
- **Conditional Logic**: Decisões inteligentes via IF nodes  
- **Error Handling**: Timeouts e retry logic implementados

### **Casos de Uso Práticos**

**📚 Knowledge Management**: 
- Input: Novo artigo/conceito → Output: Análise + Categorização PARA + Localização sugerida

**⚙️ Task Automation**:  
- Input: Descrição de tarefa → Output: Plano estruturado + Execução automática (opcional)

**🔍 Content Analysis**:
- Input: URL de artigo → Output: Scraping + Análise + Verificação duplicatas

**🏥 System Health**:  
- Input: Request de monitoramento → Output: Status completo + Recomendações proativas

### **Documentação Completa**
Para informações detalhadas, use a busca LEANN:
```bash
leann search myvault "n8n ai agents system implementation"
leann search myvault "webhook endpoints knowledge task content monitoring"
leann search myvault "ai agents performance metrics leann integration"
```

**Status**: ✅ **SISTEMA 100% OPERACIONAL** - 4 Agentes Ativos + LEANN Integration + Performance Otimizada