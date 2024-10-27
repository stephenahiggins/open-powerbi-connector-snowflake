let
    // Load JSON configuration from file - be sure to edit this
    jsonFilePath = "C:\\path\\to\\config.json",
    jsonContent = Text.FromBinary(File.Contents(jsonFilePath)),
    jsonConfig = Json.Document(jsonContent),

    // Retrieve server and warehouse values from JSON
    server = jsonConfig[server],
    warehouse = jsonConfig[warehouse],

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
