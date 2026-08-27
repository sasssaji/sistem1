from django.db import migrations, models


def populate_bulletin_year(apps, schema_editor):
    ShellfishAdvisory = apps.get_model('prediction', 'ShellfishAdvisory')
    for bulletin in ShellfishAdvisory.objects.all():
        bulletin.bulletin_year = (
            bulletin.advisory_date.year if bulletin.advisory_date else 2000
        )
        bulletin.save(update_fields=['bulletin_year'])


class Migration(migrations.Migration):
    dependencies = [
        ('prediction', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='shellfishadvisory',
            name='bulletin_year',
            field=models.PositiveSmallIntegerField(default=2000),
            preserve_default=False,
        ),
        migrations.RunPython(populate_bulletin_year, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='shellfishadvisory',
            name='bulletin_number',
            field=models.CharField(max_length=120),
        ),
        migrations.AddConstraint(
            model_name='shellfishadvisory',
            constraint=models.UniqueConstraint(
                fields=('bulletin_number', 'bulletin_year'),
                name='unique_shellfish_bulletin_year',
            ),
        ),
    ]
