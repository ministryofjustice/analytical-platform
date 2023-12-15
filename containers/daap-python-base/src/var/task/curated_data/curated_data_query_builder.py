from data_platform_paths import QueryTable


class CuratedDataQueryBuilder:
    """
    Builds queries for processing raw data, via athena.
    """

    def __init__(self, column_metadata: list[dict[str, str]], table_path: str):
        """
        Args:
            column_metadata - glue metadata for the columns in the table
            table_path - path to the partition files in the curated data bucket
        """
        self.table_path: str
        self.column_metadata = column_metadata
        self.table_path = table_path

    def _get_column_names_and_types(self) -> str:
        select_list = []
        for column in self.column_metadata:
            col_name = '"' + column["Name"] + '"'
            col_type = column["Type"] if not column["Type"] == "string" else "VARCHAR"
            col_no_zero_len_str = f"NULLIF({col_name},'')"
            select_list.append(
                f"CAST({col_no_zero_len_str} as {col_type}) as {col_name}"
            )

        select_str = ",".join(select_list)

        return select_str

    def sql_unload_table_partition(self, timestamp: str, raw_table: QueryTable) -> str:
        """
        generates sql string to unload a timestamped partition
        of raw data to given s3 location
        """
        partition_sql = f"""
            UNLOAD (
                SELECT
                    {self._get_column_names_and_types()},
                    '{timestamp}' as extraction_timestamp
                FROM {raw_table.database}.{raw_table.name}
            )
            TO '{self.table_path}'
            WITH(
                format='parquet',
                compression = 'SNAPPY',
                partitioned_by=ARRAY['extraction_timestamp']
            )
        """

        return partition_sql

    def sql_create_table_partition(
        self, raw_table: QueryTable, curated_table: QueryTable, timestamp: str
    ) -> str:
        """
        For use if the curated table does not exist in the glue catalog.
        This uses a CTAS query to create the table and partitions in the glue catalog
        and associate this table with the parquet in s3 created from the raw data.
        """
        partition_sql = f"""
            CREATE TABLE {curated_table.database}.{curated_table.name}
            WITH(
                format='parquet',
                write_compression = 'SNAPPY',
                external_location='{self.table_path}',
                partitioned_by=ARRAY['extraction_timestamp']
            ) AS
            SELECT
                {self._get_column_names_and_types()},
                '{timestamp}' as extraction_timestamp
            FROM {raw_table.database}.{raw_table.name}
        """

        return partition_sql

    def sql_create_next_major_increment_table(self, new_curated_table: QueryTable):
        """
        This creates a table in the new version database of the latest snapshot
        from each table in a data product.

        For tables that have not been updated as part of the version increment
        """
        previous_major_database = new_curated_table.database[:-1] + str(
            int(new_curated_table.database[-1]) - 1
        )

        sql = f"""
            CREATE TABLE {new_curated_table.database}.{new_curated_table.name}
            WITH(
                format='parquet',
                write_compression = 'SNAPPY',
                external_location='{self.table_path}',
                partitioned_by=ARRAY['extraction_timestamp']
            ) AS
            SELECT
                *
            FROM {previous_major_database}.{new_curated_table.name}
            WHERE extraction_timestamp = (
                SELECT MAX(extraction_timestamp)
                FROM {previous_major_database}.{new_curated_table.name}
            )
        """

        return sql

    def sql_unload_for_major_updated_table(self, curated_table: QueryTable):
        """
        Unloads latest snapshot data of the table that is updated to the partition folder
        in the new version database
        """
        previous_major_database = curated_table.database[:-1] + str(
            int(curated_table.database[-1]) - 1
        )

        sql = f"""
            UNLOAD (
                SELECT
                    *
                FROM {previous_major_database}.{curated_table.name}
                WHERE extraction_timestamp = (
                    SELECT MAX(extraction_timestamp)
                    FROM {previous_major_database}.{curated_table.name}
                )
            )
            TO '{self.table_path}'
            WITH(
                format='parquet',
                compression = 'SNAPPY',
                partitioned_by=ARRAY['extraction_timestamp']
            )
        """
        return sql
