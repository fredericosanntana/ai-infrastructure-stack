#!/usr/bin/env python3
"""
LEANN Auto-Reindexação com Embeddings Locais
Monitora modificações e usa embeddings locais por padrão
"""

import os
import sys
import time
import hashlib
import json
from datetime import datetime, timedelta
from pathlib import Path
import logging

# Add local-llm to path
sys.path.insert(0, '/opt/local-llm')
from leann_local_adapter import LEANNAdapter

# Configurações
VAULT_PATH = "/var/lib/docker/volumes/docker-compose_obsidian-vaults/_data/MyVault"
INDEX_NAME = "myvault"
METADATA_FILE = "/tmp/leann_reindex_metadata_local.json"
LOG_FILE = "/var/log/leann-reindex-local.log"
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

                    # Adicionar ao hash
                    hash_md5.update(f"{rel_path}:{mtime}".encode())
                    md_files.append(rel_path)

                except Exception as e:
                    logger.warning(f"Failed to process {file_path}: {e}")

    return hash_md5.hexdigest(), len(md_files)

def load_metadata():
    """Carrega metadados salvos"""
    if os.path.exists(METADATA_FILE):
        try:
            with open(METADATA_FILE, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load metadata: {e}")

    return {
        "last_hash": None,
        "last_reindex": None,
        "file_count": 0,
        "mode": "local"
    }

def save_metadata(metadata):
    """Salva metadados"""
    try:
        with open(METADATA_FILE, 'w') as f:
            json.dump(metadata, f, indent=2)
    except Exception as e:
        logger.error(f"Failed to save metadata: {e}")

def perform_reindex(adapter, force=False):
    """Executa reindexação com embeddings locais"""
    logger.info("Starting reindexation with LOCAL embeddings")

    start_time = time.time()

    try:
        # Rebuild index
        success = adapter.rebuild_leann_index(force=True)

        if success:
            elapsed = time.time() - start_time
            logger.info(f"✅ Reindexation completed in {elapsed:.2f} seconds")

            # Get stats
            stats = adapter.get_stats()
            logger.info(f"Adapter stats: {stats}")

            return True
        else:
            logger.error("❌ Reindexation failed")
            return False

    except Exception as e:
        logger.error(f"Reindexation error: {e}")
        return False

def monitor_loop():
    """Loop principal de monitoramento"""
    logger.info("=== LEANN Local Auto-Reindex Started ===")
    logger.info(f"Vault path: {VAULT_PATH}")
    logger.info(f"Check interval: {CHECK_INTERVAL} seconds")
    logger.info("Using LOCAL embeddings (zero cost, 100% privacy)")

    # Initialize adapter in auto mode (local first, OpenAI fallback)
    adapter = LEANNAdapter(mode="auto")

    while True:
        try:
            # Calcular hash atual
            current_hash, file_count = calculate_vault_hash()

            # Carregar metadados
            metadata = load_metadata()

            # Verificar se houve mudança
            if current_hash != metadata.get("last_hash"):
                logger.info(f"Changes detected! Files: {file_count}, Hash: {current_hash[:8]}...")

                # Verificar intervalo mínimo
                last_reindex = metadata.get("last_reindex")
                if last_reindex:
                    last_time = datetime.fromisoformat(last_reindex)
                    time_since = datetime.now() - last_time

                    if time_since < timedelta(seconds=MIN_REINDEX_INTERVAL):
                        wait_time = MIN_REINDEX_INTERVAL - time_since.total_seconds()
                        logger.info(f"Waiting {wait_time:.0f} seconds before next reindex")
                        time.sleep(wait_time)

                # Executar reindexação
                if perform_reindex(adapter, force=True):
                    # Atualizar metadados
                    metadata["last_hash"] = current_hash
                    metadata["last_reindex"] = datetime.now().isoformat()
                    metadata["file_count"] = file_count
                    metadata["mode"] = "local"
                    save_metadata(metadata)

                    logger.info("✅ Metadata updated")
            else:
                logger.debug(f"No changes detected. Files: {file_count}")

            # Aguardar próximo check
            time.sleep(CHECK_INTERVAL)

        except KeyboardInterrupt:
            logger.info("Received stop signal")
            break
        except Exception as e:
            logger.error(f"Monitor loop error: {e}")
            time.sleep(30)  # Wait before retry

def main():
    """Main function"""
    if len(sys.argv) > 1:
        if sys.argv[1] == "force":
            logger.info("Force reindexing...")
            adapter = LEANNAdapter(mode="local")
            perform_reindex(adapter, force=True)
        elif sys.argv[1] == "status":
            metadata = load_metadata()
            print(f"Last reindex: {metadata.get('last_reindex', 'Never')}")
            print(f"File count: {metadata.get('file_count', 0)}")
            print(f"Mode: {metadata.get('mode', 'unknown')}")
            print(f"Last hash: {metadata.get('last_hash', 'None')[:8] if metadata.get('last_hash') else 'None'}...")
    else:
        monitor_loop()

if __name__ == "__main__":
    main()