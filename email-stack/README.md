# 📧 BillionMail Email Stack

Complete enterprise email infrastructure with 7 integrated services.

## Quick Deploy
```bash
docker compose -f billionmail-compose.yml up -d
```

## Services Included
- **Postfix**: SMTP server
- **Dovecot**: IMAP/POP3 server
- **Rspamd**: Anti-spam engine
- **Roundcube**: Webmail interface
- **PostgreSQL**: Email database
- **Redis**: Caching layer
- **Core**: Management interface

## Configuration
Copy and edit `.env` with your domain and credentials.