const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3300;

app.use(cors());
app.use(express.json());

// LEANN CLI wrapper endpoints - mock for testing
app.get('/api/leann/list', (req, res) => {
  // Mock LEANN list response for now
  const mockResponse = `📚 LEANN Indexes
==================================================

🏠 Current Project
   /root
   ─────────────────────────────────────────────
   1. 📁 myvault ✅
      📦 Size: 0.2 MB

==================================================
📊 Total: 1 indexes across 1 projects`;

  res.json({ 
    success: true, 
    data: mockResponse,
    raw: mockResponse,
    indexes: ['myvault']
  });
});

app.post('/api/leann/search', (req, res) => {
  const { index, query, top_k = 5 } = req.body;
  
  if (!index || !query) {
    return res.status(400).json({ error: 'index and query are required' });
  }

  // Mock LEANN search for semantic queries
  const mockSearchResults = [
    {
      score: 0.95,
      content: `# Sistema PARA - Projetos e Áreas\n\nO método PARA (Projects, Areas, Resources, Archives) é um sistema de organização baseado na ação.\n\n## Projetos Ativos\n- Integração LEANN com n8n\n- Automação de descoberta de conhecimento\n- Sistema de notificações inteligentes`
    },
    {
      score: 0.87,
      content: `# Zettelkasten - Gestão de Conhecimento\n\nSistema de notas interconectadas para captura e desenvolvimento de ideias.\n\n## Novas Conexões Identificadas\n- Automação workflow + Knowledge management\n- LEANN semantic search + PARA organization\n- n8n integration + Obsidian vault monitoring`
    },
    {
      score: 0.82,
      content: `# Activity Agent Metrics\n\nAgente de atividade que monitora e processa automaticamente novas notas do sistema Zettelkasten/PARA.\n\n## Insights Recentes\n- Aumento na criação de notas sobre automação\n- Conexões frequentes entre temas de AI e produtividade\n- Padrões de uso indicando foco em integração de sistemas`
    }
  ];

  const filteredResults = mockSearchResults.filter(result => 
    result.content.toLowerCase().includes(query.toLowerCase()) ||
    query.toLowerCase().includes('para') ||
    query.toLowerCase().includes('zettelkasten') ||
    query.toLowerCase().includes('automation') ||
    query.toLowerCase().includes('conceito')
  );

  res.json({ 
    success: true, 
    query,
    index,
    results: filteredResults.slice(0, top_k),
    mock: true,
    message: 'Using mock semantic search results - replace with real LEANN integration'
  });
});

// File system monitoring endpoints
app.get('/api/obsidian/files', (req, res) => {
  const vaultPath = '/obsidian-vaults/MyVault';
  
  if (!fs.existsSync(vaultPath)) {
    return res.status(404).json({ error: 'MyVault directory not found' });
  }

  try {
    const files = getFilesRecursively(vaultPath);
    const fileStats = files.map(file => {
      const stat = fs.statSync(file);
      return {
        path: file.replace(vaultPath, ''),
        fullPath: file,
        mtime: stat.mtime,
        size: stat.size,
        isMarkdown: file.endsWith('.md')
      };
    }).filter(file => file.isMarkdown);

    res.json({
      success: true,
      vaultPath,
      totalFiles: fileStats.length,
      files: fileStats.sort((a, b) => b.mtime - a.mtime) // newest first
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/obsidian/new-files', (req, res) => {
  const { since } = req.query; // timestamp
  const sinceDate = since ? new Date(since) : new Date(Date.now() - 24 * 60 * 60 * 1000); // 24h ago default
  
  const vaultPath = '/obsidian-vaults/MyVault';
  
  if (!fs.existsSync(vaultPath)) {
    return res.status(404).json({ error: 'MyVault directory not found' });
  }

  try {
    const files = getFilesRecursively(vaultPath);
    const newFiles = files
      .filter(file => file.endsWith('.md'))
      .map(file => {
        const stat = fs.statSync(file);
        return {
          path: file.replace(vaultPath, ''),
          fullPath: file,
          mtime: stat.mtime,
          size: stat.size
        };
      })
      .filter(file => file.mtime > sinceDate)
      .sort((a, b) => b.mtime - a.mtime);

    res.json({
      success: true,
      since: sinceDate,
      newFiles: newFiles.length,
      files: newFiles
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    leannAvailable: true, // Mock as available
    vaultAvailable: fs.existsSync('/obsidian-vaults/MyVault')
  });
});

// Helper functions
function getFilesRecursively(dir) {
  const files = [];
  const items = fs.readdirSync(dir);
  
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory()) {
      files.push(...getFilesRecursively(fullPath));
    } else {
      files.push(fullPath);
    }
  }
  
  return files;
}

function parseLeannOutput(output) {
  // Simple parser for LEANN search output
  const lines = output.split('\n');
  const results = [];
  let currentResult = null;
  
  for (const line of lines) {
    if (line.match(/^\d+\.\s+Score:/)) {
      if (currentResult) {
        results.push(currentResult);
      }
      const scoreMatch = line.match(/Score:\s+([\d.]+)/);
      currentResult = {
        score: scoreMatch ? parseFloat(scoreMatch[1]) : 0,
        content: ''
      };
    } else if (currentResult && line.trim()) {
      currentResult.content += line + '\n';
    }
  }
  
  if (currentResult) {
    results.push(currentResult);
  }
  
  return results;
}

app.listen(PORT, '0.0.0.0', () => {
  console.log(`LEANN API Server running on http://0.0.0.0:${PORT}`);
  console.log(`LEANN CLI available: true (mock mode)`);
  console.log(`Obsidian Vault available: ${fs.existsSync('/obsidian-vaults/MyVault')}`);
});