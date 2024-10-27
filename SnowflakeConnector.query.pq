let
    // Retrieve server and warehouse values from JSON
    server = "contoso.snowflakecomputing.com",
    warehouse = "CONTOSO_WH",

    // Define additional options
    options = [
        LogLevel = 6,
        LogPath = "C:\\temp"
    ],
    config = [
        roleName = null,                            // Optional role name
        commandTimeout = null,                      // Optional command timeout
        connectionTimeout = null,                   // Optional connection timeout
        includeRelationshipColumns = null,          // Optional include relationship columns
        database = null,                            // Optional database
        sqlStatement = null,                        // Optional SQL statement
        options = options                           // Additional options
    ],

    // Call Snowflake.Database with sourced parameters
    result = Snowflake.Database(
        server,
        warehouse,
        config
    )
in
    result
