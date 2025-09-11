#!/usr/bin/env python3
"""
LEANN Auto-Reindexação Baseada em Mudanças
Monitora modificações no MyVault e reindex automaticamente quando necessário
"""

import os
import sys
import time
import hashlib
import subprocess
import json
from datetime import datetime, timedelta
from pathlib import Path
import logging

# Configurações
VAULT_PATH = "/var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault"
INDEX_NAME = "myvault"
METADATA_FILE = "/tmp/leann_reindex_metadata.json"
LOG_FILE = "/var/log/leann-reindex.log"
CHECK_INTERVAL = 300  # 5 minutos
MIN_REINDEX_INTERVAL = 3600  # 1 hora mínima entre reindexações

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

def calculate_vault_hash():
    """Calcula hash MD5 de todos os arquivos .md no vault"""
    hash_md5 = hashlib.md5()
    
    md_files = []
    for root, dirs, files in os.walk(VAULT_PATH):
        # Ignorar diretórios ocultos
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        for file in sorted(files):
            if file.endswith('.md'):
                file_path = os.path.join(root, file)
                try:
                    # Adicionar path relativo e timestamp
                    rel_path = os.path.relpath(file_path, VAULT_PATH)
                    mtime = os.path.getmtime(file_path)
                    size = os.path.getsize(file_path)
                    
                    # Hash do conteúdo do arquivo
                    with open(file_path, 'rb') as f:
                        file_content = f.read()
                        file_hash = hashlib.md5(file_content).hexdigest()
                    
                    # Combinar informações do arquivo
                    file_info = f"{rel_path}:{mtime}:{size}:{file_hash}"
                    hash_md5.update(file_info.encode())
                    md_files.append({
                        'path': rel_path,
                        'mtime': mtime,
                        'size': size,
                        'hash': file_hash
                    })
                    
                except Exception as e:
                    logger.warning(f"Erro ao processar {file_path}: {e}")
                    continue
    
    return hash_md5.hexdigest(), md_files

def load_metadata():
    """Carrega metadata da última verificação"""
    try:
        if os.path.exists(METADATA_FILE):
            with open(METADATA_FILE, 'r') as f:
                return json.load(f)
    except Exception as e:
        logger.warning(f"Erro ao carregar metadata: {e}")
    
    return {
        'last_hash': None,
        'last_reindex': 0,
        'last_check': 0,
        'total_files': 0,
        'reindex_count': 0
    }

def save_metadata(metadata):
    """Salva metadata da verificação atual"""
    try:
        with open(METADATA_FILE, 'w') as f:
            json.dump(metadata, f, indent=2)
    except Exception as e:
        logger.error(f"Erro ao salvar metadata: {e}")

def needs_reindex(current_hash, metadata):
    """Verifica se reindexação é necessária"""
    # Mudança no conteúdo
    if current_hash != metadata.get('last_hash'):
        return True, "Conteúdo modificado"
    
    # Reindexação forçada a cada 24h (backup)
    last_reindex = metadata.get('last_reindex', 0)
    if time.time() - last_reindex > 86400:  # 24 horas
        return True, "Reindexação diária de segurança"
    
    return False, "Nenhuma mudança detectada"

def run_leann_reindex():
    """Executa reindexação do LEANN"""
    try:
        logger.info("🔄 Iniciando reindexação LEANN...")
        
        cmd = [
            "leann", "build", INDEX_NAME,
            "--docs", VAULT_PATH,
            "--file-types", ".md",
            "--embedding-mode", "openai",
            "--embedding-model", "text-embedding-3-small",
            "--force"
        ]
        
        # Executar comando
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd="/root",
            env={**os.environ, 
                 "PATH": "/root/.local/bin:" + os.environ.get("PATH", ""),
                 "OPENAI_API_KEY": os.environ.get("OPENAI_API_KEY", "")}
        )
        
        if result.returncode == 0:
            logger.info("✅ Reindexação LEANN concluída com sucesso")
            return True
        else:
            logger.error(f"❌ Erro na reindexação: {result.stderr}")
            return False
            
    except Exception as e:
        logger.error(f"❌ Erro ao executar reindexação: {e}")
        return False

def clear_redis_cache():
    """Limpa cache Redis após reindexação"""
    try:
        import redis
        r = redis.Redis(host='localhost', port=26379, db=1, decode_responses=True)
        
        # Buscar chaves do cache LEANN
        leann_keys = r.keys("leann:*")
        if leann_keys:
            deleted = r.delete(*leann_keys)
            logger.info(f"🗑️ Cache Redis limpo: {deleted} chaves removidas")
        else:
            logger.info("🗑️ Cache Redis já vazio")
            
    except Exception as e:
        logger.warning(f"⚠️ Erro ao limpar cache Redis: {e}")

def monitor_vault():
    """Loop principal de monitoramento"""
    logger.info("🚀 Iniciando monitoramento LEANN auto-reindex")
    logger.info(f"📁 Monitorando: {VAULT_PATH}")
    logger.info(f"⏰ Intervalo de verificação: {CHECK_INTERVAL}s")
    
    while True:
        try:
            # Carregar metadata
            metadata = load_metadata()
            
            # Calcular hash atual
            current_hash, file_list = calculate_vault_hash()
            total_files = len(file_list)
            
            logger.info(f"📊 Verificação: {total_files} arquivos .md encontrados")
            
            # Verificar se precisa reindexar
            should_reindex, reason = needs_reindex(current_hash, metadata)
            
            if should_reindex:
                # Verificar intervalo mínimo
                last_reindex = metadata.get('last_reindex', 0)
                time_since_last = time.time() - last_reindex
                
                if time_since_last < MIN_REINDEX_INTERVAL:
                    wait_time = MIN_REINDEX_INTERVAL - time_since_last
                    logger.info(f"⏳ Aguardando intervalo mínimo: {wait_time/60:.1f} min")
                else:
                    logger.info(f"🔄 Reindexação necessária: {reason}")
                    
                    # Executar reindexação
                    if run_leann_reindex():
                        # Limpar cache Redis
                        clear_redis_cache()
                        
                        # Atualizar metadata
                        metadata.update({
                            'last_hash': current_hash,
                            'last_reindex': time.time(),
                            'last_check': time.time(),
                            'total_files': total_files,
                            'reindex_count': metadata.get('reindex_count', 0) + 1
                        })
                        
                        logger.info(f"✅ Reindexação #{metadata['reindex_count']} concluída")
                    else:
                        logger.error("❌ Falha na reindexação")
            else:
                logger.info(f"✅ {reason}")
                
                # Atualizar apenas timestamp da verificação
                metadata.update({
                    'last_check': time.time(),
                    'total_files': total_files
                })
            
            # Salvar metadata
            save_metadata(metadata)
            
            # Aguardar próxima verificação
            logger.info(f"😴 Próxima verificação em {CHECK_INTERVAL/60:.1f} min")
            time.sleep(CHECK_INTERVAL)
            
        except KeyboardInterrupt:
            logger.info("🛑 Monitoramento interrompido pelo usuário")
            break
        except Exception as e:
            logger.error(f"❌ Erro no loop principal: {e}")
            time.sleep(60)  # Aguardar 1 min antes de tentar novamente

def show_status():
    """Mostra status atual do monitoramento"""
    metadata = load_metadata()
    
    print("📊 LEANN Auto-Reindex Status")
    print("=" * 40)
    
    if metadata.get('last_check'):
        last_check = datetime.fromtimestamp(metadata['last_check'])
        print(f"🕐 Última verificação: {last_check.strftime('%Y-%m-%d %H:%M:%S')}")
    
    if metadata.get('last_reindex'):
        last_reindex = datetime.fromtimestamp(metadata['last_reindex'])
        print(f"🔄 Última reindexação: {last_reindex.strftime('%Y-%m-%d %H:%M:%S')}")
    
    print(f"📁 Total de arquivos: {metadata.get('total_files', 'N/A')}")
    print(f"🔢 Reindexações realizadas: {metadata.get('reindex_count', 0)}")
    
    if metadata.get('last_hash'):
        print(f"🔐 Hash atual: {metadata['last_hash'][:16]}...")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "status":
            show_status()
        elif sys.argv[1] == "force":
            logger.info("🔄 Forçando reindexação...")
            if run_leann_reindex():
                clear_redis_cache()
                logger.info("✅ Reindexação forçada concluída")
            else:
                logger.error("❌ Falha na reindexação forçada")
        else:
            print("Uso: python3 leann_auto_reindex.py [status|force]")
    else:
        monitor_vault()