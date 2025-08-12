# Application Integration Examples

## .NET Application Integration

### appsettings.json
```json
{
  "Vault": {
    "Address": "http://vault.internal:8200",
    "Token": "your-app-token",
    "SecretPath": "secret/data/myapp"
  }
}
```

### C# Code Example
```csharp
using VaultSharp;
using VaultSharp.V1.AuthMethods.Token;
using VaultSharp.V1.Commons;

public class VaultService
{
    private readonly IVaultClient _vault;

    public VaultService(string address, string token)
    {
        var authMethod = new TokenAuthMethodInfo(token);
        var vaultClientSettings = new VaultClientSettings(address, authMethod);
        _vault = new VaultClient(vaultClientSettings);
    }

    public async Task<string> GetSecretAsync(string path, string key)
    {
        var secret = await _vault.V1.Secrets.KeyValue.V2.ReadSecretAsync(path);
        return secret.Data.Data[key].ToString();
    }
}
```

## Node.js Application Integration

### package.json
```json
{
  "dependencies": {
    "node-vault": "^0.10.2"
  }
}
```

### JavaScript Code Example
```javascript
const vault = require('node-vault')({
  apiVersion: 'v1',
  endpoint: 'http://vault.internal:8200',
  token: process.env.VAULT_TOKEN
});

async function getSecret(path, key) {
  try {
    const result = await vault.read(`secret/data/${path}`);
    return result.data.data[key];
  } catch (error) {
    console.error('Failed to read secret:', error);
    throw error;
  }
}

module.exports = { getSecret };
```

## Python Application Integration

### requirements.txt
```
hvac==1.2.1
```

### Python Code Example
```python
import hvac
import os

class VaultClient:
    def __init__(self):
        self.client = hvac.Client(
            url=os.getenv('VAULT_ADDR', 'http://localhost:8200'),
            token=os.getenv('VAULT_TOKEN')
        )

    def get_secret(self, path, key):
        try:
            response = self.client.secrets.kv.v2.read_secret_version(path=path)
            return response['data']['data'][key]
        except Exception as e:
            print(f"Failed to read secret: {e}")
            raise

# Usage
vault = VaultClient()
db_password = vault.get_secret('myapp/database', 'password')
```

## Docker Application Integration

### docker-compose.yml for apps
```yaml
services:
  myapp:
    image: myapp:latest
    environment:
      VAULT_ADDR: "http://vault:8200"
      VAULT_TOKEN_FILE: "/var/secrets/vault-token"
    volumes:
      - vault-secrets:/var/secrets
    depends_on:
      - vault-agent

  vault-agent:
    image: vault:latest
    command: ["vault", "agent", "-config=/vault/config/agent.hcl"]
    volumes:
      - ./vault-agent.hcl:/vault/config/agent.hcl
      - vault-secrets:/var/secrets

volumes:
  vault-secrets:
```
