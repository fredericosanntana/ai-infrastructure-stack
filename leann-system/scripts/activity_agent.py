#!/usr/bin/env python3
"""
Activity Agent - Daily Report Generator
Gera relatórios diários de atividade do sistema PARA/Zettelkasten
"""

import os
import sys
import json
import smtplib
from datetime import datetime
try:
    from email.mime.text import MimeText
    from email.mime.multipart import MimeMultipart
except ImportError:
    # Fallback para Python 3.13+
    from email.message import EmailMessage
    MimeText = EmailMessage
    MimeMultipart = EmailMessage
from pathlib import Path
import logging
from metrics_daemon import ActivityAgentMetrics

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/activity-agent/daily.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class ActivityAgent:
    def __init__(self):
        self.obsidian_vault_path = "/var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault"
        self.smtp_server = "172.18.0.1"  # BillionMail via Docker gateway
        self.smtp_port = 587
        self.email_from = "activity-agent@dpo2u.com"
        self.email_to = "admin@dpo2u.com"
        
    def get_para_stats(self):
        """Coleta estatísticas do sistema PARA"""
        try:
            para_path = Path(self.obsidian_vault_path) / "01-PARA"
            stats = {}
            
            if para_path.exists():
                stats['projects'] = len(list((para_path / "Projects").glob("*.md"))) if (para_path / "Projects").exists() else 0
                stats['areas'] = len(list((para_path / "Areas").glob("*.md"))) if (para_path / "Areas").exists() else 0
                stats['resources'] = len(list((para_path / "Resources").glob("*.md"))) if (para_path / "Resources").exists() else 0
                stats['archive'] = len(list((para_path / "Archive").glob("*.md"))) if (para_path / "Archive").exists() else 0
            else:
                stats = {'projects': 0, 'areas': 0, 'resources': 0, 'archive': 0}
                
            logger.info(f"PARA Stats: {stats}")
            return stats
            
        except Exception as e:
            logger.error(f"Error getting PARA stats: {e}")
            return {'projects': 0, 'areas': 0, 'resources': 0, 'archive': 0}
    
    def get_zettelkasten_stats(self):
        """Coleta estatísticas do Zettelkasten"""
        try:
            zk_path = Path(self.obsidian_vault_path) / "02-Zettelkasten"
            stats = {}
            
            if zk_path.exists():
                # Contar notas por categoria
                permanent_notes = len(list((zk_path / "Permanent").glob("*.md"))) if (zk_path / "Permanent").exists() else 0
                daily_notes = len(list((zk_path / "Daily").glob("*.md"))) if (zk_path / "Daily").exists() else 0
                literature_notes = len(list((zk_path / "Literature").glob("*.md"))) if (zk_path / "Literature").exists() else 0
                
                stats = {
                    'permanent_notes': permanent_notes,
                    'daily_notes': daily_notes,
                    'literature_notes': literature_notes,
                    'total_notes': permanent_notes + daily_notes + literature_notes
                }
            else:
                stats = {'permanent_notes': 0, 'daily_notes': 0, 'literature_notes': 0, 'total_notes': 0}
                
            logger.info(f"Zettelkasten Stats: {stats}")
            return stats
            
        except Exception as e:
            logger.error(f"Error getting Zettelkasten stats: {e}")
            return {'permanent_notes': 0, 'daily_notes': 0, 'literature_notes': 0, 'total_notes': 0}
    
    def get_recent_activities(self):
        """Lista atividades recentes"""
        try:
            activities = []
            
            # Buscar notas criadas hoje
            today = datetime.now().strftime("%Y-%m-%d")
            zk_path = Path(self.obsidian_vault_path) / "02-Zettelkasten"
            
            if zk_path.exists():
                # Buscar em todas as pastas
                for folder in ["Permanent", "Daily", "Literature"]:
                    folder_path = zk_path / folder
                    if folder_path.exists():
                        for note in folder_path.glob("*.md"):
                            if note.stat().st_mtime > (datetime.now().timestamp() - 86400):  # Últimas 24h
                                activities.append({
                                    'type': folder,
                                    'name': note.stem,
                                    'created': datetime.fromtimestamp(note.stat().st_mtime).strftime("%H:%M")
                                })
            
            logger.info(f"Recent Activities: {len(activities)} items")
            return activities
            
        except Exception as e:
            logger.error(f"Error getting recent activities: {e}")
            return []
    
    def generate_html_report(self, para_stats, zk_stats, activities):
        """Gera relatório HTML"""
        today = datetime.now().strftime("%Y-%m-%d")
        
        html = f"""
        <html>
        <head>
            <title>Activity Report - {today}</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 40px; }}
                .header {{ background-color: #f0f8ff; padding: 20px; border-radius: 8px; }}
                .section {{ margin: 20px 0; }}
                .stats-grid {{ display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; }}
                .stat-card {{ background-color: #f9f9f9; padding: 15px; border-radius: 8px; }}
                .activities {{ background-color: #fff8f0; padding: 15px; border-radius: 8px; }}
                .number {{ font-size: 24px; font-weight: bold; color: #2c3e50; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Daily Activity Report</h1>
                <p><strong>Date:</strong> {today}</p>
                <p><strong>Generated:</strong> {datetime.now().strftime("%H:%M:%S")}</p>
            </div>
            
            <div class="section">
                <h2>PARA System Status</h2>
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="number">{para_stats['projects']}</div>
                        <div>Active Projects</div>
                    </div>
                    <div class="stat-card">
                        <div class="number">{para_stats['areas']}</div>
                        <div>Areas of Responsibility</div>
                    </div>
                    <div class="stat-card">
                        <div class="number">{para_stats['resources']}</div>
                        <div>Resources</div>
                    </div>
                    <div class="stat-card">
                        <div class="number">{para_stats['archive']}</div>
                        <div>Archive Items</div>
                    </div>
                </div>
            </div>
            
            <div class="section">
                <h2>Zettelkasten Status</h2>
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="number">{zk_stats['permanent_notes']}</div>
                        <div>Permanent Notes</div>
                    </div>
                    <div class="stat-card">
                        <div class="number">{zk_stats['daily_notes']}</div>
                        <div>Daily Notes</div>
                    </div>
                    <div class="stat-card">
                        <div class="number">{zk_stats['literature_notes']}</div>
                        <div>Literature Notes</div>
                    </div>
                    <div class="stat-card">
                        <div class="number">{zk_stats['total_notes']}</div>
                        <div>Total Notes</div>
                    </div>
                </div>
            </div>
            
            <div class="section">
                <h2>Recent Activities</h2>
                <div class="activities">
        """
        
        if activities:
            html += "<ul>"
            for activity in activities[:10]:  # Últimas 10 atividades
                html += f"<li><strong>{activity['created']}</strong> - {activity['type']}: {activity['name']}</li>"
            html += "</ul>"
        else:
            html += "<p>No recent activities found.</p>"
            
        html += """
                </div>
            </div>
            
            <div class="section">
                <p><em>Generated by Activity Agent - Powered by Claude Code</em></p>
            </div>
        </body>
        </html>
        """
        
        return html
    
    def send_email_report(self, html_content):
        """Envia relatório por email"""
        try:
            today = datetime.now().strftime("%Y-%m-%d")
            
            # Criar mensagem simples
            headers = [
                f"Subject: Daily Activity Report - {today}",
                f"From: {self.email_from}",
                f"To: {self.email_to}",
                "MIME-Version: 1.0",
                "Content-Type: text/html; charset=utf-8",
                ""
            ]
            
            message = "\r\n".join(headers) + html_content
            
            # Conectar ao servidor SMTP
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            # server.login(username, password)  # Configurar se necessário
            
            server.sendmail(self.email_from, [self.email_to], message)
            server.quit()
            
            logger.info("Email report sent successfully")
            return True
            
        except Exception as e:
            logger.error(f"Error sending email report: {e}")
            return False
    
    def generate_daily_report(self):
        """Gera e envia relatório diário"""
        logger.info("Starting daily report generation")
        
        try:
            # Coletar dados
            para_stats = self.get_para_stats()
            zk_stats = self.get_zettelkasten_stats()
            activities = self.get_recent_activities()
            
            # Gerar HTML
            html_content = self.generate_html_report(para_stats, zk_stats, activities)
            
            # Enviar por email
            success = self.send_email_report(html_content)
            
            if success:
                logger.info("Daily report generated and sent successfully")
            else:
                logger.error("Failed to send daily report")
                
            return success
            
        except Exception as e:
            logger.error(f"Error generating daily report: {e}")
            return False

def main():
    """Função principal"""
    try:
        # Garantir que o diretório de logs existe
        log_dir = Path("/var/log/activity-agent")
        log_dir.mkdir(parents=True, exist_ok=True)
        
        # Gerar relatório
        agent = ActivityAgent()
        success = agent.generate_daily_report()
        
        sys.exit(0 if success else 1)
        
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()