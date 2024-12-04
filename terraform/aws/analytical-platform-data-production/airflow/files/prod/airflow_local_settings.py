from airflow.www.utils import UIAlert

# This is desribed;
# here https://airflow.apache.org/docs/apache-airflow/2.4.3/howto/customize-ui.html#add-custom-alert-messages-on-the-dashboard
# and here https://github.com/apache/airflow/blob/main/airflow/www/utils.py#L889
DASHBOARD_UIALERTS = [
    UIAlert(
        'Workflows that use internal networking (HMCTS SDP or Cloud and Modernisation Platforms) will need to complete the migration steps outlined in the <a href="https://user-guidance.analytical-platform.service.justice.gov.uk/tools/airflow/migration.html">user guidance</a>',
        category="warning",
        html=True,
    )
]
