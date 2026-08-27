from django.apps import AppConfig


class PredictionConfig(AppConfig):
    name = 'prediction'

    def ready(self):
        from prediction.scheduler import start_scheduler
        start_scheduler()
