# Generated by Django 3.1.13 on 2022-04-22 15:36

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("api", "0023_delete_sqlite_probes"),
    ]

    operations = [
        migrations.CreateModel(
            name="UsageInstrumentation",
            fields=[
                ("id", models.BigAutoField(primary_key=True, serialize=False)),
                (
                    "action_type",
                    models.CharField(
                        choices=[("PROBE_SEARCH", "probe_search")], max_length=100
                    ),
                ),
                ("timestamp", models.DateTimeField(auto_now_add=True)),
                ("context", models.JSONField(null=True)),
                ("tracking_id", models.CharField(blank=True, max_length=500)),
                ("probe_name", models.CharField(blank=True, max_length=100)),
            ],
            options={
                "db_table": "glam_usage_instrumentation",
            },
        ),
    ]
