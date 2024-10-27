[Version = "100.0.3"]
section Snowflake;

// When set to true, additional trace information will be written out to the User log.
// This should be set to false before release. Tracing is done through a call to
// Diagnostics.LogValue(). When EnableTraceOutput is set to false, the call becomes a
// no-op and simply returns the original value.
//
EnableTraceOutput = false;

// Hook into the Microsoft/Simba OEM driver to prevent the need for installation of
// additional drivers on client machiness.
//
Config_DriverName = "Simba Snowflake ODBC Driver";

// If your driver under-reports its SQL conformance level because it does not
// support the full range of CRUD operations, but does support the ANSI SQL required
// to support the SELECT operations performed by Power Query, you can override
// this value to report a higher conformance level. Please use one of the numeric
// values below (i.e. 8 for SQL_SC_SQL92_FULL).
//
// SQL_SC =
// [
//     SQL_SC_SQL92_ENTRY            = 1,
//     SQL_SC_FIPS127_2_TRANSITIONAL = 2,
//     SQL_SC_SQL92_INTERMEDIATE     = 4,
//     SQL_SC_SQL92_FULL             = 8
// ]
//
// Set to null to determine the value from the driver.
//
Config_SqlConformance = ODBC[SQL_SC][SQL_SC_SQL92_FULL];
// Snowflake supports "LIMIT <take> [OFFSET <skip>]". While supported in the documented grammar,
// using OFFSET without LIMIT produces a syntax error so we can't use LimitClauseKind.LimitOffset.               
//
// LimitClauseKind.Limit (LIMIT only, OFFSET not supported)
// ---------------------
// SELECT *
// FROM table
// LIMIT 100
//
Config_LimitClauseKind = LimitClauseKind.Limit;
// see above
// Set this option to true if your ODBC supports the standard username/password
// handling through the UID and PWD connection string parameters. If the user
// selects UsernamePassword auth, the supplied values will be automatically
// added to the CredentialConnectionString.
//
// If you wish to set these values yourself, or your driver requires additional
// parameters to be set, please set this option to 'false'
//
Config_DefaultUsernamePasswordHandling = true;
// true, false
// Some drivers have problems will parameter bindings and certain data types.
// If the driver supports parameter bindings, then set this to true.
// When set to false, parameter values will be inlined as literals into the generated SQL.
// To enable inlining for a limited number of data types, set this value
// to null and set individual flags through the SqlCapabilities record.
//
// Set to null to determine the value from the driver.
//
Config_UseParameterBindings = null;
// true, false, null
// Override this setting to force the character escape value.
// This is typically done when you have set UseParameterBindings to false.
//
// Set to null to determine the value from the driver.
//
Config_StringLiterateEscapeCharacters = {"\"};
// ex. { "\" }
// Override this if the driver expects the use of CAST instead of CONVERT.
// By default, the query will be generated using ANSI SQL CONVERT syntax.
//
// Set to null to leave default behavior.
//
Config_UseCastInsteadOfConvert = true;
// true, false, null
// Set this to true to enable Direct Query in addition to Import mode.
//
Config_EnableDirectQuery = true;

[DataSource.Kind = "Snowflake", Publish = "Snowflake.Publish"]
shared Snowflake.Database = Value.ReplaceType(DatabaseCoreImplementation, DatabaseType);

ConfigType = type [
    optional roleName = (type text meta [
        Documentation.FieldCaption = "Specify a text value to use as Role name",
        Documentation.SampleValues = {"abc"}
    ]),
    optional commandTimeout = (type number meta [
        Documentation.FieldCaption = "Command timeout in seconds",
        Documentation.SampleValues = {123}
    ]),
    optional connectionTimeout = (type number meta [
        Documentation.FieldCaption = "Connection timeout in seconds",
        Documentation.SampleValues = {123}
    ]),
    optional includeRelationshipColumns = (type logical meta [
        Documentation.FieldCaption = "Include relationship columns",
        Documentation.FieldDescription = "Not implemented",
        Documentation.SampleValues = {true}
    ]),
    optional database = (type text meta [
        Documentation.FieldCaption = "Database",
        Documentation.SampleValues = {"DEMO_DB"}
    ]),
    optional options = (type text meta [
        Documentation.FieldCaption = "Options",
        Documentation.FieldDescription = "Additional connection string options separated by semicolon",
        Documentation.SampleValues = {"LogFileSize=20971520;maxHttpRetries=7","LogFileSize=20971520"}
    ])
];

// Documenting the function
DatabaseType = type function (
    server as (type text meta [
        Documentation.FieldCaption = "Server",
        Documentation.SampleValues = {"contoso.snowflakecomputing.com"}
    ]),
    warehouse as (type text meta [
        Documentation.FieldCaption = "Warehouse",
        Documentation.SampleValues = {"CONTOSO_WH"}
    ]),
    optional config as (ConfigType meta [
        Documentation.FieldCaption = "Advanced options"
    ])
) as table meta [
    Documentation.Name = "Snowflake",
    Documentation.LongDescription = "Snowflake ODBC connector for Power Query",
    Documentation.Examples = {[
        Description = "Returns a navigation table with list of Snowflake tables that can be folded",
        Code = "Snowflake.Database(""https://app.snowflake.com"")"
    ]}
];

DatabaseCoreImplementation = (
    server as text,
    warehouse as text,
    optional config as record
) => let
        // Many data sources accept an optional 'options' record that allows users to change
        // default behaviors about the connection, such as connection timeout. Use this map
        // to define the appropriate options for your ODBC Driver. If you do not want to support
        // an options record, remove the ValidOptionsMap variable and options parameter from
        // the data source function.
        // 
        // More details regarding the driver options can be found at https://docs.snowflake.com/en/developer-guide/odbc/odbc-parameters
        //
        ValidOptionsMap = #table(
            {"Name", "Type", "Description", "Default", "Validate"},
            {
                // Configuration parameters, see: https://docs.snowflake.com/en/developer-guide/odbc/odbc-parameters#configuration-parameters
                {
                    "CABundleFile",
                    type nullable text,
                    "Location of the Certificate Authority (CA) bundle file, which must include a valid list of CA certificates.",
                    null,
                    each _ = null or _ <> null
                },
                {
                    "client_config_file",
                    type nullable text,
                    "Path of a logging configuration file to define the logging level and directory for log files.",
                    null,
                    each _ = null or _ <> null
                },
                {
                    "CURLVerboseMode",
                    type nullable logical,
                    "Enable cURL verbose logging for network diagnostics. Creates and updates 'snowflake_odbc_curl.dmp'.",
                    false,
                    each _ = null or _ <> null
                },
                {
                    "DisableOCSPCheck",
                    type nullable logical,
                    "Disable OCSP check for TLS certificate revocation status. Should only be used temporarily during connectivity issues.",
                    false,
                    each _ = null or _ <> null
                },
                {
                    "EnableAutoIpdByDefault",
                    type nullable logical,
                    "Configure SQL_ATTR_ENABLE_AUTO_IPD (true by default for compatibility with third-party tools).",
                    true,
                    each _ = null or _ <> null
                },
                {
                    "EnablePidLogFileNames",
                    type nullable logical,
                    "Include process ID in log file names to prevent different processes from overwriting log files.",
                    false,
                    each _ = null or _ <> null
                },
                {
                    "get_size_threshold",
                    type nullable number,
                    "Minimum file size in MB to trigger multi-part downloading in the GET command.",
                    5,
                    each _ = null or (_ > 0 and Number.RoundDown(_) = _)
                },
                {
                    "KeepLeadingTrailingZeros",
                    type nullable logical,
                    "Determine if leading/trailing zeros in numbers formatted as strings are retained.",
                    true,
                    each _ = null or _ <> null
                },
                {
                    "LogFileCount",
                    type nullable number,
                    "Maximum number of log files to retain before rotating.",
                    null,
                    each _ = null or (_ > 0 and Number.RoundDown(_) = _)
                },
                {
                    "LogFileSize",
                    type nullable number,
                    "Maximum size of a log file in bytes before rotation.",
                    20971520,
                    each _ = null or (_ > 0 and Number.RoundDown(_) = _)
                },
                {
                    "LogLevel",
                    type nullable number,
                    "Log level for clients using the ODBC driver (0=Off, 1=Fatal, 2=Error, 3=Warning, 4=Info, 5=Debug, 6=Trace).",
                    4,
                    each _ = null or List.Contains({0, 1, 2, 3, 4, 5, 6}, _)
                },
                {
                    "LogPath",
                    type nullable text,
                    "Path to the directory for Snowflake log files.",
                    null,
                    each _ = null or _ <> null
                },
                {
                    "MapToLongVarchar",
                    type nullable number,
                    "Threshold length in characters for mapping strings to SQL_LONGVARCHAR instead of default SQL data types.",
                    -1,
                    each _ = null or _ >= -1
                },
                {
                    "NoExecuteInSQLPrepare",
                    type nullable logical,
                    "Enable standard ODBC behaviour when using SQLPrepare() and SQLExecute() with DDL statements.",
                    false,
                    each _ = null or _ <> null
                },
                {
                    "NoProxy",
                    type nullable text,
                    "Specify hostname patterns to bypass proxy (e.g. .amazonaws.com for S3).",
                    null,
                    each _ = null or _ <> null
                },
                {
                    "Proxy",
                    type nullable text,
                    "Specify the proxy server as <host>:<port> for ODBC clients.",
                    null,
                    each _ = null or _ <> null
                },
                // Optional connection parameters, see: https://docs.snowflake.com/en/developer-guide/odbc/odbc-parameters#optional-connection-parameters
                {
                    "BROWSER_RESPONSE_TIMEOUT",
                    type nullable number,
                    "Specifies the timeout (in seconds) for receiving an authentication response from an external browser.",
                    120,
                    each _ = null or (_ > 0 and Number.RoundDown(_) = _)
                },
                {
                    "CLIENT_OUT_OF_BAND_TELEMETRY_ENABLED",
                    type nullable logical,
                    "Enable out-of-band telemetry for enhanced analytics.",
                    true,
                    each _ = null or _ <> null
                },
                {
                    "CLIENT_SESSION_KEEP_ALIVE",
                    type nullable logical,
                    "Keep session active after inactivity, avoiding re-login (true) or require re-login (false) after four hours.",
                    false,
                    each _ = null or _ <> null
                },
                {
                    "disableSamlUrlCheck",
                    type nullable logical,
                    "Disable verification of SAML URLs, ensuring connection flexibility during login.",
                    false,
                    each _ = null or _ <> null
                },
                {
                    "maxHttpRetries",
                    type nullable number,
                    "Maximum number of HTTP retries before returning an error; 0 removes limit (retry may be indefinite).",
                    7,
                    each _ = null or (_ >= 0 and Number.RoundDown(_) = _)
                },
                {
                    "schema",
                    type nullable text,
                    "Default schema for sessions; if unspecified, 'public' schema is used.",
                    "public",
                    each _ = null or _ <> null
                },
                {
                    "SecondaryRoles",
                    type nullable text,
                    "Secondary roles for the session; values are 'All' (all user roles) or 'None' (no secondary roles).",
                    null,
                    each _ = null or List.Contains({"All", "None"}, _)
                },
                {
                    "tracing",
                    type nullable number,
                    "Trace logging level: 0=Disable, 1=Fatal, 2=Error, 3=Warning, 4=Info, 5=Debug, 6=Detailed.",
                    4,
                    each _ = null or List.Contains({0, 1, 2, 3, 4, 5, 6}, _)
                },
                // Additional connection parameters, see: https://docs.snowflake.com/en/developer-guide/odbc/odbc-parameters#additional-connection-parameters
                {
                    "allowEmptyProxy",
                    type nullable logical,
                    "Allow empty values for proxy and no_proxy settings, overriding existing configurations if set to true.",
                    true,
                    each _ = null or _ <> null
                },
                {
                    "authenticator",
                    type nullable text,
                    "Authenticator for verifying user credentials, options: snowflake, externalbrowser, Okta URL, oauth, username_password_mfa.",
                    "username_password_mfa",
                    each _ = null or List.Contains({"snowflake", "externalbrowser", "oauth", "username_password_mfa"}, _)
                },
                {
                    "default_binary_size",
                    type nullable number,
                    "Default size in bytes for retrieving BINARY column values of undetermined size.",
                    8388608,
                    each _ = null or (_ > 0 and Number.RoundDown(_) = _)
                },
                {
                    "default_varchar_size",
                    type nullable number,
                    "Default size in bytes for retrieving VARCHAR column values of undetermined size.",
                    16777216,
                    each _ = null or (_ > 0 and Number.RoundDown(_) = _)
                },
                {
                    "network_timeout",
                    type nullable number,
                    "Time in seconds to wait for a response during interactions before returning a network error.",
                    0,
                    each _ = null or (_ >= 0 and Number.RoundDown(_) = _)
                },
                {
                    "retryTimeout",
                    type nullable number,
                    "Time in seconds to wait before returning an error after failed HTTP request retries.",
                    300,
                    each _ = null or (_ >= 0 and Number.RoundDown(_) = _)
                },
                {
                    "no_proxy",
                    type nullable text,
                    "Comma-separated list of hostnames or IPs to bypass the proxy server (e.g., .amazonaws.com).",
                    null,
                    each _ = null or _ <> null
                },
                {
                    "odbc_use_standard_timestamp_columnsize",
                    type nullable logical,
                    "Boolean parameter to control the column size for SQL_TYPE_TIMESTAMP (29=ODBC standard, 35 for timezone offset).",
                    false,
                    each _ = null or _ <> null
                },
                {
                    "passcode",
                    type nullable text,
                    "Passcode for multi-factor authentication.",
                    null,
                    each _ = null or _ <> null
                },
                {
                    "passcodeInPassword",
                    type nullable logical,
                    "Boolean parameter to specify if MFA passcode is appended to the password.",
                    false,
                    each _ = null or _ <> null
                },
                {
                    "put_compresslv",
                    type nullable number,
                    "Compression level for PUT commands (-1 for default, 0-9 for custom level).",
                    -1,
                    each _ = null or (_ >= -1 and _ <= 9)
                },
                {
                    "put_fastfail",
                    type nullable logical,
                    "Boolean to stop PUT command when an error occurs with one file (true) or continue with others (false).",
                    false,
                    each _ = null or _ <> null
                },
                {
                    "put_maxretries",
                    type nullable number,
                    "Number of times to retry the PUT command if it fails (range: 0-100).",
                    5,
                    each _ = null or (_ >= 0 and _ <= 100)
                },
                {
                    "put_tempdir",
                    type nullable text,
                    "Temporary directory to use for PUT command requests.",
                    "/tmp/snowflakeTmp_username",
                    each _ = null or _ <> null
                },
                {
                    "token",
                    type nullable text,
                    "OAuth token for authentication, required when authenticator=oauth.",
                    null,
                    each _ = null or _ <> null
                },
                {
                    "validateSessionParam",
                    type nullable logical,
                    "Validate session parameters (database, schema, warehouse); rejects connection if set to true and parameters are invalid.",
                    false,
                    each _ = null or _ <> null
                }
            }
        ),
        
        ValidatedOptions = ValidateOptions(
            if config <> null and Record.HasFields(config, "options") then config[options] else [],
            ValidOptionsMap
        ),
        //
        // Connection string settings
        //
        ConnectionString = [
            // At minimum you need to specify the ODBC Driver to use.
            Driver = Config_DriverName,

            // Replicating the options set by the official connector
            application = "Mashup Engine",
            UseCurrentCatalog = 1,

            // Specify custom properties for your ODBC Driver here.
            // The fields below are appropriate for the SQL Server ODBC Driver. The
            // names might be different for your data source.
            Server = server,
            Warehouse = warehouse,
            Role = if config <> null and Record.HasFields(config, "roleName") then config[roleName] else null,
            Database = if config <> null and Record.HasFields(config, "database") then config[database] else null,

            login_timeout = if config <> null and Record.HasFields(config, "connectionTimeout") then config[connectionTimeout] else null,
            query_timeout = if config <> null and Record.HasFields(config, "commandTimeout") then config[commandTimeout] else null,


            // These fields come from the options record, so they might be null.
            // A later step will strip all null values from the connection string.
            #"CABundleFile" = ValidatedOptions[CABundleFile]?,
            #"client_config_file" = ValidatedOptions[client_config_file]?,
            #"get_size_threshold" = ValidatedOptions[get_size_threshold]?,
            #"LogFileCount" = ValidatedOptions[LogFileCount]?,
            #"LogFileSize" = ValidatedOptions[LogFileSize]?,
            #"LogLevel" = ValidatedOptions[LogLevel]?,
            #"LogPath" = ValidatedOptions[LogPath]?,
            #"MapToLongVarchar" = ValidatedOptions[MapToLongVarchar]?,
            #"NoProxy" = ValidatedOptions[NoProxy]?,
            #"Proxy" = ValidatedOptions[Proxy]?,
            #"BROWSER_RESPONSE_TIMEOUT" = ValidatedOptions[BROWSER_RESPONSE_TIMEOUT]?,
            #"maxHttpRetries" = ValidatedOptions[maxHttpRetries]?,
            #"schema" = ValidatedOptions[schema]?,
            #"SecondaryRoles" = ValidatedOptions[SecondaryRoles]?,
            #"tracing" = ValidatedOptions[tracing]?,
            #"authenticator" = ValidatedOptions[authenticator]?,
            #"default_binary_size" = ValidatedOptions[default_binary_size]?,
            #"default_varchar_size" = ValidatedOptions[default_varchar_size]?,
            #"network_timeout" = ValidatedOptions[network_timeout]?,
            #"retryTimeout" = ValidatedOptions[retryTimeout]?,
            #"no_proxy" = ValidatedOptions[no_proxy]?,
            #"passcode" = ValidatedOptions[passcode]?,
            #"put_compresslv" = ValidatedOptions[put_compresslv]?,
            #"put_maxretries" = ValidatedOptions[put_maxretries]?,
            #"put_tempdir" = ValidatedOptions[put_tempdir]?,
            #"token" = ValidatedOptions[token]?,

            // Fix for poorly documented driver documentation on types
            #"CURLVerboseMode" = if ValidatedOptions[CURLVerboseMode]? = true then 1 else if ValidatedOptions[CURLVerboseMode]? = false then 0 else null,
            #"DisableOCSPCheck" = if ValidatedOptions[DisableOCSPCheck]? = true then 1 else if ValidatedOptions[DisableOCSPCheck]? = false then 0 else null,
            #"EnableAutoIpdByDefault" = if ValidatedOptions[EnableAutoIpdByDefault]? = true then 1 else if ValidatedOptions[EnableAutoIpdByDefault]? = false then 0 else null,
            #"EnablePidLogFileNames" = if ValidatedOptions[EnablePidLogFileNames]? = true then 1 else if ValidatedOptions[EnablePidLogFileNames]? = false then 0 else null,
            #"KeepLeadingTrailingZeros" = if ValidatedOptions[KeepLeadingTrailingZeros]? = true then 1 else if ValidatedOptions[KeepLeadingTrailingZeros]? = false then 0 else null,
            #"NoExecuteInSQLPrepare" = if ValidatedOptions[NoExecuteInSQLPrepare]? = true then 1 else if ValidatedOptions[NoExecuteInSQLPrepare]? = false then 0 else null,
            #"CLIENT_OUT_OF_BAND_TELEMETRY_ENABLED" = if ValidatedOptions[CLIENT_OUT_OF_BAND_TELEMETRY_ENABLED]? = true then 1 else if ValidatedOptions[CLIENT_OUT_OF_BAND_TELEMETRY_ENABLED]? = false then 0 else null,
            #"CLIENT_SESSION_KEEP_ALIVE" = if ValidatedOptions[CLIENT_SESSION_KEEP_ALIVE]? = true then 1 else if ValidatedOptions[CLIENT_SESSION_KEEP_ALIVE]? = false then 0 else null,
            #"disableSamlUrlCheck" = if ValidatedOptions[disableSamlUrlCheck]? = true then 1 else if ValidatedOptions[disableSamlUrlCheck]? = false then 0 else null,
            #"allowEmptyProxy" = if ValidatedOptions[allowEmptyProxy]? = true then 1 else if ValidatedOptions[allowEmptyProxy]? = false then 0 else null,
            #"odbc_use_standard_timestamp_columnsize" = if ValidatedOptions[odbc_use_standard_timestamp_columnsize]? = true then 1 else if ValidatedOptions[odbc_use_standard_timestamp_columnsize]? = false then 0 else null,
            #"passcodeInPassword" = if ValidatedOptions[passcodeInPassword]? = true then 1 else if ValidatedOptions[passcodeInPassword]? = false then 0 else null,
            #"put_fastfail" = if ValidatedOptions[put_fastfail]? = true then 1 else if ValidatedOptions[put_fastfail]? = false then 0 else null,
            #"validateSessionParam" = if ValidatedOptions[validateSessionParam]? = true then 1 else if ValidatedOptions[validateSessionParam]? = false then 0 else null
        ],
        //
        // Handle credentials
        // Credentials are not persisted with the query and are set through a separate
        // record field - CredentialConnectionString. The base Odbc.DataSource function
        // will handle UsernamePassword authentication automatically, but it is explictly
        // handled here as an example.
        //
        Credential = Extension.CurrentCredential(),
        CredentialConnectionString =
                [UID = Credential[Username], PWD = Credential[Password]],
          
        //
        // Configuration options for the call to Odbc.DataSource
        //
        defaultConfig = Diagnostics.LogValue("BuildOdbcConfig", BuildOdbcConfig()),
        SqlCapabilities = Diagnostics.LogValue(
            "SqlCapabilities_Options", 
            defaultConfig[SqlCapabilities] & [
                // Place custom overrides here
                FractionalSecondsScale = 3,
                MaxParameters = 50,
                Sql92Translation = "Passthrough" // Always enable passthrough
            ]
        ),
        // Please refer to the ODBC specification for SQLGetInfo properties and values.
        // https://github.com/Microsoft/ODBC-Specification/blob/master/Windows/inc/sqlext.h
        SQLGetInfo = Diagnostics.LogValue(
            "SQLGetInfo_Options",
            defaultConfig[SQLGetInfo]
                & [
                    // Place custom overrides here
                    // The values below are required for the SQL Native Client ODBC driver, but might
                    // not be required for your data source.
                    SQL_SQL92_PREDICATES = ODBC[SQL_SP][All],
                    SQL_AGGREGATE_FUNCTIONS = ODBC[SQL_AF][All],
                    SQL_CONVERT_FUNCTIONS = 0x00000002 // Tell PowerBI that Snowflake uses cast and not convert
                ]
        ),
        // SQLGetTypeInfo can be specified in two ways:
        // 1. A #table() value that returns the same type information as an ODBC
        //    call to SQLGetTypeInfo.
        // 2. A function that accepts a table argument, and returns a table. The
        //    argument will contain the original results of the ODBC call to SQLGetTypeInfo.
        //    Your function implementation can modify/add to this table.
        //
        // For details of the format of the types table parameter and expected return value,
        // please see: https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlgettypeinfo-function
        //
        // The sample implementation provided here will simply output the original table
        // to the user trace log, without any modification.
        SQLGetTypeInfo = (types) =>
            if (EnableTraceOutput <> true) then
                types
            else
                let
                    // Outputting the entire table might be too large, and result in the value being truncated.
                    // We can output a row at a time instead with Table.TransformRows()
                    rows = Table.TransformRows(types, each Diagnostics.LogValue("SQLGetTypeInfo " & _[TYPE_NAME], _)),
                    toTable = Table.FromRecords(rows)
                in
                    Value.ReplaceType(toTable, Value.Type(types)),
        // SQLColumns is a function handler that receives the results of an ODBC call
        // to SQLColumns(). The source parameter contains a table with the data type
        // information. This override is typically used to fix up data type mismatches
        // between calls to SQLGetTypeInfo and SQLColumns.
        //
        // For details of the format of the source table parameter, please see:
        // https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlcolumns-function
        //
        // The sample implementation provided here will simply output the original table
        // to the user trace log, without any modification.
        SQLColumns = (catalogName, schemaName, tableName, columnName, source) =>
            let
                OdbcSqlType.DATETIME = 9,
                OdbcSqlType.TYPE_DATE = 91,
                OdbcSqlType.TIME = 10,
                OdbcSqlType.TYPE_TIME = 92,
                OdbcSqlType.TIMESTAMP = 11,
                OdbcSqlType.TYPE_TIMESTAMP = 93,
                FixDataType = (dataType) =>
                    if dataType = OdbcSqlType.DATETIME then
                        OdbcSqlType.TYPE_DATE
                    else if dataType = OdbcSqlType.TIME then
                        OdbcSqlType.TYPE_TIME
                    else if dataType = OdbcSqlType.TIMESTAMP then
                        OdbcSqlType.TYPE_TIMESTAMP
                    else
                        dataType,
                Transform = Table.TransformColumns(source, {{"DATA_TYPE", FixDataType}})
            in
                if (EnableTraceOutput <> true) then
                    Transform
                else if (
                    // the if statement conditions will force the values to evaluated/written to diagnostics
                    Diagnostics.LogValue("SQLColumns.TableName", tableName) <> "***"
                    and Diagnostics.LogValue("SQLColumns.ColumnName", columnName) <> "***"
                ) then
                    let
                        // Outputting the entire table might be too large, and result in the value being truncated.
                        // We can output a row at a time instead with Table.TransformRows()
                        rows = Table.TransformRows(Transform, each Diagnostics.LogValue("SQLColumns", _)),
                        toTable = Table.FromRecords(rows)
                    in
                        Value.ReplaceType(toTable, Value.Type(Transform))
                else
                    Transform,
        // Remove null fields from the ConnectionString
        ConnectionStringNoNulls = Record.SelectFields(
            ConnectionString, Table.SelectRows(Record.ToTable(ConnectionString), each [Value] <> null)[Name]
        ),
        OdbcDatasource = try Odbc.DataSource(
            ConnectionStringNoNulls,
            [
                AstVisitor = [
                    Constant = let
                        Quote = each Text.Format("'#{0}'", {_}),
                        Cast = (value, typeName) => [
                            Text = Text.Format("CAST(#{0} as #{1})", {value, typeName})
                        ],
                        Visitor = [
                            // This is to work around parameters being converted to VARCHAR
                            // and to work around driver crash when using TYPE_TIME parameters.
                            NUMERIC = each Cast(_, "NUMERIC"),
                            DECIMAL = each Cast(_, "DECIMAL"),
                            INTEGER = each Cast(_, "INTEGER"),
                            FLOAT = each Cast(_, "FLOAT"),
                            REAL = each Cast(_, "REAL"),
                            DOUBLE = each Cast(_, "DOUBLE"),
                            DATE = each Cast(Quote(Date.ToText(_, "yyyy-MM-dd")), "DATE"),
                            TIMESTAMP = each Cast(Quote(DateTime.ToText(_, "yyyy-MM-dd HH:mm:ss.sssssss")), "TIMESTAMP"),
                            TIME = each Cast(Quote(Time.ToText(_, "HH:mm:ss.sssssss")), "TIME")
                        ]
                    in
                        (typeInfo, ast) => Record.FieldOrDefault(Visitor, typeInfo[TYPE_NAME], each null)(ast[Value])
                ],
                // A logical (true/false) that sets whether to view the tables grouped by their schema names
                HierarchicalNavigation = true,
                // A logical value that controls whether or not the connector shows generated SQL statements in the Power Query user experience.
                HideNativeQuery = true,
                // Allows upconversion of numeric types
                SoftNumbers = true,
                // Allow upconversion / resizing of numeric and string types
                TolerateConcatOverflow = true,
                // Enables connection pooling via the system ODBC manager
                ClientConnectionPooling = true,
                // These values should be set by previous steps
                CredentialConnectionString = CredentialConnectionString,
                SqlCapabilities = SqlCapabilities,
                SQLColumns = SQLColumns,
                SQLGetInfo = SQLGetInfo,
                SQLGetTypeInfo = SQLGetTypeInfo,
                UseEmbeddedDriver = true
            ]
        ) 
        catch (e)=>
        let
            errorMessage = e[Message],
            // check if the error is related to missing driver, if so add a link for installation, else raise the error as is
            customErrorMessageToAdd = if Text.Contains(errorMessage, "doesn't correspond to an installed ODBC driver") then " Please visit the installation guide: https://docs.snowflake.com/en/developer-guide/odbc/odbc-windows." else ""
        in 
            error Text.Combine({errorMessage, customErrorMessageToAdd}),
        
        // without this filter, the user will get all databases 
        OdbcDatasourceForSelectedDatabase = Table.SelectRows(
            OdbcDatasource, 
            each (config <> null and Record.HasFields(config, "database") and config[database] <> null) 
                and [Name] = config[database] 
                or config = null or not Record.HasFields(config, "database") or config[database] = null
        )

    in
        OdbcDatasourceForSelectedDatabase;

// Data Source Kind description
Snowflake = [
    // Set the TestConnection handler to enable gateway support.
    // The TestConnection handler will invoke your data source function to
    // validate the credentials the user has provider. Ideally, this is not
    // an expensive operation to perform. By default, the dataSourcePath value
    // will be a json string containing the required parameters of your data
    // source function. These should be parsed and parsed as individual parameters
    // to the specified data source function.
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath),
            server = json[server],
            warehouse = json[warehouse]
        in
            {"Snowflake.Database", server, warehouse},
    // Set supported types of authentication
    Authentication = [
        //Windows = [],
        UsernamePassword = []
    ],
    SupportsEncryption = true,
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
Snowflake.Publish = [
    Beta = true,
    Category = "Database",
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    LearnMoreUrl = "https://learn.microsoft.com/en-us/power-query/connectors/snowflake",
    SupportsDirectQuery = Config_EnableDirectQuery,
    SourceImage = Snowflake.Icons,
    SourceTypeImage = Snowflake.Icons,
    NativeQueryProperties = [
        navigationSteps = {
            [
                indices = {
                    [
                        value = "database",
                        indexName = "Name"
                    ],
                    [
                        displayName = "Database",
                        indexName = "Kind"
                    ]
                },
                access = "Data"
            ]
        },
        nativeQueryOptions = [
            EnableFolding = true
        ]
    ]
];

Snowflake.Icons = [
    Icon16 = {
        Extension.Contents("SnowflakeConnector16.png"),
        Extension.Contents("SnowflakeConnector20.png"),
        Extension.Contents("SnowflakeConnector24.png"),
        Extension.Contents("SnowflakeConnector32.png")
    },
    Icon32 = {
        Extension.Contents("SnowflakeConnector32.png"),
        Extension.Contents("SnowflakeConnector40.png"),
        Extension.Contents("SnowflakeConnector48.png"),
        Extension.Contents("SnowflakeConnector64.png")
    }
];



// build settings based on configuration variables
BuildOdbcConfig = () as record =>
    let
        Merge = (previous as record, optional caps as record, optional funcs as record, optional getInfo as record) as record =>
            let
                newCaps = if (caps <> null) then previous[SqlCapabilities] & caps else previous[SqlCapabilities],
                newFuncs = if (funcs <> null) then previous[SQLGetFunctions] & funcs else previous[SQLGetFunctions],
                newGetInfo = if (getInfo <> null) then previous[SQLGetInfo] & getInfo else previous[SQLGetInfo]
            in
                [SqlCapabilities = newCaps, SQLGetFunctions = newFuncs, SQLGetInfo = newGetInfo],
        defaultConfig = [
            SqlCapabilities = [],
            SQLGetFunctions = [],
            SQLGetInfo = []
        ],
        withParams =
            if (Config_UseParameterBindings = false) then
                let
                    caps = [
                        SupportsNumericLiterals = true,
                        SupportsStringLiterals = true,
                        SupportsOdbcDateLiterals = true,
                        SupportsOdbcTimeLiterals = true,
                        SupportsOdbcTimestampLiterals = true
                    ],
                    funcs = [
                        SQL_API_SQLBINDPARAMETER = false
                    ]
                in
                    Merge(defaultConfig, caps, funcs)
            else
                defaultConfig,
        withEscape =
            if (Config_StringLiterateEscapeCharacters <> null) then
                let
                    caps = [
                        StringLiteralEscapeCharacters = Config_StringLiterateEscapeCharacters
                    ]
                in
                    Merge(withParams, caps)
            else
                withParams,
        withLimitClauseKind = let caps = [
            LimitClauseKind = Config_LimitClauseKind
        ] in Merge(withEscape, caps),
        withCastOrConvert =
            if (Config_UseCastInsteadOfConvert <> null) then
                let
                    value =
                        if (Config_UseCastInsteadOfConvert = true) then
                            ODBC[SQL_FN_CVT][SQL_FN_CVT_CAST]
                        else
                            ODBC[SQL_FN_CVT][SQL_FN_CVT_CONVERT],
                    getInfo = [
                        SQL_CONVERT_FUNCTIONS = value
                    ]
                in
                    Merge(withLimitClauseKind, null, null, getInfo)
            else
                withLimitClauseKind,
        withSqlConformance =
            if (Config_SqlConformance <> null) then
                let
                    getInfo = [
                        SQL_SQL_CONFORMANCE = Config_SqlConformance
                    ]
                in
                    Merge(withCastOrConvert, null, null, getInfo)
            else
                withCastOrConvert
    in
        withSqlConformance;

ValidateOptions = (options as nullable record, validOptionsMap as table) as record =>
    let
        ValidKeys = Table.Column(validOptionsMap, "Name"),
        InvalidKeys = List.Difference(Record.FieldNames(options), ValidKeys),
        InvalidKeysText =
            if List.IsEmpty(InvalidKeys) then
                null
            else
                Text.Format(
                    "'#{0}' are not valid options. Valid options are: '#{1}'",
                    {Text.Combine(InvalidKeys, ", "), Text.Combine(ValidKeys, ", ")}
                ),
        ValidateValue = (name, optionType, description, default, validate, value) =>
            if
                (value is null and (Type.IsNullable(optionType) or default <> null))
                or (Type.Is(Value.Type(value), optionType) and validate(value))
            then
                null
            else
                Text.Format(
                    "This function does not support the option '#{0}' with value '#{1}'. Valid value is #{2}.",
                    {name, value, description}
                ),
        InvalidValues = List.RemoveNulls(
            Table.TransformRows(
                validOptionsMap,
                each
                    ValidateValue(
                        [Name],
                        [Type],
                        [Description],
                        [Default],
                        [Validate],
                        Record.FieldOrDefault(options, [Name], [Default])
                    )
            )
        ),
        DefaultOptions = Record.FromTable(
            Table.RenameColumns(Table.SelectColumns(validOptionsMap, {"Name", "Default"}), {"Default", "Value"})
        ),
        NullNotAllowedFields = List.RemoveNulls(
            Table.TransformRows(
                validOptionsMap,
                each
                    if not Type.IsNullable([Type]) and null = Record.FieldOrDefault(options, [Name], [Default]) then
                        [Name]
                    else
                        null
            )
        ),
        NormalizedOptions = DefaultOptions & Record.RemoveFields(options, NullNotAllowedFields, MissingField.Ignore)
    in
        if null = options then
            DefaultOptions
        else if not List.IsEmpty(InvalidKeys) then
            error Error.Record("Expression.Error", InvalidKeysText)
        else if not List.IsEmpty(InvalidValues) then
            error Error.Record("Expression.Error", Text.Combine(InvalidValues, ", "))
        else
            NormalizedOptions;

//
// Load common library functions
//
Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

// Diagnostics module contains multiple functions. We can take the ones we need.
Diagnostics = Extension.LoadFunction("Diagnostics.pqm");

Diagnostics.LogValue = if (EnableTraceOutput) then Diagnostics[LogValue] else (prefix, value) => value;

// OdbcConstants contains numeric constants from the ODBC header files, and a
// helper function to create bitfield values.
ODBC = Extension.LoadFunction("OdbcConstants.pqm");
