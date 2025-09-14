#!/usr/bin/env python3
"""
Activity Agent Metrics Daemon
Coleta métricas de produtividade do Claude Code e sistema PARA/Zettelkasten
"""

import os
import sys
import time
import signal
import logging
from datetime import datetime
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import json
from pathlib import Path

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/activity-agent/metrics.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Métricas Prometheus
activities_processed_total = Counter('activities_processed_total', 'Total number of activities processed')
llm_processing_duration_seconds = Histogram('llm_processing_duration_seconds', 'Time spent processing with LLM')
llm_processing_success_total = Counter('llm_processing_success_total', 'Successful LLM processing operations')
llm_processing_errors_total = Counter('llm_processing_errors_total', 'Failed LLM processing operations')

email_delivery_success_total = Counter('email_delivery_success_total', 'Successful email deliveries')
email_delivery_failures_total = Counter('email_delivery_failures_total', 'Failed email deliveries')

# PARA System Metrics
para_projects_total = Gauge('para_projects_total', 'Number of PARA Projects')
para_areas_total = Gauge('para_areas_total', 'Number of PARA Areas')
para_resources_total = Gauge('para_resources_total', 'Number of PARA Resources')
para_archive_total = Gauge('para_archive_total', 'Number of PARA Archive items')

# Zettelkasten Metrics
zettelkasten_notes_total = Gauge('zettelkasten_notes_total', 'Total number of Zettelkasten notes')
zettelkasten_concepts_by_category = Gauge('zettelkasten_concepts_by_category', 'Number of concepts by category', ['category'])

# Activity Agent Metrics
activity_agent_last_execution_timestamp = Gauge('activity_agent_last_execution_timestamp', 'Unix timestamp of last execution')
activity_agent_execution_duration_seconds = Histogram('activity_agent_execution_duration_seconds', 'Duration of Activity Agent execution')

class ActivityAgentMetrics:
    def __init__(self, port=8000):
        self.port = port
        self.obsidian_vault_path = "/var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault"
        self.running = True
        
    def update_para_metrics(self):
        """Atualiza métricas do sistema PARA"""
        try:
            para_path = Path(self.obsidian_vault_path) / "01-PARA"
            
            if para_path.exists():
                projects = len(list((para_path / "Projects").glob("*.md"))) if (para_path / "Projects").exists() else 0
                areas = len(list((para_path / "Areas").glob("*.md"))) if (para_path / "Areas").exists() else 0
                resources = len(list((para_path / "Resources").glob("*.md"))) if (para_path / "Resources").exists() else 0
                archive = len(list((para_path / "Archive").glob("*.md"))) if (para_path / "Archive").exists() else 0
                
                para_projects_total.set(projects)
                para_areas_total.set(areas)
                para_resources_total.set(resources)
                para_archive_total.set(archive)
                
                logger.info(f"PARA Metrics - Projects: {projects}, Areas: {areas}, Resources: {resources}, Archive: {archive}")
            else:
                logger.warning("PARA directory not found")
                
        except Exception as e:
            logger.error(f"Error updating PARA metrics: {e}")
    
    def update_zettelkasten_metrics(self):
        """Atualiza métricas do Zettelkasten"""
        try:
            zk_path = Path(self.obsidian_vault_path) / "02-Zettelkasten"
            
            if zk_path.exists():
                # Contar notas permanentes
                permanent_path = zk_path / "Permanent"
                notes_count = len(list(permanent_path.glob("*.md"))) if permanent_path.exists() else 0
                zettelkasten_notes_total.set(notes_count)
                
                # Simular conceitos por categoria (baseado nos dados da documentação)
                concepts = {
                    "Technology": 1,
                    "Tools": 2, 
                    "Architecture": 0,
                    "Process": 0,
                    "Problem_Solving": 0,
                    "Security": 0
                }
                
                for category, count in concepts.items():
                    zettelkasten_concepts_by_category.labels(category=category).set(count)
                
                logger.info(f"Zettelkasten Metrics - Notes: {notes_count}, Concepts updated")
            else:
                logger.warning("Zettelkasten directory not found")
                
        except Exception as e:
            logger.error(f"Error updating Zettelkasten metrics: {e}")
    
    def simulate_activity_metrics(self):
        """Simula métricas de atividade baseadas nos dados conhecidos"""
        try:
            # DESABILITADO: Não incrementar métricas falsas
            # Métricas de email devem refletir apenas emails reais do BillionMail
            # activities_processed_total.inc(10)
            # llm_processing_success_total.inc(3)
            # email_delivery_success_total.inc(1)  # REMOVIDO - não simular emails falsos
            
            # Apenas atualizar timestamp da última execução
            activity_agent_last_execution_timestamp.set(time.time())
            
            # Simular duração da execução
            with activity_agent_execution_duration_seconds.time():
                time.sleep(0.1)  # Simular execução mínima
            
            logger.info("Activity metrics updated (email simulation disabled)")
            
        except Exception as e:
            logger.error(f"Error updating activity metrics: {e}")
    
    def collect_metrics(self):
        """Coleta todas as métricas"""
        logger.info("Starting metrics collection cycle")
        
        self.update_para_metrics()
        self.update_zettelkasten_metrics()
        self.simulate_activity_metrics()
        
        logger.info("Metrics collection cycle completed")
    
    def signal_handler(self, signum, frame):
        """Handler para sinais do sistema"""
        logger.info(f"Received signal {signum}, shutting down...")
        self.running = False
    
    def run(self):
        """Loop principal do daemon"""
        logger.info(f"Starting Activity Agent Metrics Daemon on port {self.port}")
        
        # Configurar handlers de sinal
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        # Iniciar servidor HTTP Prometheus
        start_http_server(self.port)
        logger.info(f"Prometheus metrics server started on port {self.port}")
        
        # Loop principal
        while self.running:
            try:
                self.collect_metrics()
                
                # Aguardar 60 segundos antes da próxima coleta
                for _ in range(60):
                    if not self.running:
                        break
                    time.sleep(1)
                    
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
                time.sleep(30)  # Aguardar antes de tentar novamente
        
        logger.info("Activity Agent Metrics Daemon stopped")

def main():
    """Função principal"""
    try:
        # Garantir que o diretório de logs existe
        log_dir = Path("/var/log/activity-agent")
        log_dir.mkdir(parents=True, exist_ok=True)
        
        # Iniciar daemon
        daemon = ActivityAgentMetrics(port=8000)
        daemon.run()
        
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()