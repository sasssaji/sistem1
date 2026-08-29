import logging
from apscheduler.schedulers.background import BackgroundScheduler
from django.conf import settings

from prediction.services.bfar import sync_latest_advisory

logger = logging.getLogger(__name__)
scheduler = None


def start_scheduler():
    global scheduler
    if scheduler is not None and scheduler.running:
        return

    try:
        scheduler = BackgroundScheduler()
        scheduler.add_job(
            sync_latest_advisory,
            'interval',
            hours=6,
            id='sync_bfar_advisory',
            name='Sync BFAR Shellfish Advisory',
            replace_existing=True,
            misfire_grace_time=60,
            coalesce=True,
        )
        scheduler.start()
        logger.info('BFAR advisory scheduler started: syncs every 6 hours')
    except Exception as exc:
        logger.error(f'Failed to start BFAR scheduler: {exc}')


def stop_scheduler():
    global scheduler
    if scheduler is not None and scheduler.running:
        scheduler.shutdown()
        logger.info('BFAR advisory scheduler stopped')
