from django.core.management.base import BaseCommand

from prediction.services.bfar import sync_latest_advisory


class Command(BaseCommand):
    help = 'Fetch and cache the latest official BFAR shellfish advisory.'

    def handle(self, *args, **options):
        result = sync_latest_advisory(force=True)
        if result.get('error'):
            self.stdout.write(self.style.WARNING(f"BFAR sync failed; cache preserved: {result['error']}"))
        else:
            self.stdout.write(self.style.SUCCESS(f"BFAR sync complete: {result}"))
