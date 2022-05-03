# Generated by Django 3.0.3 on 2020-03-23 21:53

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("api", "0003_betaaggregation_nightlyaggregation_releaseaggregation"),
    ]

    operations = [
        migrations.CreateModel(
            name="FirefoxCounts",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                (
                    "channel",
                    models.IntegerField(
                        blank=True,
                        choices=[(1, "nightly"), (2, "beta"), (3, "release")],
                        null=True,
                    ),
                ),
                ("version", models.CharField(blank=True, max_length=100, null=True)),
                ("build_id", models.CharField(max_length=100)),
                ("os", models.CharField(max_length=100)),
                ("total_users", models.IntegerField()),
            ],
            options={
                "db_table": "glam_firefox_counts",
            },
        ),
        migrations.AddConstraint(
            model_name="firefoxcounts",
            constraint=models.UniqueConstraint(
                fields=("channel", "version", "build_id", "os"),
                name="unique_dimensions",
            ),
        ),
    ]
