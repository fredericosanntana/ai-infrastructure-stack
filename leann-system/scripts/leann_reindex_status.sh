#!/bin/bash
# Script para verificar status do LEANN Auto-Reindex

echo "🔍 === STATUS LEANN AUTO-REINDEX ==="
echo ""

# Status do serviço
echo "🟢 Serviço systemd:"
systemctl is-active leann-auto-reindex --quiet && echo "   ✅ ATIVO" || echo "   ❌ INATIVO"

# Status detalhado
echo ""
echo "📊 Estatísticas:"
python3 /opt/leann/leann_auto_reindex.py status

# Últimas linhas do log
echo ""
echo "📝 Últimas atividades (últimas 10 linhas):"
tail -n 10 /var/log/leann-auto-reindex.log 2>/dev/null || echo "   Log não encontrado"

# Processos relacionados
echo ""
echo "🔄 Processos ativos:"
ps aux | grep "leann_auto_reindex\|leann build" | grep -v grep || echo "   Nenhum processo LEANN ativo"

# Tamanho do índice
echo ""
echo "📦 Índice LEANN:"
leann list | grep myvault || echo "   Índice não encontrado"