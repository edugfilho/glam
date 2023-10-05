# Generated by Django 3.1.13 on 2023-05-25 22:59

from django.db import migrations, models

from glam.api import constants

sql_create = []
sql_create_rev = []
sql_rename = []
sql_drop = []
for channel in constants.CHANNEL_NAMES.values():
    sql_create.extend(
        [
            f"CREATE MATERIALIZED VIEW view_glam_desktop_{channel}_aggregation_temp AS SELECT * FROM glam_desktop_{channel}_aggregation;",
            f"CREATE UNIQUE INDEX ON view_glam_desktop_{channel}_aggregation_temp (id);",
            f"CREATE INDEX ON view_glam_desktop_{channel}_aggregation_temp (version);",
            f"CREATE INDEX ON view_glam_desktop_{channel}_aggregation_temp USING HASH (metric);",
            f"CREATE INDEX ON view_glam_desktop_{channel}_aggregation_temp (os);",
        ]
    )
    sql_create_rev.extend(
        [
            f"CREATE MATERIALIZED VIEW view_glam_desktop_{channel}_aggregation AS SELECT * FROM glam_desktop_{channel}_aggregation;",
            f"CREATE UNIQUE INDEX ON view_glam_desktop_{channel}_aggregation (id);",
            f"CREATE INDEX ON view_glam_desktop_{channel}_aggregation (version);",
            f"CREATE INDEX ON view_glam_desktop_{channel}_aggregation USING HASH (metric);",
            f"CREATE INDEX ON view_glam_desktop_{channel}_aggregation (os);",
        ]
    )
for channel in constants.CHANNEL_NAMES.values():
    sql_rename.extend(
        [
            f"ALTER MATERIALIZED VIEW view_glam_desktop_{channel}_aggregation rename TO view_glam_desktop_{channel}_aggregation_old;",
            f"ALTER MATERIALIZED VIEW view_glam_desktop_{channel}_aggregation_temp rename TO view_glam_desktop_{channel}_aggregation;",
        ]
    )
for channel in constants.CHANNEL_NAMES.values():
    sql_drop.extend(
        [
            f"DROP MATERIALIZED VIEW view_glam_desktop_{channel}_aggregation_old;",
        ]
    )


class Migration(migrations.Migration):

    dependencies = [
        ("api", "0024_usageinstrumentation"),
    ]

    operations = [
        migrations.RunSQL(
            sql=migrations.RunSQL.noop,
            reverse_sql=sql_create_rev,
        ),
        migrations.AddField(
            model_name="desktopbetaaggregation",
            name="non_norm_histogram",
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="desktopbetaaggregation",
            name="non_norm_percentiles",
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="desktopnightlyaggregation",
            name="non_norm_histogram",
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="desktopnightlyaggregation",
            name="non_norm_percentiles",
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="desktopreleaseaggregation",
            name="non_norm_histogram",
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="desktopreleaseaggregation",
            name="non_norm_percentiles",
            field=models.TextField(blank=True, null=True),
        ),
        migrations.RunSQL(
            sql_create,
            reverse_sql=migrations.RunSQL.noop,
        ),
        migrations.RunSQL(
            sql_rename,
            reverse_sql=migrations.RunSQL.noop,
        ),
        migrations.RunSQL(
            sql_drop,
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]