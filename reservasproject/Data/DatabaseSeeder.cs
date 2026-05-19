using Microsoft.Data.SqlClient;
using System.Text.RegularExpressions;

namespace reservasproject.Data
{
    public static class DatabaseSeeder
    {
        public static void Initialize(IServiceProvider serviceProvider, string connectionString)
        {
            var masterConnectionString = new SqlConnectionStringBuilder(connectionString)
            {
                InitialCatalog = "master"
            }.ConnectionString;

            using (var connection = new SqlConnection(masterConnectionString))
            {
                connection.Open();

                // Verificar si la base de datos ya existe
                var checkCmd = new SqlCommand("SELECT 1 FROM sys.databases WHERE name = 'SedesRecreativasDB'", connection);
                var exists = checkCmd.ExecuteScalar();

                if (exists != null && exists != DBNull.Value)
                {
                    // La base de datos ya existe, no ejecutamos el script para no dar error de tablas repetidas
                    return;
                }

                // Leer y ejecutar el script SQL
                var scriptPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "schema.sql");
                if (File.Exists(scriptPath))
                {
                    var script = File.ReadAllText(scriptPath);
                    
                    // Separar por GO
                    var batches = Regex.Split(script, @"^\s*GO\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase);

                    foreach (var batch in batches)
                    {
                        var trimmedBatch = batch.Trim();
                        if (string.IsNullOrWhiteSpace(trimmedBatch)) continue;

                        using (var command = new SqlCommand(trimmedBatch, connection))
                        {
                            command.ExecuteNonQuery();
                        }
                    }
                }
            }
        }
    }
}
