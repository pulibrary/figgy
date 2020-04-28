# Browse Everything

## Getting it to work in development

Before your bin/wepack-dev-server ensure you have
REACT_APP_GOOGLE_DEVELOPER_KEY, REACT_APP_GOOGLE_CLIENT_ID,
REACT_APP_GOOGLE_SCOPE, and REACT_APP_SECRET set. You can get copies of these
from princeton_ansible for the staging variables, the secret is pulled from
`config/secrets.yml`

## Using Google Drive as a storage provider
### Registering your Figgy
- [Register for a Google Cloud Platform account](https://console.cloud.google.com)
- Access the [Google Cloud Platform console](console.cloud.google.com/apis)
- Next to "Google Cloud Platform" branding in the top left, select from the dropdown menu
- Click on the "+" button to the far right of the "Search projects and folders" form field
- Create a new project with a new name

### Enabling the Google Drive API for your Figgy
- From the "Dashboard" interface, click "Enable APIs and Services"
- Within "Search for APIs & Services" enter for "Google Drive", and select the "Google Drive API"
- Click the "Enable" button
- From the "Google Drive API" management interface, select "Create credentials"
- "Which API are you using?" should contain the value "Google Drive API"
- "Where will you be calling the API from?" should contain the value "Web server (e. g. node.js, Tomcat)"
- "What data will you be accessing?" should contain "User data"
- Select "What credentials do I need?"

#### Creating an OAuth 2 client ID
- Provide the "name" for your Figgy
- Select "Create client ID"
- Provide the e-mail address for the repository administrator
- Provide the product name for users granting your Figgy access to Google Drive accounts
- Provide the authorized redirect URIs
  - `http://localhost:3000/browse/connect` will be sufficient for testing using an instance on the localhost
  - Otherwise, please offer some URI of the structure `http://[YOUR_FIGGY_URL]/browse/connect`
- _You do not **need** to download the credentials_

#### Retrieving the OAuth client secret
- From the "Credentials" interface, select the "Edit OAuth client" button (it features a pencil icon to the right of the name of your Figgy)
- Copy the "Client ID" and "Client secret" into the `config/browse_everything_providers.yml` configuration file
  - _Should your client secret every be compromised, please note that one can "Reset Secret" at the top of this interface_

### Uploading Files
- After restarting your instance of Figgy, one should be able to upload files from Google Drive within the File Manager for resources in the repository
