from airflow.www.utils import UIAlert

DASHBOARD_UIALERTS = [
    UIAlert(
        'This Airflow instance is a proof of concept and is not intended for production use.',
        category="info",
        html=True,
    )
]
