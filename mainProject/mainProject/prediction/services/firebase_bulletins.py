import hashlib
import json
import logging
import os
from pathlib import Path
from datetime import date, datetime

logger = logging.getLogger(__name__)

COLLECTION_NAME = 'shellfish_bulletins'
PROJECT_DIR = Path(__file__).resolve().parents[2]


def _load_dotenv():
    """Load local environment values without overriding real process values."""
    env_path = PROJECT_DIR / '.env'
    if not env_path.exists():
        return

    raw = env_path.read_bytes()
    for encoding in ('utf-8-sig', 'utf-16'):
        try:
            content = raw.decode(encoding)
            break
        except UnicodeDecodeError:
            continue
    else:
        logger.warning('Could not decode Firebase environment file: %s', env_path)
        return

    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, value = line.split('=', 1)
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key.strip(), value)


def _stable_id(bulletin_number, bulletin_year, advisory_date, pdf_url, source_url):
    identity = (
        f'{bulletin_number}|{bulletin_year}'
        if bulletin_number
        else f'{advisory_date or ""}|{pdf_url}|{source_url}'
    )
    return hashlib.sha256(identity.encode('utf-8')).hexdigest()[:40]


def _serialize(value):
    if isinstance(value, (date, datetime)):
        return value.isoformat()
    return value


class FirebaseBulletinRepository:
    """Persist bulletin history in Firestore when Firebase is configured."""

    def __init__(self):
        self._collection = None
        self._initialised = False

    def _get_collection(self):
        if self._initialised:
            return self._collection

        self._initialised = True
        try:
            _load_dotenv()
            import firebase_admin
            from firebase_admin import credentials, firestore

            if firebase_admin._apps:
                app = firebase_admin.get_app()
            else:
                credentials_path = os.environ.get('FIREBASE_CREDENTIALS')
                if credentials_path and credentials_path.lstrip().startswith('{'):
                    app = firebase_admin.initialize_app(
                        credentials.Certificate(json.loads(credentials_path)),
                    )
                elif credentials_path and not os.path.isabs(credentials_path):
                    resolved_path = PROJECT_DIR / credentials_path
                    app = firebase_admin.initialize_app(
                        credentials.Certificate(str(resolved_path)),
                    )
                elif credentials_path and os.path.exists(credentials_path):
                    app = firebase_admin.initialize_app(
                        credentials.Certificate(credentials_path),
                    )
                else:
                    app = firebase_admin.initialize_app()

            self._collection = firestore.client(app).collection(COLLECTION_NAME)
        except Exception as exc:
            logger.warning('Firebase bulletin persistence unavailable: %s', exc)

        return self._collection

    def upsert(self, bulletin):
        collection = self._get_collection()
        if collection is None:
            return False

        document_id = _stable_id(
            bulletin.get('bulletin_number'),
            bulletin.get('bulletin_year'),
            bulletin.get('advisory_date'),
            bulletin.get('pdf_url'),
            bulletin.get('source_url'),
        )
        payload = {
            key: _serialize(value)
            for key, value in bulletin.items()
            if value is not None
        }
        payload['stable_id'] = document_id
        payload['updated_at'] = datetime.utcnow().isoformat() + 'Z'
        collection.document(document_id).set(payload, merge=True)
        return True


firebase_bulletins = FirebaseBulletinRepository()