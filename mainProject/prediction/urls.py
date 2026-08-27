from django.urls import path

from .views import predict_shell, shellfish_advisory, shellfish_advisory_pdf, shellfish_advisory_history

urlpatterns = [
    path('predict/', predict_shell, name='predict_shell'),
    path('advisories/shellfish/', shellfish_advisory, name='shellfish_advisory'),
    path('advisories/shellfish/pdf/', shellfish_advisory_pdf, name='shellfish_advisory_pdf'),
    path('advisories/shellfish/history/', shellfish_advisory_history, name='shellfish_advisory_history'),
]
