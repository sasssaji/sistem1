from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('prediction', '0002_bulletin_year'),
    ]

    operations = [
        migrations.AddField(
            model_name='shellfishadvisory',
            name='pdf_text_extracted',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='shellfishadvisory',
            name='verification_method',
            field=models.CharField(blank=True, max_length=40),
        ),
    ]
