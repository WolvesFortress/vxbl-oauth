# vweb XboxLive oauth2

You can integrate this into your vweb project

To run it, do `v run main.v`

Upon first start, the code will panic and a `login.conf` file will be generated. You must fill it with your ClientID, ClientSecret and RedirectURI, which you can find on Azure.

# Azure
## ClientID
Register an azure application at https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps

Your ClientID is the `Application (client) ID`
## ClientSecret
In your application, head over to `Certificates & Secrets` tab and click `+ New client secret`.

Your ClientSecret is the `Value` field of the secret you added
## RedirectURI
In your application, head over to `Authentication` tab and click `+ Add a platform`.

Select `Web` and you will be asked to input `Redirect URIs`.

Your `RedirectURI` will send the client to `/signin`. Since both `index()` and `signin()` are defined as websites in this project and therefore both handled by `main.v`, you should configure it to `<url_to_index>/signin`

# Additional information
- You can modify `main.v` to suit your needs. Some people might want a button or link to "log in using Xbox Live" instead.
  Currently there is `app.redirect(request_url)` in `index()`. request_uri is the "log in using Xbox Live" webpage by Microsoft

- You can move the `signin()` web handler to another file. You might need to modify your `RedirectURI` in BOTH Azure and `login.conf`

- In `signin()` you can access all kinds of variables, which can be used in the template or to extend functionality, i.e. saving the xuid in a session cookie or do database requests and redirects

- I tested the app on debian 9, ubuntu 20.4 (port 80 and 443) and windows 10 (as localhost, port 80)